#!/usr/bin/env perl
# Basic HTTP query example
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_PORT} // 8123,
    on_connect => sub {
        print "Connected via HTTP\n";
    },
    on_error => sub { warn "Connection error: $_[0]\n"; EV::break },
);

$ch->query("SELECT number, number * number AS square FROM system.numbers LIMIT 10 FORMAT TabSeparated", sub {
    my ($rows, $err) = @_;
    if ($err) {
        warn "Query error: $err\n";
    } else {
        printf "%3s  %s\n", "n", "n^2";
        printf "%3s  %s\n", $_->[0], $_->[1] for @$rows;
    }
    EV::break;
});

EV::run;
