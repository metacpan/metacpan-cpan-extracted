#!/usr/bin/env perl
# Multi-host failover: pass `hosts => [...]` to the constructor; on
# connect-phase failure (refused, timeout, hello stall), the client
# advances to the next host in round-robin order. Pair with
# auto_reconnect for automatic recovery without user intervention.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $port = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;
my $ch;
$ch = EV::ClickHouse->new(
    hosts                  => ["127.0.0.1:1", "127.0.0.1:2", "127.0.0.1:$port"],
    protocol               => 'native',
    connect_timeout        => 0.5,
    auto_reconnect         => 1,
    reconnect_delay        => 0.1,
    reconnect_max_attempts => 10,
    on_error               => sub { print "[err] $_[0]\n" },
    on_connect             => sub {
        $ch->query("select 'connected to $port'", sub {
            my ($r) = @_;
            print "result: ", $r->[0][0], "\n";
            EV::break;
        });
    },
);
EV::run;
$ch->finish if $ch->is_connected;
