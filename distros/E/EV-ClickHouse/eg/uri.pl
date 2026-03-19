#!/usr/bin/env perl
# Connection URI — single-string connection specification
use strict;
use warnings;
use EV;
use EV::ClickHouse;

# URI format: clickhouse[+native]://user:password@host:port/database?key=val
my $uri = $ENV{CLICKHOUSE_URI}
    // 'clickhouse+native://default:@127.0.0.1:9000/default';

my $ch;
$ch = EV::ClickHouse->new(
    uri        => $uri,
    on_connect => sub {
        printf "Connected: %s\n", $ch->server_info;
        $ch->query("SELECT currentDatabase() AS db", sub {
            my ($rows, $err) = @_;
            die "Error: $err\n" if $err;
            printf "Database: %s\n", $rows->[0][0];
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
