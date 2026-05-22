#!/usr/bin/env perl
# Decimal128/256 columns deliver raw 16/32 LE bytes — pair with
# Math::BigInt::Calc / Math::BigFloat for arbitrary-precision arithmetic.
use strict;
use warnings;
use EV;
use EV::ClickHouse;
use Math::BigInt;

sub le_bytes_to_bigint {
    my ($buf, $signed) = @_;
    my @b = unpack 'C*', $buf;
    my $n = Math::BigInt->new(0);
    my $bit = 1;
    for my $byte (@b) {
        $n += Math::BigInt->new($byte) * $bit;
        $bit *= 256;
    }
    if ($signed && $b[-1] & 0x80) {
        $n -= Math::BigInt->new(256) ** scalar(@b);
    }
    return $n;
}

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        $ch->query(
            "select toDecimal256('123456789012345678901234567890.123456789', 9) as d",
            sub {
                my ($rows) = @_;
                my $raw = $rows->[0][0];     # 32 bytes LE
                my $big = le_bytes_to_bigint($raw, 1);
                # scale = 9 → divide by 10^9
                printf "raw  (%d bytes): %s\n", length($raw), unpack 'H*', $raw;
                printf "int: %s\n", $big;
                printf "as scaled decimal: %s\n", ($big / Math::BigInt->new(10)**9);
                EV::break;
            });
    },
    on_error => sub { die "Error: $_[0]\n" },
);
EV::run;
