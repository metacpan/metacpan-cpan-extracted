use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# named_rows + decode_datetime + decode_decimal + decode_enum round-trip.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

plan tests => 9;

# 1-3: named_rows
{
    my $ch;
    my $rows;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        protocol   => 'native',
        named_rows => 1,
        on_connect => sub {
            $ch->query("select 1 as one, 'two' as two, 3.14 as three", sub {
                my ($r, $err) = @_;
                $rows = $r unless $err;
                EV::break;
            });
        },
        on_error => sub { diag("error: $_[0]"); EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok($rows && @$rows == 1, "named_rows: 1 row");
    my $first = ($rows && @$rows) ? $rows->[0] : undef;
    is(ref $first, 'HASH', "named_rows: row is hashref");
    is_deeply([sort keys %{$first || {}}], ['one', 'three', 'two'],
        "named_rows: keys match column names");
    $ch->finish if $ch->is_connected;
}

# 4-5: decode_datetime
{
    my $ch;
    my $rows;
    $ch = EV::ClickHouse->new(
        host            => $host,
        port            => $port,
        protocol        => 'native',
        decode_datetime => 1,
        on_connect      => sub {
            $ch->query("select toDateTime('2024-01-15 10:30:00', 'UTC') as dt,
                               toDate('2024-01-15') as d", sub {
                my ($r, $err) = @_;
                $rows = $r unless $err;
                EV::break;
            });
        },
        on_error => sub { diag("error: $_[0]"); EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    my $r = ($rows && @$rows) ? $rows->[0] : undef;
    is($r ? $r->[0] : undef, '2024-01-15 10:30:00',
        "decode_datetime: DateTime as string");
    is($r ? $r->[1] : undef, '2024-01-15',
        "decode_datetime: Date as string");
    $ch->finish if $ch->is_connected;
}

# 6-7: decode_decimal
{
    my $ch;
    my $rows;
    $ch = EV::ClickHouse->new(
        host           => $host,
        port           => $port,
        protocol       => 'native',
        decode_decimal => 1,
        on_connect     => sub {
            $ch->query("select toDecimal64('123.456', 3) as d", sub {
                my ($r, $err) = @_;
                $rows = $r unless $err;
                EV::break;
            });
        },
        on_error => sub { diag("error: $_[0]"); EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok($rows && @$rows, "decode_decimal: got rows");
    my $val = ($rows && @$rows) ? $rows->[0][0] : undef;
    cmp_ok(abs(($val // 0) - 123.456), '<', 0.001,
        "decode_decimal: scaled value (got " . ($val // 'undef') . ")");
    $ch->finish if $ch->is_connected;
}

# 8-9: decode_enum
{
    my $ch;
    my $rows;
    $ch = EV::ClickHouse->new(
        host        => $host,
        port        => $port,
        protocol    => 'native',
        decode_enum => 1,
        on_connect  => sub {
            $ch->query(
                "select CAST('red' as Enum8('red'=1,'green'=2,'blue'=3)) as color",
                sub {
                    my ($r, $err) = @_;
                    $rows = $r unless $err;
                    EV::break;
                },
            );
        },
        on_error => sub { diag("error: $_[0]"); EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok($rows && @$rows, "decode_enum: got rows");
    is(($rows && @$rows) ? $rows->[0][0] : undef, 'red',
        "decode_enum: label not numeric");
    $ch->finish if $ch->is_connected;
}
