#!/usr/bin/env perl
# Keepalive — periodic pings keep idle connections alive
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host      => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port      => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol  => 'native',
    keepalive => 30,   # ping every 30 seconds when idle
    on_connect => sub {
        printf "Connected with keepalive=30s: %s\n", $ch->server_info;

        # Simulate idle time, then query
        my $t; $t = EV::timer(2, 0, sub {
            undef $t;
            printf "Still connected after 2s idle: %s\n",
                $ch->is_connected ? "yes" : "no";
            $ch->query("SELECT 1", sub {
                my ($rows, $err) = @_;
                printf "Query after idle: %s\n", $err // "ok";
                $ch->finish;
                EV::break;
            });
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
