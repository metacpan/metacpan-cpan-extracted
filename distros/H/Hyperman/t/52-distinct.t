#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# DISTINCT CLIENTS, opt-in. With run(distinct_clients => 1) every accepted
# peer goes into a HyperLogLog on the arena; the estimate over N connections
# from N distinct ports lands within the sketch's error. Off, the door answers
# the empty list and the accept path is untouched (bench/arena-bench.sh's
# `hll` case is the number).

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';
plan skip_all => 'Shared::Arena is not available to this Hyperman'
    if $ENV{HYPERMAN_NO_SA_ABI} || !eval { require Shared::Arena; 1 };

my @ports = free_ports(2);
plan skip_all => 'no free loopback ports' unless @ports == 2;

is_deeply([ Hyperman->distinct_clients ], [], 'no arena: the empty list');

sub start {
    my ($port, %extra) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        Hyperman->run(
            app => sub {
                my ($c, $e) = Hyperman->distinct_clients;
                my $out = defined $c ? sprintf('distinct=%.1f err=%.4f', $c, $e) : 'off';
                [ 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => length $out ], [$out] ];
            },
            host => '127.0.0.1', port => $port, workers => 2, %extra,
        );
        exit 0;
    }
    return $pid;
}

sub http_get {
    my ($port) = @_;
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                      Proto => 'tcp', Timeout => 2);
        if (!$s) { Time::HiRes::sleep(0.05); next }
        syswrite $s, "GET / HTTP/1.0\r\nHost: x\r\n\r\n";
        local $/;
        my $res = <$s>;
        close $s;
        return $1 if defined $res && $res =~ /\r\n\r\n(.*)\z/s && length $1;
        Time::HiRes::sleep(0.05);
    }
    return '';
}

# ---- on: a client is an ADDRESS, and every connection here has the same one -
#
# The peer the accept path formats is the address without the port, which is
# what "distinct clients" means: two hundred connections from 127.0.0.1 are
# one client, however many ephemeral ports they came from. So the estimate
# over two hundred connections is one, and the sketch's own doors show it
# would count a second address as a second client.
{
    my $pid = start($ports[0], distinct_clients => 1);
    http_get($ports[0]) for 1 .. 199;
    my $body = http_get($ports[0]);          # the 200th
    my ($est, $err) = $body =~ /distinct=([\d.]+) err=([\d.]+)/;
    ok(defined $est, "the sketch is on ($body)");
    cmp_ok($est, '>=', 0.9, 'two hundred connections from one address');
    cmp_ok($est, '<=', 1.1, '...count as one client, not two hundred');
    cmp_ok($err, '<', 0.01, 'and the relative error is reported');
    kill 'TERM', $pid;
    server_reap($pid);
}

# The same sketch through Shared::Arena's own door, so the arithmetic that
# makes it a distinct count is seen to hold: two hundred distinct addresses
# land within the sketch's error of two hundred.
{
    my $arena = Shared::Arena->create(size => 512 * 1024);
    my $hll   = $arena->hll('clients', precision => 14);
    $hll->add("10.1.$_.7") for 1 .. 200;
    my $c = $hll->count;
    cmp_ok($c, '>', 190, "two hundred distinct addresses estimate near 200 ($c)");
    cmp_ok($c, '<', 210, '...within the sketch\'s error');
}

# ---- off by default ---------------------------------------------------------
{
    my $pid = start($ports[1]);
    is(http_get($ports[1]), 'off', 'with the option off the door answers nothing');
    kill 'TERM', $pid;
    server_reap($pid);
}

done_testing;
