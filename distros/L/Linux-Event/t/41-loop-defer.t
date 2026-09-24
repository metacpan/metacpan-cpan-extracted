use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::Loop;

sub exception ($code) {
    local $@;
    return eval { $code->(); 1 } ? '' : "$@";
}

subtest 'validation, non-inline delivery, liveness, and handle lifecycle' => sub {
    my $loop = Linux::Event::Loop->new;
    can_ok($loop, 'defer');
    ok(!defined $loop->resources->{defer_fd},
        'defer source is absent before first use');
    is($loop->resources->{pending_deferred}, 0,
        'new Loop has no deferred work');
    like(exception(sub { $loop->defer('not a callback') }),
        qr/callback must be a coderef/, 'non-coderef is rejected');

    my @seen;
    my $pending = $loop->defer(sub { push @seen, 'deferred' });
    is_deeply(\@seen, [], 'defer never invokes inline');
    ok($pending->is_active, 'returned handle starts active');

    my $resources = $loop->resources;
    ok(defined $resources->{defer_fd}, 'defer source is created lazily');
    is($resources->{pending_deferred}, 1, 'resources reports pending defer work');
    ok(grep($_->{type} eq 'deferred' && $_->{pending} == 1,
        @{ $loop->why_alive }), 'pending deferred work is a liveness reason');

    cmp_ok($loop->run_once(100), '>=', 1, 'deferred eventfd is dispatched');
    is_deeply(\@seen, ['deferred'], 'deferred callback ran');
    ok(!$pending->is_active, 'delivered handle becomes inactive');
    is($loop->resources->{pending_deferred}, 0, 'pending count returns to zero');
    ok(!grep($_->{type} eq 'deferred', @{ $loop->why_alive }),
        'completed deferred work is no longer a liveness reason');
};

subtest 'FIFO, cancellation, and dropped-handle ownership' => sub {
    my $loop = Linux::Event::Loop->new;
    my @seen;
    my $first = $loop->defer(sub { push @seen, 'first' });
    my $cancelled = $loop->defer(sub { push @seen, 'cancelled' });
    my $third = $loop->defer(sub { push @seen, 'third' });
    is($cancelled->cancel, $cancelled, 'cancel returns the same handle');
    ok(!$cancelled->is_active, 'cancel is immediately visible');
    is($cancelled->cancel, $cancelled, 'cancel is idempotent');

    $loop->defer(sub { push @seen, 'dropped-handle' });
    $loop->run_once(100);
    is_deeply(\@seen, [qw(first third dropped-handle)],
        'eligible non-cancelled work runs FIFO and dropped handle does not cancel');
    ok(!$first->is_active && !$third->is_active, 'delivered FIFO handles are inactive');
};

subtest 'work queued during defer drain waits for a later turn' => sub {
    my $loop = Linux::Event::Loop->new;
    my @seen;
    $loop->defer(sub {
        push @seen, 'outer';
        $loop->defer(sub { push @seen, 'inner' });
    });

    $loop->run_once(100);
    is_deeply(\@seen, ['outer'], 'recursive defer is excluded from current drain');
    is($loop->resources->{pending_deferred}, 1, 'recursive work remains pending');
    $loop->run_once(100);
    is_deeply(\@seen, [qw(outer inner)], 'recursive defer runs on later turn');
};

subtest 'defer from readiness callback is non-reentrant' => sub {
    my $loop = Linux::Event::Loop->new;
    pipe(my $reader, my $writer) or die "pipe: $!";
    my @seen;
    my $registration = $loop->watch(
        fh => $reader,
        read => sub ($watcher) {
            sysread($reader, my $bytes, 16);
            push @seen, 'io-enter';
            $loop->defer(sub { push @seen, 'deferred' });
            push @seen, 'io-exit';
            $watcher->cancel;
        },
    );
    syswrite($writer, 'x');
    $loop->run_once(100);
    is_deeply(\@seen, [qw(io-enter io-exit)],
        'readiness callback completes before deferred work');
    $loop->run_once(100);
    is_deeply(\@seen, [qw(io-enter io-exit deferred)],
        'deferred readiness follow-up runs later');
    close $reader;
    close $writer;
};

subtest 'exception propagation preserves later queued work' => sub {
    my $loop = Linux::Event::Loop->new;
    my @seen;
    my $failed = $loop->defer(sub { die "defer failure\n" });
    my $later = $loop->defer(sub { push @seen, 'later' });

    like(exception(sub { $loop->run_once(100) }), qr/defer failure/,
        'deferred callback exception propagates');
    ok(!$loop->running, 'driver state is restored after deferred exception');
    ok(!$failed->is_active, 'failed callback is consumed');
    ok($later->is_active, 'later callback remains pending');
    is($loop->resources->{pending_deferred}, 1, 'remaining work stays queued');

    $loop->run_once(100);
    is_deeply(\@seen, ['later'], 'later work runs after caller recovers');
    ok(!$later->is_active, 'later handle completes normally');
};

subtest 'deferred drain is bounded' => sub {
    my $loop = Linux::Event::Loop->new;
    my $calls = 0;
    $loop->defer(sub { $calls++ }) for 1 .. 1025;

    $loop->run_once(100);
    is($calls, 1024, 'one turn executes at most the documented batch');
    is($loop->resources->{pending_deferred}, 1, 'overflow work remains pending');
    $loop->run_once(100);
    is($calls, 1025, 'remaining work runs on a later turn');
};

done_testing;
