#!/usr/bin/env perl
# Graceful shutdown with drain — wait for all pending queries to complete
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    on_connect => sub {
        # Fire several queries
        for my $i (1..5) {
            $ch->query("SELECT $i AS n, sleep(0.1)", sub {
                my ($rows, $err) = @_;
                printf "Query %d: %s\n", $i, $err // "ok (n=$rows->[0][0])";
            });
        }
        printf "Queued %d queries (pending=%d)\n",
            5, $ch->pending_count;

        # drain fires after all queries complete
        $ch->drain(sub {
            print "All queries done, shutting down\n";
            $ch->finish;
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
