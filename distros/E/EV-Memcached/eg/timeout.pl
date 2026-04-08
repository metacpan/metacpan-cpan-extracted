#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Connect timeout: abort stalled TCP connections.
# Uses a non-routable IP to demonstrate the timeout.

print "Connecting to non-routable host with 2s timeout...\n";

my $mc = EV::Memcached->new(
    host            => '192.0.2.1',   # TEST-NET, guaranteed non-routable
    port            => 11211,
    connect_timeout => 2000,          # 2 seconds
    on_error        => sub {
        my ($msg) = @_;
        print "Error (expected): $msg\n";
        EV::break;
    },
    on_connect => sub {
        print "Connected (unexpected!)\n";
        EV::break;
    },
);

my $start = EV::now;
EV::run;
printf "Took %.1fs\n", EV::now - $start;
