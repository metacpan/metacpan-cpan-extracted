#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use Feersum;
use EV::Websockets;
use IO::Socket::INET;

# Feersum native API: accept HTTP, detect WebSocket upgrade,
# hand socket to EV::Websockets via adopt(initial_data => ...).
#
# Feersum parses the HTTP request headers. We reconstruct them
# from the PSGI env and replay them to lws via initial_data.

my $ctx = EV::Websockets::Context->new();
# A listener vhost is required for adopt() to work with lws 4.5+
$ctx->listen(port => 0, on_connect => sub {}, on_message => sub {});

my $feersum = Feersum->endjinn;

my $sock = IO::Socket::INET->new(
    Listen    => 128,
    LocalAddr => '0.0.0.0',
    LocalPort => $ARGV[0] || 8080,
    ReuseAddr => 1,
    Blocking  => 0,
) or die "Cannot create socket: $!";

my $port = $sock->sockport;
$feersum->use_socket($sock);

print "Feersum+EV::Websockets server on ws://127.0.0.1:$port\n";
print "Connect: wscat -c ws://127.0.0.1:$port/chat\n\n";

# Helper: reconstruct HTTP request from PSGI env
sub env_to_http_request {
    my ($env) = @_;
    my $path = $env->{REQUEST_URI} // $env->{PATH_INFO} // '/';
    my $req = "GET $path HTTP/1.1\r\n";
    for my $key (sort keys %$env) {
        next unless $key =~ /^HTTP_(.+)/;
        (my $hdr = $1) =~ s/_/-/g;
        $req .= "$hdr: $env->{$key}\r\n";
    }
    $req .= "\r\n";
    return $req;
}

# Track all WebSocket connections for broadcast
my %connections;

$feersum->request_handler(sub {
    my $req = shift;
    my $env = $req->env;

    # Only handle WebSocket upgrades
    unless (($env->{HTTP_UPGRADE} // '') =~ /websocket/i) {
        $req->send_response(200,
            ['Content-Type' => 'text/plain'],
            ["This is a WebSocket server. Connect with a WS client.\n"]);
        return;
    }

    # Get raw socket — adopt() holds a reference to $io internally
    my $io = $req->io;

    my $path = $env->{REQUEST_URI} // '/';

    $ctx->adopt(
        fh           => $io,
        initial_data => env_to_http_request($env),
        on_connect => sub {
            my ($c) = @_;
            $connections{"$c"} = $c;
            print "[+] Client connected to $path (",
                  scalar keys %connections, " total)\n";
            $c->send("Welcome to $path!");
        },
        on_message => sub {
            my ($c, $data, $is_binary) = @_;
            print "[msg] $data\n";
            # Broadcast to all connected clients
            for my $peer ($ctx->connections) {
                $peer->send($data);
            }
        },
        on_close => sub {
            my ($c) = @_;
            delete $connections{"$c"};
            print "[-] Client disconnected (",
                  scalar keys %connections, " remaining)\n";
        },
        on_error => sub {
            my ($c, $err) = @_;
            delete $connections{"$c"};
            warn "[err] $err\n";
        },
    );
});

EV::run;
