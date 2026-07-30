use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

# A cancel issued from inside a DESTROY that fires *during* cleanup itself is
# a different hazard from an ordinary user cancel. Cleanup drops
# ctx->tasks/final_cb/worker, and any of those can be the last reference
# keeping a blessed object alive. If that object's DESTROY calls $h->cancel
# while the handle had not been detached yet, the handle still looked live
# and cancel would re-enter cleanup on a context that is already half torn
# down: it double-decs ctx->tasks and ctx->final_cb, walks whatever CV field
# the first pass freed without NULLing, then double-frees the handle cell and
# the context itself. Detaching the handle first, before any SvREFCNT_dec that
# can run Perl, makes the reentrant call see h->ctx == NULL and bail out
# immediately.
#
# All four primitives have their own cleanup with its own copy of that
# ordering, so all four are exercised here: covering only parallel let the
# other three regress silently (the detach block moved back to the end of
# series_cleanup, plimit_cleanup or race_cleanup still passed the whole suite).
#
# Both shapes crash the process outright against the buggy ordering (not only
# under valgrind), so a plain run of this file is the detector; valgrind on top
# confirms no leak either.

package EVF::Repro::Guard;

sub new {
    my ($class, $cb) = @_;
    return bless { cb => $cb }, $class;
}

sub DESTROY {
    my $self = shift;
    my $cb = delete $self->{cb};
    $cb->() if $cb;
}

package main;

my @kinds = (
    {
        name  => 'parallel',
        start => sub { parallel($_[0], $_[1]) },
        # A plain object element is a no-op task that completes instantly, so
        # the tasks array is its sole owner and nothing else has to co-operate.
        guard_element => sub { $_[0] },
    },
    {
        name  => 'series',
        start => sub { series($_[0], $_[1]) },
        guard_element => sub { $_[0] },
    },
    {
        name  => 'parallel_limit',
        # limit 2 so both elements are handled in the opening burst and the
        # operation is finished by the async task's completion, as with
        # parallel; the guard is then freed from plimit_cleanup's final path.
        start => sub { parallel_limit($_[0], 2, $_[1]) },
        guard_element => sub { $_[0] },
    },
    {
        name  => 'race',
        start => sub { race($_[0], $_[1]) },
        # race treats a non-coderef element as an instant winner, which would
        # settle it inside the XSUB before the handle reaches Perl - too early
        # for the DESTROY to have a handle to cancel. So race's guard travels
        # inside a task CV that never completes; the tasks array is still the
        # only owner, and race_cleanup still frees it.
        guard_element => sub {
            my $guard = shift;
            return sub { my $keep_alive = $guard; return };
        },
    },
);

for my $kind (@kinds) {
    my $name = $kind->{name};

    subtest "reentrant cancel from a guard freed via the final_cb closure ($name)" => sub {
        our @w;
        my ($final, $reentries, $err) = (0, 0, '');
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $h;

        {
            my $guard = EVF::Repro::Guard->new(sub {
                $reentries++;
                eval { $h->cancel };
                $err = $@ if $@;
            });
            # $guard's only remaining owner once this block ends is the
            # closure's own captured copy. The closure itself is passed
            # straight through as an argument and never bound to a variable
            # that outlives this statement, so ctx->final_cb ends up as its
            # sole reference; freeing it during cleanup is what frees $guard
            # in turn.
            $h = $kind->{start}->(
                [ sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } } ],
                sub { my $keep_alive = $guard; $final++ },
            );
        }

        $h->cancel;

        is($reentries, 1, 'guard DESTROY ran its re-entrant cancel exactly once');
        is($final, 0, 'final_cb was freed, not called (plain cancel does not fire it)');
        ok(!$err, 'the re-entrant cancel call did not die') or diag $err;
        is_deeply(\@warnings, [], 'no "Attempt to free unreferenced scalar" or similar')
            or diag explain \@warnings;
        pass('process survived a DESTROY-triggered cancel from inside cleanup');
        @w = ();
    };

    subtest "reentrant cancel from a guard freed via the tasks array ($name)" => sub {
        our @w;
        my ($final, $reentries, $err) = (0, 0, '');
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $h;

        # The guard reaches the operation only through the anonymous tasks
        # array, whose sole owner is ctx->tasks, so it is freed when ctx->tasks
        # is freed during ordinary completion cleanup - no explicit cancel()
        # call from outside is involved here. The first task is asynchronous so
        # that $h is assigned by the time the DESTROY runs.
        $h = $kind->{start}->(
            [
                sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
                $kind->{guard_element}->(EVF::Repro::Guard->new(sub {
                    $reentries++;
                    eval { $h->cancel(1) };
                    $err = $@ if $@;
                })),
            ],
            sub { $final++; EV::break },
        );

        my $bail = EV::timer 0.2, 0, sub { EV::break };
        EV::run;

        is($reentries, 1, 'guard DESTROY ran its re-entrant cancel exactly once');
        is($final, 1, 'final_cb still ran exactly once after the reentrant cancel');
        ok(!$err, 'the re-entrant cancel call did not die') or diag $err;
        is_deeply(\@warnings, [], 'no "Attempt to free unreferenced scalar" or similar')
            or diag explain \@warnings;
        pass('process survived a DESTROY-triggered cancel during normal completion');
        @w = ();
    };
}

done_testing;
