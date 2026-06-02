#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# WebSocket echo server over TLS (wss://) -- the server-side counterpart to
# eg/self_signed.pl (which is the client side).
#
# Generate a self-signed cert/key for local testing:
#   openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
#     -keyout key.pem -out cert.pem -subj /CN=localhost
#
# Usage: perl eg/tls_server.pl [cert.pem] [key.pem] [port]
#   then: perl eg/self_signed.pl wss://localhost:8443/

my $cert = shift // 'cert.pem';
my $key  = shift // 'key.pem';
my $port = shift // 8443;

die "cert/key not readable ($cert / $key); see the header for how to make them\n"
    unless -r $cert && -r $key;

my $ctx = EV::Websockets::Context->new;

my $bound = $ctx->listen(
    port     => $port,
    ssl_cert => $cert,
    ssl_key  => $key,
    on_connect => sub {
        my ($conn) = @_;
        warn "TLS client connected from " . ($conn->peer_address // '?') . "\n";
    },
    on_message => sub {
        my ($conn, $data, $is_binary) = @_;
        $conn->send("echo: $data");
    },
    on_close => sub { warn "client closed\n" },
    on_error => sub { my ($conn, $err) = @_; warn "error: $err\n" },
);

warn "wss:// server listening on port $bound\n";
EV::run;
