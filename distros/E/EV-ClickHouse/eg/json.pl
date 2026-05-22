#!/usr/bin/env perl
# JSON column round-trip: insert nested hashrefs, select them back.
use strict;
use warnings;
use EV;
use EV::ClickHouse;
use Data::Dumper; $Data::Dumper::Sortkeys = 1;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    settings   => { allow_experimental_json_type => 1 },
    on_connect => sub {
        $ch->query("create temporary table eg_json (j JSON) ENGINE = Memory", sub {
            $ch->insert('eg_json', [
                [{ user => { id => 1, name => 'alice', tags => ['x','y'] } }],
                [{ user => { id => 2, name => 'bob',   tags => ['z']     } }],
            ], sub {
                $ch->query("select j from eg_json", sub {
                    my ($rows) = @_;
                    print Dumper($rows);
                    EV::break;
                });
            });
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);
EV::run;
