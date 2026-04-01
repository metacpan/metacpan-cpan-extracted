#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# Enable debug
EV::Websockets::_set_debug(1);

my $url = $ARGV[0] || 'wss://ws.postman-echo.com/raw';

print "Connecting to $url...\n";

my $ctx = EV::Websockets::Context->new();

my $conn;
my $timeout = EV::timer(10, 0, sub {
    print "Timeout!\n";
    EV::break;
});

$conn = $ctx->connect(
    url => $url,
    on_connect => sub {
        my ($c) = @_;
        print "Connected!\n";
        print "Sending: Hello, WebSocket!\n";
        $c->send("Hello, WebSocket!");
    },
    on_message => sub {
        my ($c, $data, $is_binary, $is_final) = @_;
        print "Received: $data (binary=$is_binary, final=$is_final)\n";

        if ($data eq "Hello, WebSocket!") {
            print "Sending: Goodbye!\n";
            $c->send("Goodbye!");
        } else {
            print "Closing connection...\n";
            $c->close(1000, "Test complete");
        }
    },
    on_close => sub {
        my ($c, $code, $reason) = @_;
        print "Connection closed: code=$code", ($reason ? " reason=$reason" : ""), "\n";
        EV::break;
    },
    on_error => sub {
        my ($c, $err) = @_;
        print "Error: $err\n";
        EV::break;
    },
);

print "Connection initiated, wsi=", ($conn ? "ok" : "null"), "\n";
print "Starting event loop...\n";
EV::run;
print "Done.\n";
