#!/usr/bin/env perl
# End-to-end failover scenario:
#   - Pass hosts => [bad, good]
#   - Verify on_failover fires once with the right (old, new) tuple
#   - Verify the connection actually lands on the good host
#   - Verify current_host / current_port reflect the live target
use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use IO::Socket::INET;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 6;

my @failovers;
my $ok;
my $ch; $ch = EV::ClickHouse->new(
    hosts            => ["$host:1", "$host:$nport"],     # bad, good
    protocol         => 'native',
    connect_timeout  => 1,
    auto_reconnect   => 1,
    reconnect_delay  => 0.05,
    on_failover      => sub {
        my ($oh, $op, $nh, $np, $msg) = @_;
        push @failovers, [$oh, $op, $nh, $np, $msg];
    },
    on_connect       => sub {
        $ch->query("select 42", sub { my ($r) = @_; $ok = $r->[0][0]; EV::break });
    },
    on_error         => sub { },
);
my $bail = EV::timer(5, 0, sub { EV::break });
EV::run;
undef $bail;

is        $ok,             42,       'connection landed on the good host';
ok        scalar(@failovers) >= 1,   'on_failover fired at least once';
is        $failovers[0][1], 1,       '  old port was the bad one (1)';
is        $failovers[0][3], $nport,  '  new port is the good one';
is        $ch->current_port, $nport, 'current_port reflects active host';
like      $ch->current_host, qr/\A\Q$host\E\z/, 'current_host reflects active host';

$ch->finish if $ch->is_connected;
