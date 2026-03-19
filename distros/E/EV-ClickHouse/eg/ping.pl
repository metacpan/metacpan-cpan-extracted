#!/usr/bin/env perl
# Ping example — health check with reconnect on failure
use strict;
use warnings;
use EV;
use EV::ClickHouse;
$| = 1;

my $ch;
$ch = EV::ClickHouse->new(
    host            => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port            => $ENV{CLICKHOUSE_PORT} // 8123,
    connect_timeout => 5,
    on_connect => sub { print "Connected\n" },
    on_error   => sub {
        warn "Connection lost: $_[0]\n";
        # reconnect after 1 second
        my $t; $t = EV::timer 1, 0, sub { undef $t; $ch->reconnect };
    },
);

# Ping every 2 seconds
my $w = EV::timer 0, 2, sub {
    return unless $ch->is_connected;
    $ch->ping(sub {
        my (undef, $err) = @_;
        if ($err) {
            warn "Ping failed: $err\n";
        } else {
            printf "Pong (connected=%d, pending=%d)\n",
                $ch->is_connected, $ch->pending_count;
        }
    });
};

print "Pinging every 2s — Ctrl+C to stop\n";
EV::run;
