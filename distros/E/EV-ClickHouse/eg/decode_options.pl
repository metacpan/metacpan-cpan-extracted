#!/usr/bin/env perl
# Decode options — formatted dates, scaled decimals, enum labels, named rows
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host            => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port            => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol        => 'native',
    decode_datetime => 1,   # "2024-01-15 10:30:00" instead of epoch
    decode_decimal  => 1,   # 12345.67 instead of 1234567
    decode_enum     => 1,   # "active" instead of 1
    named_rows      => 1,   # hashrefs instead of arrayrefs
    on_connect => sub {
        $ch->query(
            "SELECT
                toDateTime('2024-06-15 14:30:00', 'America/New_York') AS dt,
                toDecimal64(12345.67, 2) AS price,
                CAST('active' AS Enum8('inactive' = 0, 'active' = 1)) AS status",
            sub {
                my ($rows, $err) = @_;
                die "Error: $err\n" if $err;

                my $row = $rows->[0];  # hashref with named keys
                printf "DateTime:  %s\n", $row->{dt};
                printf "Decimal:   %s\n", $row->{price};
                printf "Enum:      %s\n", $row->{status};
                printf "Types:     %s\n", join(', ', @{$ch->column_types});
                EV::break;
            },
        );
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
