#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# Echo server that shuts down gracefully on SIGINT/SIGTERM: it sends a Close
# frame (1001 "going away") to every open connection, lets them drain briefly,
# then stops the loop.
#
# Usage: perl eg/graceful_shutdown.pl [port]    (Ctrl-C to stop)

my $port = shift // 8080;
my $ctx  = EV::Websockets::Context->new;

my $bound = $ctx->listen(
    port       => $port,
    on_connect => sub { warn "client connected\n" },
    on_message => sub { my ($c, $d) = @_; $c->send("echo: $d") },
    on_close   => sub { warn "client closed\n" },
);
warn "listening on port $bound; Ctrl-C to shut down\n";

my $shutting_down = 0;
# Keep the watchers alive for the life of the process.
my $sigint  = EV::signal('INT',  \&graceful_shutdown);
my $sigterm = EV::signal('TERM', \&graceful_shutdown);

sub graceful_shutdown {
    return if $shutting_down++;
    my @conns = $ctx->connections;
    warn "shutting down; closing " . scalar(@conns) . " connection(s)\n";
    $_->close(1001, "server going away") for @conns;
    # Let the Close frames flush, then leave the loop.
    my $t; $t = EV::timer(1, 0, sub { undef $t; EV::break });
}

EV::run;
warn "stopped cleanly\n";
