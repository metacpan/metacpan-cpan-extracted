#!/usr/bin/env perl
# Fan-out — fire N independent queries concurrently and gather all results.
#
# A single connection serializes requests at the wire (the pipeline); the
# event loop is what's "concurrent" here. For true parallelism you'd open
# multiple clients, one per worker.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my @queries = (
    "select 'hello' as greeting",
    "select count() as rows from system.numbers limit 1000",
    "select version()",
    "select now() as now",
    "select uptime() as up",
);

my $ch;
my %results;

$ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // $ENV{TEST_CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    on_connect => sub {
        for my $i (0 .. $#queries) {
            $ch->query($queries[$i], sub {
                my ($rows, $err) = @_;
                $results{$i} = $err ? "ERROR: $err" : $rows->[0];
            });
        }

        # drain fires when every query has completed.
        $ch->drain(sub {
            for my $i (sort { $a <=> $b } keys %results) {
                my $r = $results{$i};
                printf "  [%d] %-50s -> %s\n",
                    $i, $queries[$i],
                    ref $r eq 'ARRAY' ? join(", ", map defined $_ ? $_ : 'null', @$r)
                                      : $r;
            }
            $ch->finish;
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
