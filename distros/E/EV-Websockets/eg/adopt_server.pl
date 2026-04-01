#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use AnyEvent;
use AnyEvent::Socket;
use EV::Websockets;

# This example demonstrates adopting a socket accepted by AnyEvent::Socket
# and upgrading it to a WebSocket connection.

my $ctx = EV::Websockets::Context->new();
$ctx->listen(port => 0, on_connect => sub {}, on_message => sub {});

my $port = 8080;

print "Listening on port $port...
";
print "Connect using: wscat -c ws://127.0.0.1:$port
";

my $server; $server = tcp_server undef, $port, sub {
    my ($fh, $host, $peer_port) = @_;
    print "Accepted connection from $host:$peer_port
";

    # Hand the socket over to EV::Websockets
    $ctx->adopt(
        fh => $fh,
        on_connect => sub {
            my ($c, $headers) = @_;
            print "WebSocket handshake successful!
";
            $c->send("Welcome to the adopted server");
        },
        on_message => sub {
            my ($c, $data) = @_;
            print "Received: $data
";
            $c->send("Echo: $data");
        },
        on_close => sub {
            print "Client disconnected.
";
        },
        on_error => sub {
            my ($c, $err) = @_;
            warn "Error: $err
";
        }
    );
};

EV::run;
