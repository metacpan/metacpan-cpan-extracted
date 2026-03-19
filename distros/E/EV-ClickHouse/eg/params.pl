#!/usr/bin/env perl
# Parameterized queries — safe value binding without SQL injection
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
        # Numeric parameters
        $ch->query(
            "SELECT {x:UInt32} + {y:UInt32} AS sum, {name:String} AS greeting",
            { params => { x => 100, y => 200, name => "hello world" } },
            sub {
                my ($rows, $err) = @_;
                die "Error: $err\n" if $err;
                printf "sum=%d, greeting=%s\n", $rows->[0][0], $rows->[0][1];

                # Parameters work with HTTP too (use param_ prefix directly)
                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
