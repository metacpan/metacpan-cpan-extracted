#!/usr/bin/env perl
# IPv6 — bracketed IPv6 literal in a connection URI.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

# URI form is required for IPv6 literals so the brackets disambiguate the
# address from the port: clickhouse://[host]:port/db
my $uri = $ENV{CLICKHOUSE_URI}
    // 'clickhouse+native://default:@[::1]:9000/default';

my $ch;
$ch = EV::ClickHouse->new(
    uri        => $uri,
    on_connect => sub {
        printf "Connected to %s\n", $ch->server_info;
        $ch->query("select hostName(), version()", sub {
            my ($rows, $err) = @_;
            die "Error: $err\n" if $err;
            printf "host=%s version=%s\n", @{$rows->[0]};
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
