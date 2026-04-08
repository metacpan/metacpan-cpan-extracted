#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Automatic reconnection: the client will retry connecting
# when the connection is lost.

my $mc = EV::Memcached->new(
    host                        => $ENV{MC_HOST} // '127.0.0.1',
    port                        => $ENV{MC_PORT} // 11211,
    reconnect                   => 1,
    reconnect_delay             => 2000,    # 2 seconds between attempts
    max_reconnect_attempts      => 10,
    resume_waiting_on_reconnect => 1,       # replay queued commands
    on_error      => sub { warn "Error: @_\n" },
    on_connect    => sub { print "Connected at " . localtime() . "\n" },
    on_disconnect => sub { print "Disconnected at " . localtime() . "\n" },
);

# Periodic version check as heartbeat
my $w = EV::timer 0, 3, sub {
    $mc->version(sub {
        my ($ver, $err) = @_;
        if ($err) {
            warn "VERSION failed: $err\n";
        } else {
            print "Server version: $ver  (" . localtime() . ")\n";
        }
    });
};

print "Checking version every 3s.\n";
print "Try stopping/starting memcached to see reconnection...\n\n";
EV::run;
