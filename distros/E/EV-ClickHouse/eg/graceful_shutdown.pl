#!/usr/bin/env perl
# Graceful shutdown — drain pending queries then finish, then break the loop.
#
# This is the canonical "submit all my work and exit cleanly" pattern.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
my $disconnected = 0;

$ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // $ENV{TEST_CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    on_disconnect => sub { $disconnected = 1 },
    on_connect    => sub {
        # Queue several queries with realistic latency.
        for my $i (1 .. 5) {
            $ch->query("select $i as n, sleep(0.2)", sub {
                my ($rows, $err) = @_;
                printf "  query %d: %s\n", $i,
                    $err ? "ERROR ($err)" : "ok";
            });
        }
        printf "queued %d queries (pending=%d)\n", 5, $ch->pending_count;

        # drain fires once every queued + in-flight query has completed.
        # finish closes the socket; on_disconnect runs before drain returns
        # (state is reset before the callback fires).
        $ch->drain(sub {
            $ch->finish;
            printf "shutdown complete (on_disconnect fired=%d)\n", $disconnected;
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
