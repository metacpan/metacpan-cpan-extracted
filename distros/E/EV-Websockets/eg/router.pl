#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# Route connections by request path. on_handshake sees the request headers
# (including Path) and can reject before the upgrade; on_connect then dispatches
# on the path. Try paths /echo, /time, and /secret (rejected).
#
# Usage: perl eg/router.pl [port]

my $port = shift // 8080;
my $ctx  = EV::Websockets::Context->new;

my $bound = $ctx->listen(
    port => $port,
    on_handshake => sub {
        my ($headers) = @_;
        my $path = $headers->{Path} // '/';
        warn "handshake for $path\n";
        return 0 if $path eq '/secret';   # reject -> client gets 403
        return 1;                          # accept (could return a headers hashref)
    },
    on_connect => sub {
        my ($conn, $headers) = @_;         # server side: request headers
        my $path = $headers->{Path} // '/';
        $conn->stash->{path} = $path;
        $conn->send("time is " . localtime) if $path eq '/time';
    },
    on_message => sub {
        my ($conn, $data) = @_;
        my $path = $conn->stash->{path} // '/';
        if    ($path eq '/echo') { $conn->send("echo: $data") }
        elsif ($path eq '/time') { $conn->send("time is " . localtime) }
        else                     { $conn->send("no handler for $path") }
    },
    on_error => sub { my ($conn, $err) = @_; warn "error: $err\n" },
);

warn "router on port $bound (paths: /echo /time /secret)\n";
EV::run;
