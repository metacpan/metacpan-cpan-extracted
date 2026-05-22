#!/usr/bin/env perl
# A "types zoo" select exercising every supported scalar / nested type.
# Useful as a quick smoke check when running against a new ClickHouse
# server version. Set decode_datetime/decode_decimal/decode_enum for
# nicer string output.
use strict;
use warnings;
use EV;
use EV::ClickHouse;
use Data::Dumper; $Data::Dumper::Sortkeys = 1;

my $ch;
$ch = EV::ClickHouse->new(
    host            => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port            => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol        => 'native',
    decode_datetime => 1,
    decode_decimal  => 1,
    decode_enum     => 1,
    on_connect => sub {
        $ch->query(<<'SQL', sub {
            select
                toInt8(-1)                                          as i8,
                toUInt64(2**63)                                     as u64,
                toFloat32(1.5)                                      as f32,
                toBFloat16(2.5)                                     as bf16,
                'hello'                                             as s,
                toFixedString('abc', 8)                             as fs,
                toDate('2030-01-02')                                as d,
                toDate32('2099-12-31')                              as d32,
                toDateTime64('2030-01-02 03:04:05.678', 3)          as dt64,
                toDecimal64('1234.56', 2)                           as dec64,
                toUUID('6ba7b810-9dad-11d1-80b4-00c04fd430c8')      as u,
                toIPv4('1.2.3.4')                                   as ip4,
                toIPv6('::1')                                       as ip6,
                CAST('b' as Enum8('a' = 1, 'b' = 2))                as e8,
                toBool(true)                                        as b,
                [1, 2, 3]                                           as arr,
                (42, 'x')                                           as tup,
                map('k', 1)                                         as m,
                toLowCardinality('xx')                              as lc,
                toIntervalSecond(15)                                as iv,
                toPoint(10, 20)                                     as pt
SQL
            my ($rows, $err) = @_;
            die $err if $err;
            print Dumper($rows->[0]);
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);
EV::run;
