#!/usr/bin/env perl
# with totals — totals row read via the last_totals accessor.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // $ENV{TEST_CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    on_connect => sub {
        $ch->query(
            "select number % 3 as bucket, count() as n
               from numbers(100)
              group by bucket
              with totals
              order by bucket",
            sub {
                my ($rows, $err) = @_;
                die "Error: $err\n" if $err;
                printf "bucket %d -> %d rows\n", @$_ for @$rows;

                if (my $totals = $ch->last_totals) {
                    printf "TOTAL: %d rows across %d buckets\n",
                        $totals->[0][1], scalar @$rows;
                }
                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
