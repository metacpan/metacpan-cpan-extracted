#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# This example demonstrates real-time state monitoring of a connection.

my $url = $ARGV[0] || 'wss://ws.postman-echo.com/raw';
my $ctx = EV::Websockets::Context->new();

print "Initiating connection to $url...
";

my $conn = $ctx->connect(
    url => $url,
    on_connect => sub { print "--- Event: on_connect ---
" },
    on_close   => sub { print "--- Event: on_close ---
"; EV::break; },
    on_error   => sub { print "--- Event: on_error ---
"; EV::break; },
);

# Poll the state every 0.1 seconds
my $monitor = EV::timer(0, 0.1, sub {
    printf "Current State: %s (Connecting: %d, Connected: %d)
",
        $conn->state,
        $conn->is_connecting,
        $conn->is_connected;
    
    if ($conn->is_connected) {
        print "Stable connection reached. Closing in 1s...
";
        shift->stop;
        EV::timer(1, 0, sub { $conn->close(1000, "Done") });
    }
});

EV::run;
