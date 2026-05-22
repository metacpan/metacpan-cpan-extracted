#!/usr/bin/env perl
# Exhaustive LZ4 round-trip across the type matrix in one wide table.
# Insert a small number of rows via the native protocol with compression
# on, read them back compressed, and check value-for-value equality.
# A regression in any single decoder shows up here as a typed mismatch
# instead of a generic decode error far from the cause.
use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use IO::Socket::INET;

my $host = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

plan tests => 3;

my $tbl = "ev_ch_compr_$$";

# Each entry: [ name, ClickHouse type, [ value@row0, row1, row2 ] ].
# Ordering matters — arrayref insert uses positional ordering.
my @cols = (
    [ i8       => 'Int8',                  [ -128, 0, 127 ] ],
    [ u8       => 'UInt8',                 [ 0, 1, 255 ] ],
    [ i16      => 'Int16',                 [ -32768, 0, 32767 ] ],
    [ u16      => 'UInt16',                [ 0, 1, 65535 ] ],
    [ i32      => 'Int32',                 [ -2_000_000_000, 0, 2_000_000_000 ] ],
    [ u32      => 'UInt32',                [ 0, 1, 4_000_000_000 ] ],
    [ i64      => 'Int64',                 [ -9_000_000_000_000_000, 0, 9_000_000_000_000_000 ] ],
    [ f32      => 'Float32',               [ -1.5, 0, 3.25 ] ],
    [ f64      => 'Float64',               [ -1e9, 0, 3.14159265358979 ] ],
    [ str      => 'String',                [ '', 'abc', "with\ttab" ] ],
    [ fstr     => 'FixedString(4)',        [ "ABCD", "1234", "____" ] ],
    [ dt       => 'DateTime',              [ '2024-01-02 03:04:05', '2024-12-31 23:59:59', '2000-01-01 00:00:00' ] ],
    [ d32      => 'Date32',                [ '1925-01-01', '2024-06-15', '2299-12-31' ] ],
    [ uuid     => 'UUID',                  [ '00000000-0000-0000-0000-000000000000',
                                             '11111111-2222-3333-4444-555555555555',
                                             'ffffffff-ffff-ffff-ffff-ffffffffffff' ] ],
    [ ipv4     => 'IPv4',                  [ '127.0.0.1', '10.0.0.1', '255.255.255.255' ] ],
    [ ipv6     => 'IPv6',                  [ '::1', '2001:db8::1', '::ffff:1.2.3.4' ] ],
    [ nul      => 'Nullable(String)',      [ undef, 'present', '' ] ],
    [ lc       => 'LowCardinality(String)',[ 'a', 'b', 'a' ] ],
    [ arr      => 'Array(Int32)',          [ [], [1], [1,2,3] ] ],
);

my $col_decl  = join ', ', map { "$_->[0] $_->[1]" } @cols;
my $col_names = join ', ', map { $_->[0] } @cols;

my @rows;
for my $r (0 .. 2) {
    push @rows, [ map { $_->[2][$r] } @cols ];
}

my $err_phase;
my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $port, protocol => 'native',
    compress => 1,
    decode_datetime => 1,
    on_connect => sub {
        $ch->query(
            "create table $tbl ($col_decl) engine=Memory",
            sub {
                my (undef, $err) = @_;
                if ($err) { $err_phase = "create: $err"; return EV::break }
                $ch->insert("$tbl ($col_names)", \@rows, sub {
                    my (undef, $err) = @_;
                    if ($err) { $err_phase = "insert: $err"; return EV::break }
                    $ch->query(
                        "select $col_names from $tbl order by i32",
                        sub {
                            my ($got, $err) = @_;
                            if ($err) { $err_phase = "select: $err"; return EV::break }
                            ok defined($got) && @$got == 3, '3 rows round-tripped';
                            my $all_ok = 1;
                            for my $r (0 .. 2) {
                                for my $i (0 .. $#cols) {
                                    my ($n, $type, $exp) = @{ $cols[$i] };
                                    my $expv = $exp->[$r];
                                    my $gotv = $got->[$r][$i];
                                    my $eq;
                                    if (!defined $expv && !defined $gotv) { $eq = 1 }
                                    elsif (!defined $expv || !defined $gotv) { $eq = 0 }
                                    elsif (ref $expv eq 'ARRAY') {
                                        $eq = (ref $gotv eq 'ARRAY'
                                               && @$expv == @$gotv
                                               && !grep { $expv->[$_] != $gotv->[$_] } 0..$#$expv);
                                    }
                                    elsif ($type =~ /^Float/) {
                                        $eq = abs(($expv - $gotv) / ($expv || 1)) < 1e-5;
                                    }
                                    else { $eq = "$expv" eq "$gotv" }
                                    unless ($eq) {
                                        diag "row $r col $n ($type): got=".
                                             (defined $gotv ? (ref $gotv ? "[@$gotv]" : "'$gotv'") : 'undef').
                                             " expected=".
                                             (defined $expv ? (ref $expv ? "[@$expv]" : "'$expv'") : 'undef');
                                        $all_ok = 0;
                                    }
                                }
                            }
                            ok $all_ok, 'all values round-trip cleanly under LZ4';
                            $ch->query("drop table $tbl", sub { EV::break });
                        });
                });
            });
    },
    on_error => sub { $err_phase = "conn: $_[0]"; EV::break },
);

my $bail = EV::timer(30, 0, sub { EV::break });
EV::run;
undef $bail;
eval { $ch->finish };

ok !$err_phase, "no error during round-trip"
    or diag "phase error: $err_phase";
