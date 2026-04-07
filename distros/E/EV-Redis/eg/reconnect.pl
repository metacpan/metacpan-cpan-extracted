#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host                        => '127.0.0.1',
    reconnect                   => 1,
    reconnect_delay             => 2000,
    max_reconnect_attempts      => 10,
    resume_waiting_on_reconnect => 1,
    on_error   => sub { warn "Error: @_\n" },
    on_connect => sub { print "Connected\n" },
    on_disconnect => sub { print "Disconnected\n" },
);

# periodic ping
my $w = EV::timer 0, 3, sub {
    $redis->ping(sub {
        my ($res, $err) = @_;
        if ($err) { warn "PING error: $err\n" }
        else      { print "PONG at " . scalar(localtime) . "\n" }
    });
};

print "Pinging every 3s (try stopping/starting redis-server)...\n";
EV::run;
