#!/usr/bin/env perl
# Connect over a Unix-domain socket instead of TCP.
#
# Pass the socket path as `path` to the constructor (or call
# $g->connect_unix($path) later). Everything else — submit, work,
# admin — is identical to the TCP case.
#
# gearmand 1.x only listens on TCP, so for a quick local demo bridge a
# Unix socket to it with socat in another terminal:
#
#   socat UNIX-LISTEN:/tmp/gm.sock,fork TCP:127.0.0.1:4730
#
# Usage: unix_socket.pl [/path/to/socket]   (default /tmp/gm.sock)
use strict;
use warnings;
use EV;
use EV::Gearman;

my $path = $ARGV[0] // '/tmp/gm.sock';

# For Unix sockets connect(2) usually completes immediately, so pass
# on_connect in the constructor — a later $g->on_connect could miss it.
my $g = EV::Gearman->new(
    path       => $path,
    on_connect => sub { warn "[client] connected via $path\n" },
    on_error   => sub { warn "[client] error: $_[0]\n"; EV::break },
);

$g->echo("ping over unix", sub {
    my ($echoed, $err) = @_;
    die "echo failed: $err\n" if $err;
    warn "[client] echo round-trip: $echoed\n";
    EV::break;
});

my $guard = EV::timer 5, 0, sub { warn "timeout (is the socat bridge up?)\n"; EV::break };
EV::run;
