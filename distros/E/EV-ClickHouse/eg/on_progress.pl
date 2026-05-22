#!/usr/bin/env perl
# on_progress — periodic progress reports for long-running queries.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
my $progress_count = 0;

$ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // $ENV{TEST_CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    on_progress => sub {
        my ($rows, $bytes, $total_rows, $written_rows, $written_bytes) = @_;
        $progress_count++;
        printf "  progress: %d rows / %d bytes (total target=%d)\n",
            $rows, $bytes, $total_rows;
    },
    on_connect => sub {
        $ch->query(
            "select sum(number) from numbers(50000000)",
            sub {
                my ($rows, $err) = @_;
                die "Error: $err\n" if $err;
                printf "Result: %s (%d progress packets)\n",
                    $rows->[0][0], $progress_count;
                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
