#!/usr/bin/env perl
# HTTP basic auth behind a reverse proxy. Many gateway setups
# (nginx, Envoy, k8s ingress) strip the proprietary X-ClickHouse-User
# and X-ClickHouse-Key headers but forward Authorization verbatim.
# Pass http_basic_auth => 1 to send credentials as
# `Authorization: Basic base64(user:password)` instead.
#
# Pair with `auth_request` / `proxy_pass` in nginx, JWT middleware
# in Envoy, etc. — the client side is the same regardless.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host = $ENV{CLICKHOUSE_HOST} // '127.0.0.1';
my $port = $ENV{CLICKHOUSE_PORT} // 8123;
my $user = $ENV{CLICKHOUSE_USER} // 'default';
my $pass = $ENV{CLICKHOUSE_PASS} // '';

my $ch; $ch = EV::ClickHouse->new(
    host            => $host, port => $port, protocol => 'http',
    user            => $user, password => $pass,
    http_basic_auth => 1,         # ← Authorization: Basic ...
    on_connect      => sub {
        $ch->query("select hostName(), version()", sub {
            my ($rows, $err) = @_;
            die "query: $err\n" if $err;
            printf "Connected via Basic auth: %s on CH %s\n",
                   $rows->[0][0], $rows->[0][1];
            EV::break;
        });
    },
    on_error => sub { die "error: $_[0]\n" },
);
EV::run;
$ch->finish;
