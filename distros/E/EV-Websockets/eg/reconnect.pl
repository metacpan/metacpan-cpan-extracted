#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# A client with automated reconnection logic
# Usage: perl eg/reconnect.pl [url]

my $url = $ARGV[0] || 'ws://127.0.0.1:12345';
my $ctx = EV::Websockets::Context->new();

my $conn;
my $reconnect_timer;
my $delay = 1;

sub connect_ws {
    print "Attempting to connect to $url...
";
    $conn = $ctx->connect(
        url => $url,
        on_connect => sub {
            my ($c) = @_;
            print "Connected successfully!
";
            $delay = 1; # Reset delay on success
            $c->send("Hello from persistent client");
        },
        on_message => sub {
            my ($c, $data) = @_;
            print "Got message: $data
";
        },
        on_close => sub {
            undef $conn;
            print "Connection closed. Reconnecting in ${delay}s...
";
            schedule_reconnect();
        },
        on_error => sub {
            my ($c, $err) = @_;
            undef $conn;
            print "Connection error: $err. Reconnecting in ${delay}s...
";
            schedule_reconnect();
        },
    );
}

sub schedule_reconnect {
    return if $reconnect_timer;
    # Exponential backoff with jitter: wait 50-100% of the current window so a
    # fleet of clients does not reconnect in lockstep (thundering herd).
    my $wait = $delay * (0.5 + rand 0.5);
    $reconnect_timer = EV::timer($wait, 0, sub {
        $reconnect_timer = undef;
        $delay *= 2 if $delay < 30;
        connect_ws();
    });
}

connect_ws();
EV::run;
