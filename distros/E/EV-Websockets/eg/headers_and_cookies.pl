#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;
use Data::Dumper;

# This example demonstrates sending custom handshake headers (like Authorization)
# and inspecting server response headers (like Set-Cookie).

my $url = $ARGV[0] || 'wss://ws.postman-echo.com/raw';
my $ctx = EV::Websockets::Context->new();

print "Connecting to $url with custom headers...
";

my $conn = $ctx->connect(
    url     => $url,
    headers => {
        'Authorization'    => 'Bearer my-secret-token',
        'X-Client-Version' => '1.2.3',
    },
    on_connect => sub {
        my ($c, $resp_headers) = @_;
        print "Connected!
";
        print "Selected Protocol: ", ($c->get_protocol || "none"), "
";
        
        if ($resp_headers) {
            print "Server Response Headers:
";
            print Dumper($resp_headers);
        }
        
        $c->send("Identify yourself");
    },
    on_message => sub {
        my ($c, $data) = @_;
        print "Received: $data
";
        $c->close(1000, "Goodbye");
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
