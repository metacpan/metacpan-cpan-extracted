use v5.36;
use strict;
use warnings;

use Test::More;
use POSIX ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

sub reap_ok ($pid, $description) {
    is(waitpid($pid, 0), $pid, "$description child reaped");
    is($? >> 8, 0, "$description child succeeded");
}

subtest 'callback-triggered Stream move through run' => sub {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";
    my $loop = Linux::Event::Loop->new;
    pipe(my $report_reader, my $report_writer) or die "pipe failed: $!";

    my ($request, $parent_pid, $parent_quiescent, $inside_callback);
    my $stream = Linux::Event::IO::Sock::Stream->new(
        loop => $loop,
        fh   => $left,
        on_data => sub ($stream, $bytes) {
            return unless $bytes eq 'FORK';
            $inside_callback = $loop->running;
            $request = $loop->defer_fork(
                move => [$stream],
                on_child => sub {
                    my $ok = !$loop->running && $loop->has($stream)
                        && $stream->state eq 'active'
                        && !$request->is_active;
                    syswrite($report_writer, $ok ? 'Y' : 'N');
                    POSIX::_exit($ok ? 0 : 1);
                },
                on_parent => sub ($pid) {
                    $parent_pid = $pid;
                    $parent_quiescent = !$loop->running;
                    $loop->stop;
                },
            );
        },
    );

    syswrite($right, 'FORK');
    $loop->run;
    ok($inside_callback, 'fork was requested while native dispatch was active');
    ok($parent_quiescent, 'parent callback runs outside native dispatch');
    ok($parent_pid > 0, 'parent receives child pid');
    is($stream->state, 'moved', 'Stream moved out of parent');
    ok(!$request->is_active, 'completed handle is inactive');
    is(sysread($report_reader, my $response, 1), 1, 'child reports status');
    is($response, 'Y', 'child callback sees reconstructed Stream and quiescent Loop');
    reap_ok($parent_pid, 'Stream move');
    close $right;
    close $report_reader;
    close $report_writer;
};

subtest 'queued forks are parent-only and FIFO' => sub {
    my $loop = Linux::Event::Loop->new;
    my @pids;
    my ($first, $second);
    $loop->defer(sub {
        $first = $loop->defer_fork(
            on_child => sub { POSIX::_exit(!$second->is_active ? 0 : 1) },
            on_parent => sub ($pid) { push @pids, $pid },
        );
        $second = $loop->defer_fork(
            on_child => sub { POSIX::_exit(0) },
            on_parent => sub ($pid) {
                push @pids, $pid;
                $loop->stop;
            },
        );
    });
    $loop->run;
    is(scalar @pids, 2, 'parent processed both queued fork requests');
    ok($pids[0] != $pids[1], 'distinct children were created');
    ok(!$first->is_active && !$second->is_active, 'both requests consumed');
    reap_ok($_, 'queued fork') for @pids;
};

subtest 'cancellation and strict option validation' => sub {
    my $loop = Linux::Event::Loop->new;
    for my $bad (
        [missing => []],
        [move => 'not an array'],
        [on_parent => 'not a callback'],
    ) {
        my $ok = eval { $loop->defer_fork(@$bad); 1 };
        ok(!$ok, "invalid option $bad->[0] rejected");
        like($@, qr/defer_fork\(\):/, 'clear deferred fork error');
    }

    my $called = 0;
    my $handle = $loop->defer_fork(on_parent => sub { $called++ });
    ok($handle->is_active, 'queued handle starts active');
    is($handle->cancel, $handle, 'cancel returns handle');
    is($handle->cancel, $handle, 'cancel is idempotent');
    ok(!$handle->is_active, 'cancelled handle is inactive');
    $loop->run_once(100);
    is($called, 0, 'cancelled fork did not run');
};

subtest 'on_error reports deferred preflight failures' => sub {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";
    my $loop = Linux::Event::Loop->new;
    my $stream = Linux::Event::IO::Sock::Stream->new(
        loop => $loop, fh => $left, on_data => sub { },
    );
    my $reported;
    my $handle = $loop->defer_fork(
        share => [$stream],
        on_error => sub ($error) { $reported = $error },
    );
    $loop->run_once(100);
    like($reported, qr/does not support 'share'/,
        'on_error receives managed fork preflight failure');
    ok(!$handle->is_active, 'failed request is consumed');
    ok($loop->has($stream), 'failed fork leaves original Stream intact');
    $stream->close;
    close $right;
};

subtest 'run_once and poll handle forks at the quiescent boundary' => sub {
    for my $driver (qw(run_once poll)) {
        my $loop = Linux::Event::Loop->new;
        my ($pid, $was_quiescent);
        $loop->defer(sub {
            $loop->defer_fork(
                on_child => sub { POSIX::_exit($loop->running ? 1 : 0) },
                on_parent => sub ($child_pid) {
                    $pid = $child_pid;
                    $was_quiescent = !$loop->running;
                },
            );
        });
        $driver eq 'poll' ? $loop->poll : $loop->run_once(100);
        ok($pid > 0, "$driver executes queued fork");
        ok($was_quiescent, "$driver uses quiescent boundary");
        reap_ok($pid, $driver);
    }
};

subtest 'run_for preserves bounded driving' => sub {
    my $loop = Linux::Event::Loop->new;
    my $pid;
    $loop->defer(sub {
        $loop->defer_fork(
            on_child => sub { POSIX::_exit(0) },
            on_parent => sub ($child_pid) {
                $pid = $child_pid;
                $loop->stop;
            },
        );
    });
    $loop->run_for(1);
    ok($pid > 0, 'run_for dispatches pending fork');
    reap_ok($pid, 'run_for');
};


subtest 'explicit stop postpones fork until the next drive' => sub {
    my $loop = Linux::Event::Loop->new;
    my $pid;
    $loop->defer(sub {
        $loop->defer_fork(
            on_child => sub { POSIX::_exit(0) },
            on_parent => sub ($child_pid) {
                $pid = $child_pid;
                $loop->stop;
            },
        );
        $loop->stop;
    });
    $loop->run;
    ok(!defined $pid, 'explicit stop wins over queued request');
    $loop->run;
    ok($pid > 0, 'a later drive processes postponed fork');
    reap_ok($pid, 'postponed fork');
};

subtest 'handled deferred fork failure keeps run alive' => sub {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";
    my $loop = Linux::Event::Loop->new;
    my $stream = Linux::Event::IO::Sock::Stream->new(
        loop => $loop, fh => $left, on_data => sub { },
    );
    my ($reported, $continued);
    $loop->defer(sub {
        $loop->defer_fork(
            share => [$stream],
            on_error => sub ($error) {
                $reported = $error;
                $loop->defer(sub { $continued = 1; $loop->stop });
            },
        );
    });
    $loop->run;
    like($reported, qr/does not support 'share'/,
        'managed fork error was reported');
    ok($continued, 'driver continued running after handled fork error');
    $stream->close;
    close $right;
};

done_testing;
