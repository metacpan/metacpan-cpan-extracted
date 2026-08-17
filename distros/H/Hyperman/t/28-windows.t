#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports server_reap);
use IO::Socket::INET;
use Time::HiRes ();

# The Windows contract, asserted rather than assumed: one worker serves,
# and a request for a pool is REFUSED at boot instead of being silently
# downgraded to one worker. An application sized for four workers should
# find that out from a croak, not from its throughput.
#
# Everywhere else this file proves the complement: a pool is available,
# so run() with workers => 2 does not croak.

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

my $win = ($^O eq 'MSWin32');

# ---- workers => 2 --------------------------------------------------------
# run() blocks when it succeeds, so this has to happen in a child either
# way: on Windows we expect the croak, elsewhere we expect it to serve.
{
    my $pid = fork;
    plan skip_all => 'cannot fork to test run()' unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>', '/dev/null' if -e '/dev/null';
        my $err = '';
        eval {
            require Hyperman;
            Hyperman->run(
                app     => sub { [ 200, [ 'Content-Type' => 'text/plain' ], ['x'] ] },
                host    => '127.0.0.1',
                port    => $port,
                workers => 2,
            );
            1;
        } or $err = $@;
        # exit 3 = croaked (what Windows must do), 0 = ran (everywhere else)
        POSIX::_exit($err =~ /worker pool needs fork/ ? 3 : 0)
            if eval { require POSIX; 1 };
        exit($err =~ /worker pool needs fork/ ? 3 : 0);
    }

    if ($win) {
        my $st = server_reap($pid);
        is($st >> 8, 3,
           'workers => 2 croaks at boot rather than downgrading silently');
    }
    else {
        # it should still be running (serving) a moment later
        Time::HiRes::sleep(0.5);
        my $gone = waitpid($pid, 1);   # WNOHANG
        is($gone, 0, 'a worker pool runs where fork(2) exists');
        kill 'TERM', $pid;
        server_reap($pid);
    }
}

# ---- the croak says what to do instead -----------------------------------
SKIP: {
    skip 'the croak only happens on Windows', 1 unless $win;
    require Hyperman;
    my $err = '';
    eval {
        Hyperman->run(
            app     => sub { [ 200, [], [''] ] },
            host    => '127.0.0.1',
            port    => $port,
            workers => 4,
        );
        1;
    } or $err = $@;
    like($err, qr/workers => 1/,
         'the croak names the setting that does work');
}

done_testing;
