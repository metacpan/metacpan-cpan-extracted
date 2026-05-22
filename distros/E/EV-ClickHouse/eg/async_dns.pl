#!/usr/bin/env perl
# Async DNS via EV::cares: when EV::cares is installed, the constructor
# resolves hostnames non-blockingly off the EV loop instead of calling
# the blocking getaddrinfo(3). Falls back automatically if EV::cares
# isn't available. Use with hostnames that may stall under DNS pressure
# (e.g. consul / k8s service names behind flaky resolvers).
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST}        // 'localhost',
    port       => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol   => 'native',
    on_connect => sub {
        $ch->query("select hostName(), version()", sub {
            my ($r) = @_;
            printf "connected: host=%s version=%s\n",
                   $r->[0][0], $r->[0][1];
            EV::break;
        });
    },
    on_error => sub { die "Error: $_[0]\n" },
);
EV::run;
$ch->finish;
