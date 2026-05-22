#!/usr/bin/env perl
# named_rows — rows as hashrefs keyed by column name.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // $ENV{TEST_CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    named_rows => 1,
    on_connect => sub {
        $ch->query(
            "select number as n,
                    toString(number) as as_str,
                    number * number as sq
               from numbers(5)",
            sub {
                my ($rows, $err) = @_;
                die "Error: $err\n" if $err;
                for my $row (@$rows) {
                    printf "n=%d str=%s sq=%d\n",
                        $row->{n}, $row->{as_str}, $row->{sq};
                }
                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
