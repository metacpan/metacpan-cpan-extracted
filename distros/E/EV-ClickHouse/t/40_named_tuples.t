#!/usr/bin/env perl
# Named tuples — Tuple(a Int32, b String, c Array(UInt8)) — round-trip
# via native protocol. ClickHouse decodes named tuples the same as
# positional tuples (we always emit arrayrefs), but the *type metadata*
# carries the field names; column_types should reflect them verbatim.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

plan tests => 5;

my $tbl  = "ev_ch_ntup_$$";
my $rows; my $types; my $err;

my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $port, protocol => 'native',
    on_connect => sub {
        $ch->query(
            "create table $tbl (t Tuple(a Int32, b String, c Array(UInt8))) engine=Memory",
            sub {
                my (undef, $e) = @_; $err = $e and return EV::break;
                $ch->insert($tbl, [[[1, 'x', [10, 20]]],
                                   [[2, 'y', []]],
                                   [[-3, "with\ttab", [255]]]], sub {
                    my (undef, $e) = @_; $err = $e and return EV::break;
                    $ch->query("select t from $tbl order by t.1", sub {
                        ($rows, $err) = @_;
                        $types = $ch->column_types;
                        $ch->query("drop table $tbl", sub { EV::break });
                    });
                });
            });
    },
    on_error => sub { $err = $_[0]; EV::break },
);

my $bail = EV::timer(8, 0, sub { EV::break }); EV::run; undef $bail;
$ch->finish;

ok !$err,           'no error' or diag $err;
is scalar @{$rows // []}, 3,    '3 rows';
is_deeply $rows->[0][0], [-3, "with\ttab", [255]], 'first row: tab-string + ipv4-ish array';
is_deeply $rows->[1][0], [1, 'x', [10, 20]],       'second row';
like $types->[0],
     qr/\ATuple\(\s*a\s+Int32\s*,\s*b\s+String\s*,\s*c\s+Array\(UInt8\)\s*\)\z/,
     'column_types preserves the named-tuple metadata verbatim';
