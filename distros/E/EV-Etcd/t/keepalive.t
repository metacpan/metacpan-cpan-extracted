#!/usr/bin/env perl
# An endpoint that stops answering on an open connection (host hang, silent
# partition) is found by keepalive pings, and the client fails over. Uses two
# etcds started here; the first is frozen with SIGSTOP.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use File::Temp 'tempdir';
use IO::Socket::INET;
use POSIX ();

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

plan skip_all => 'etcd needed in PATH'
    unless grep { -x "$_/etcd" } split /:/, $ENV{PATH} || '';

my $dir = tempdir(CLEANUP => 1);
my @etcd_pids;
END {
    local $?;
    for (@etcd_pids) { kill CONT => $_; kill TERM => $_; waitpid $_, 0 }
}

sub free_port {
    my $s = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    return $s->sockport;
}

sub start_etcd {
    my ($name) = @_;
    my ($port, $peer) = (free_port(), free_port());
    my $pid = fork;
    defined $pid or die "fork: $!";
    unless ($pid) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        exec 'etcd', '--name', $name, '--data-dir', "$dir/$name",
            '--listen-client-urls', "http://127.0.0.1:$port",
            '--advertise-client-urls', "http://127.0.0.1:$port",
            '--listen-peer-urls', "http://127.0.0.1:$peer",
            '--initial-advertise-peer-urls', "http://127.0.0.1:$peer",
            '--initial-cluster', "$name=http://127.0.0.1:$peer",
            '--grpc-keepalive-min-time', '500ms'
            or POSIX::_exit(127);
    }
    push @etcd_pids, $pid;
    return ($pid, "127.0.0.1:$port");
}

sub put_err {
    my ($client) = @_;
    my $err = 'no callback';
    $client->put("/test_keepalive_$$", 'v', sub { $err = $_[1]; EV::break });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    return $err;
}

my ($frozen_pid, $frozen) = start_etcd('a');
my (undef, $spare) = start_etcd('b');

my $up = 0;
for (1 .. 50) {
    $up = !defined put_err(EV::Etcd->new(endpoints => [$frozen], timeout => 1))
       && !defined put_err(EV::Etcd->new(endpoints => [$spare], timeout => 1));
    last if $up;
    select undef, undef, undef, 0.2;
}
plan skip_all => 'etcd did not start' unless $up;

my $c = EV::Etcd->new(
    endpoints         => [$frozen, $spare],
    timeout           => 10,
    keepalive_time    => 1,
    keepalive_timeout => 1,
);
is(put_err($c), undef, 'put on the first endpoint');

kill STOP => $frozen_pid;
my $t0 = EV::time;
my $err = put_err($c);
my $took = EV::time - $t0;
is(ref $err && $err->{status}, 'UNAVAILABLE', 'call on the frozen endpoint fails as unavailable')
    or diag explain $err;
cmp_ok($took, '<', 8, 'found by keepalive long before the call timeout');
is(put_err($c), undef, 'next call reaches the second endpoint');

done_testing();
