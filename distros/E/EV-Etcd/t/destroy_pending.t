#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;

# Destroying the client cancels a pending lock acquisition instead of
# hanging in join. Fork-guarded: the child must exit promptly on its own.

BEGIN {
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;
use IO::Socket::INET;
use POSIX ();

# Probed without EV::Etcd: a parent that started gRPC makes the child's new()
# croak where gRPC is never shut down (macOS)
plan skip_all => 'etcd not available on 127.0.0.1:2379'
    unless IO::Socket::INET->new(PeerAddr => '127.0.0.1:2379', Timeout => 2);

plan tests => 2;

{
    my $pid = fork();
    defined $pid or BAIL_OUT("fork failed: $!");
    if ($pid == 0) {
        my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
        my ($l1, $l2, $acquired);
        my $run = sub {
            my $t = EV::timer(5, 0, sub { EV::break });
            EV::run;
        };
        $client->lease_grant(60, sub { my ($r, $e) = @_; $l1 = $r->{id} if !$e; EV::break });
        $run->();
        POSIX::_exit(2) unless $l1;
        my $name = "/test-destroy-pending-$$-" . time();
        $client->lock($name, $l1, sub { my ($r, $e) = @_; $acquired = 1 if !$e; EV::break });
        $run->();
        POSIX::_exit(2) unless $acquired;
        $client->lease_grant(60, sub { my ($r, $e) = @_; $l2 = $r->{id} if !$e; EV::break });
        $run->();
        POSIX::_exit(2) unless $l2;
        $client->lock($name, $l2, sub { EV::break });
        undef $client;
        POSIX::_exit(0);
    }
    my ($done, $status) = (0, 0);
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(20);
        waitpid($pid, 0);
        $status = $?;
        $done = 1;
        alarm(0);
    };
    if (!$done) {
        kill('KILL', $pid);
        waitpid($pid, 0);
    }
    ok($done, 'destroy with pending lock completed without hanging');
    SKIP: {
        skip 'child hung', 1 unless $done;
        is($status >> 8, 0, 'child exited 0 after destroying client with pending lock');
    }
}

done_testing();
