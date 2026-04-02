#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use Feersum;
use EV::Websockets;
use IO::Socket::INET;

# Feersum PSGI API: use psgi_request_handler with psgix.io
# to get the raw socket for WebSocket adoption.
#
# This example shows how to integrate EV::Websockets into a
# standard PSGI application running on Feersum.

my $ctx = EV::Websockets::Context->new();

my $feersum = Feersum->endjinn;
$feersum->set_psgix_io(1); # enable psgix.io in env

my $sock = IO::Socket::INET->new(
    Listen    => 128,
    LocalAddr => '0.0.0.0',
    LocalPort => $ARGV[0] || 8080,
    ReuseAddr => 1,
    Blocking  => 0,
) or die "Cannot create socket: $!";

my $port = $sock->sockport;
$feersum->use_socket($sock);

print "Feersum PSGI + EV::Websockets on ws://127.0.0.1:$port\n";
print "Connect: wscat -c ws://127.0.0.1:$port/ws\n\n";

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

my %connections;

# PSGI app
my $app = sub {
    my ($env) = @_;

    # Regular HTTP requests
    unless (($env->{HTTP_UPGRADE} // '') =~ /websocket/i) {
        return [200,
            ['Content-Type' => 'text/html'],
            ["<h1>WebSocket Server</h1><p>Connect with a WS client.</p>\n"]];
    }

    # WebSocket upgrade via psgix.io
    my $io = $env->{'psgix.io'};
    unless ($io) {
        return [500, ['Content-Type' => 'text/plain'],
                ["psgix.io not available\n"]];
    }

    my $path = $env->{REQUEST_URI} // '/';

    # adopt() holds a reference to $io internally
    $ctx->adopt(
        fh           => $io,
        initial_data => env_to_http_request($env),
        on_connect => sub {
            my ($c) = @_;
            $connections{"$c"} = $c;
            print "[+] PSGI WebSocket on $path\n";
            $c->send("Connected via PSGI on $path");
        },
        on_message => sub {
            my ($c, $data) = @_;
            print "[msg] $data\n";
            $c->send("echo: $data");
        },
        on_close => sub {
            my ($c) = @_;
            delete $connections{"$c"};
            print "[-] Disconnected\n";
        },
        on_error => sub {
            my ($c, $err) = @_;
            delete $connections{"$c"};
            warn "[err] $err\n";
        },
    );

    return; # Feersum detaches the connection when psgix.io is accessed
};

$feersum->psgi_request_handler($app);

EV::run;
