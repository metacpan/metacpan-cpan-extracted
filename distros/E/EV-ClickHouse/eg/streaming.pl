#!/usr/bin/env perl
# Streaming results with on_data — process rows as they arrive
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
        my $block_count = 0;
        my $total_rows  = 0;

        $ch->query(
            "SELECT number, toString(number) FROM numbers(100000)",
            {
                on_data => sub {
                    my ($rows) = @_;
                    $block_count++;
                    $total_rows += scalar @$rows;
                    printf "  block %d: %d rows (total so far: %d)\n",
                        $block_count, scalar @$rows, $total_rows;
                },
            },
            sub {
                my (undef, $err) = @_;
                die "Error: $err\n" if $err;
                printf "Done: %d blocks, %d total rows\n",
                    $block_count, $total_rows;
                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
