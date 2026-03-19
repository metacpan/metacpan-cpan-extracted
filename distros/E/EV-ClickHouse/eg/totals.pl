#!/usr/bin/env perl
# WITH TOTALS — separate totals/extremes from data rows
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
        $ch->query(
            "SELECT number % 3 AS g, count() AS c, sum(number) AS s "
            . "FROM numbers(100) GROUP BY g WITH TOTALS ORDER BY g",
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
                        $totals->[0][0] // 'NULL', $totals->[0][1], $totals->[0][2];
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
