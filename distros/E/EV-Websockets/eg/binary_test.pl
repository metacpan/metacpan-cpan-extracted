#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# A simple script to demonstrate binary data transfer
# Usage: perl eg/binary_test.pl [url]

my $url = $ARGV[0] || 'wss://ws.postman-echo.com/raw';
my $ctx = EV::Websockets::Context->new();

print "Connecting to $url (Binary Test)...
";

my $conn = $ctx->connect(
    url => $url,
    on_connect => sub {
        my ($c) = @_;
        print "Connected. Sending binary packet...
";
        
        # Create a packed binary packet (e.g., 4 floats)
        my $binary_data = pack "f4", 1.23, 4.56, 7.89, 0.12;
        $c->send_binary($binary_data);
    },
    on_message => sub {
        my ($c, $data, $is_binary) = @_;
        if ($is_binary) {
            my @vals = unpack "f*", $data;
            print "Received binary response: @vals
";
        } else {
            print "Received text response: $data
";
        }
        $c->close(1000, "Test finished");
    },
    on_close => sub {
        print "Closed.
";
        EV::break;
    },
    on_error => sub {
        my ($c, $err) = @_;
        warn "Error: $err
";
        EV::break;
    },
);

EV::run;
