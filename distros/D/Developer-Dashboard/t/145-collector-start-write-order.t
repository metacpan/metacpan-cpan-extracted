#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;

# Hermetic runtime rooted in a throwaway HOME. The collector runner resolves its
# state roots from the deepest .developer-dashboard layer above the working
# directory, so the test chdirs into the temp home before constructing anything.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
# Every collector loop this file starts is detached, and only the matching
# stop further down ends it. A run that is killed part-way never reaches
# that stop, and the loops then live on for days. Tie them to this test
# process: each loop ends itself once this pid is gone.
local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $$;
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => Developer::Dashboard::Collector->new( paths => $paths ),
    files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    paths      => $paths,
);

my $name = 'order-probe';

# The window this file exists to close cannot be observed by racing two
# processes - it is microseconds wide and would make a flaky test. It can be
# observed exactly, though, by asking what is on disk AT THE MOMENT the loop
# state is written. running_loops keys on the pidfile and identifies the pid from
# the recorded state, so the invariant is simply: the pidfile must never exist
# while the state does not.
my $pidfile_existed_when_state_was_written;
my $state_written = 0;

{
    no warnings 'redefine';

    # NOTE: start_loop spawns a REAL supervisor through the GoRoutine
    # spawn layer (there is no _fork_process in lib/ any more - the mock
    # that used to stand here was dead code, and the comment that claimed
    # "nothing is actually forked" was false). The loop it starts is
    # stopped at the end of this file: left running, its supervisor holds
    # the tempdir and prove's stdout pipe open, so prove never sees EOF
    # after 1..6 and the run stalls (round 67).
    my $real_write_state = \&Developer::Dashboard::CollectorRunner::_write_loop_state;
    local *Developer::Dashboard::CollectorRunner::_write_loop_state = sub {
        my ( $self, $loop_name, @rest ) = @_;
        $state_written++;
        $pidfile_existed_when_state_was_written = -f $self->_pidfile($loop_name) ? 1 : 0;
        return $self->$real_write_state( $loop_name, @rest );
    };

    # start_loop takes the job hashref itself, not named arguments.
    $runner->start_loop(
        {
            name     => $name,
            command  => 'true',
            cwd      => $home,
            interval => 60,
            schedule => 'interval',
        }
    );
}

is( $state_written, 1, 'start_loop records the loop state exactly once' );

is( $pidfile_existed_when_state_was_written, 0,
    'the loop state is written BEFORE the pidfile, so the pidfile never exists without it' );

# The pidfile must still be written - closing the window must not cost the
# pidfile itself, which everything else keys on.
ok( -f $runner->_pidfile($name), 'start_loop still writes the pidfile' );
ok( defined scalar $runner->loop_state($name), 'start_loop still records loop state' );

# And the ordering must hold on disk, not merely at the moment of writing: a
# reader arriving after start_loop returns sees both.
my $state = $runner->loop_state($name);
is( $state->{name}, $name, 'the recorded state identifies the loop by name' );
ok( $state->{pid}, 'the recorded state carries the pid a sweep would match against' );

# Stop the loop this file started. _cleanup_loop_files alone only
# removes the pidfile and state - it leaves the supervisor process
# running, and a live supervisor holds this tempdir (as its cwd, with
# collectors.log open) and prove's stdout pipe (inherited through the
# GoRoutine spawn) open, so prove never sees EOF after 1..6 and the run
# stalls until the failsafe kills it (round 67). stop_loop terminates
# the supervisor through the native process API, sweeps its workers,
# and cleans the pidfile and state up itself.
$runner->stop_loop($name);

done_testing();

__END__

=head1 NAME

145-collector-start-write-order.t - pin the write order that stops a healthy
collector loop being swept away

=head1 PURPOSE

Prove that C<start_loop> records a loop's state before it writes that loop's
pidfile, so no reader can ever observe a pidfile whose loop it cannot identify.

=head1 WHY IT EXISTS

C<running_loops> lists pidfiles and, for each one, decides whether the pid belongs
to a loop it manages - recognising it either by the child's process title or by the
recorded loop state. C<start_loop> used to write the pidfile first and the state
second. Between those two writes, a child that had not yet adopted its title was
unrecognisable by either route, and a concurrent C<running_loops> in any other
process - the status command, the web status strip, the supervisor - treated a
perfectly healthy loop as an orphan and unlinked its pidfile.

The damage is the exact failure the surrounding code exists to prevent. C<stop_loop>
returns early when the pidfile is missing, so the loop can no longer be stopped by
name; and C<start_loop> consults its loop-state fallback only inside the branch that
requires a pidfile, so the next supervisor start forks a duplicate. The fallback
that exists to prevent that duplicate cannot fire, because the sweep has already
deleted the evidence it reads.

=head1 WHEN TO USE

Run it whenever collector startup, the pidfile handling, or C<running_loops>'
orphan sweep is touched. It is part of the ordinary suite and needs no special
environment.

=head1 HOW TO USE

    prove -lv t/145-collector-start-write-order.t

=head1 WHAT USES IT

The full suite via C<prove -lr t>, the all-metric coverage gate, and the CI
workflow that runs both.

=head1 EXAMPLES

The window is microseconds wide, so racing two processes for it would produce a
flaky test that proves nothing on a fast host. Instead the state writer is wrapped
and asked what is on disk at the instant it runs:

    local *..._write_loop_state = sub {
        $pidfile_existed = -f $self->_pidfile($loop_name) ? 1 : 0;
        ...
    };
    is( $pidfile_existed, 0, '...' );

That is an exact observation of the ordering rather than an attempt to catch it in
the act, and it fails deterministically against the old order.

=cut
