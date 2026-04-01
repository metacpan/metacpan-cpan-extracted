#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# This example demonstrates connecting to a server with a self-signed certificate.
# Note: This is common in development or local network environments.

my $url = $ARGV[0];
unless ($url) {
    print "Usage: perl eg/self_signed.pl wss://localhost:8443/ws
";
    print "(Assuming you have a local WSS server running with self-signed certs)
";
    exit;
}

my $ctx = EV::Websockets::Context->new();

print "Connecting to $url (SSL Verify DISABLED)...
";

my $conn = $ctx->connect(
    url        => $url,
    ssl_verify => 0, # Allow self-signed and hostname mismatches
    on_connect => sub {
        print "Connected despite self-signed certificate!
";
        shift->close(1000, "Success");
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
