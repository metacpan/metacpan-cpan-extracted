#!/usr/bin/env perl
# with totals — separate totals/extremes from data rows
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
            "select number % 3 as g, count() as c, sum(number) as s "
            . "from numbers(100) group by g with totals order by g",
            sub {
                my ($rows, $err) = @_;
                die "Error: $err\n" if $err;

                my $names = $ch->column_names;
                my $types = $ch->column_types;

                printf "Columns: %s\n", join(', ',
                    map { "$names->[$_] ($types->[$_])" } 0..$#$names);

                printf "\nData rows:\n";
                printf "  g=%d  count=%d  sum=%d\n", @$_ for @$rows;

                if (my $totals = $ch->last_totals) {
                    printf "\nTotals:\n";
                    printf "  g=%s  count=%d  sum=%d\n",
                        $totals->[0][0] // 'null', $totals->[0][1], $totals->[0][2];
                }

                printf "\nProfile: %d rows, %d bytes\n",
                    $ch->profile_rows, $ch->profile_bytes;

                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
