#!/usr/bin/env perl
# TLS connection — connect over a TLS-fronted ClickHouse port.
#
# Set up a TLS endpoint (e.g. with stunnel or nginx) and point this script
# at it via CLICKHOUSE_TLS_HOST / CLICKHOUSE_TLS_PORT.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host = $ENV{CLICKHOUSE_TLS_HOST} // 'localhost';
my $port = $ENV{CLICKHOUSE_TLS_PORT} // 9440;
my $ca   = $ENV{CLICKHOUSE_TLS_CA};        # optional extra CA bundle

my $ch;
$ch = EV::ClickHouse->new(
    host             => $host,
    port             => $port,
    protocol         => 'native',
    tls              => 1,
    ($ca ? (tls_ca_file => $ca) : (tls_skip_verify => 1)),
    on_connect       => sub {
        printf "Connected over TLS to %s\n", $ch->server_info;
        $ch->query("select 1 + 1 as two", sub {
            my ($rows, $err) = @_;
            die "Error: $err\n" if $err;
            printf "1 + 1 = %d\n", $rows->[0][0];
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);

EV::run;
