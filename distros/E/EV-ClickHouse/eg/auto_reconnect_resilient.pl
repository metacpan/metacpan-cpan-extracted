#!/usr/bin/env perl
# Auto-reconnect resilient against permanent failures: cap retries with
# reconnect_max_attempts so a wrong host / wrong port / refused server
# fires a terminal "max reconnect attempts exceeded" error instead of
# spinning forever.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host                   => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port                   => $ENV{CLICKHOUSE_PORT} // 1,    # bad port to demo
    auto_reconnect         => 1,
    reconnect_delay        => 0.1,
    reconnect_max_delay    => 2.0,
    reconnect_max_attempts => 5,
    connect_timeout        => 0.5,
    on_connect             => sub { print "Connected\n" },
    on_error               => sub {
        my $msg = $_[0];
        print "[err] $msg\n";
        if ($msg =~ /max reconnect attempts exceeded/) {
            print "Giving up.\n";
            EV::break;
        }
    },
);

EV::run;
