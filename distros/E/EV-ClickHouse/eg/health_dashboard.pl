#!/usr/bin/env perl
# Minimal HTTP dashboard exposing per-replica health for a set of
# ClickHouse replicas. GET /health returns JSON with connection state,
# last RTT, and pending_count for every replica. Wired with EV so the
# same loop drives the dashboard server, the periodic probes, and the
# ClickHouse connections.
#
# This uses one EV::ClickHouse connection per replica (not a Pool):
# Pool members all share a single failover ring, so a Pool can't pin
# member N to replica N - which is exactly what a per-replica health
# view needs.
#
# Usage:
#   CH_REPLICAS=127.0.0.1:9000,127.0.0.1:9001 ./eg/health_dashboard.pl
#   curl http://127.0.0.1:8085/health

use strict;
use warnings;
use EV;
use EV::ClickHouse;
use IO::Socket::INET;
use JSON::PP qw(encode_json);

my @replicas = split /,/, ($ENV{CH_REPLICAS}
            // '127.0.0.1:9000,127.0.0.1:9001,127.0.0.1:9002');
my $dash_port = $ENV{DASH_PORT} // 8085;

# One connection per replica, each pinned to its own host:port.
my @conns;
for my $spec (@replicas) {
    my ($h, $p) = split /:/, $spec, 2;
    push @conns, EV::ClickHouse->new(
        host           => $h,
        port           => $p // 9000,
        protocol       => 'native',
        auto_reconnect => 1,
        on_error       => sub { },   # swallow - health is read via accessors
    );
}

# Per-replica latest RTT (seconds), updated by the periodic probe.
my @rtt = (undef) x @conns;

my $probe = EV::timer(0, 5, sub {
    for my $i (0 .. $#conns) {
        $conns[$i]->ping_round_trip(sub {
            my ($s, $err) = @_;
            $rtt[$i] = $err ? undef : $s;
        });
    }
});

# Tiny HTTP server. Single-shot, no keep-alive, no streaming - just
# enough to demonstrate the JSON shape.
my $listener = IO::Socket::INET->new(
    Listen => 16, LocalAddr => '0.0.0.0', LocalPort => $dash_port,
    ReuseAddr => 1, Blocking => 0,
) or die "listen $dash_port: $!";

my $accept_io = EV::io($listener->fileno, EV::READ, sub {
    while (my $cli = $listener->accept) {
        $cli->blocking(0);
        my $buf = '';
        my $w; $w = EV::io($cli->fileno, EV::READ, sub {
            my $n = sysread($cli, $buf, 8192, length $buf);
            if (!defined $n || $n == 0) { undef $w; close $cli; return }
            return unless $buf =~ /\r\n\r\n/;
            undef $w;
            my @body;
            for my $i (0 .. $#conns) {
                my $ch = $conns[$i];
                push @body, {
                    replica       => $replicas[$i],
                    connected     => $ch->is_connected ? \1 : \0,
                    pending_count => $ch->pending_count + 0,
                    rtt_ms        => defined $rtt[$i]
                                       ? sprintf("%.2f", $rtt[$i] * 1000) + 0
                                       : undef,
                };
            }
            my $json = encode_json({ replicas => \@body });
            my $http = "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n"
                     . "Content-Length: " . length($json) . "\r\nConnection: close\r\n\r\n"
                     . $json;
            syswrite $cli, $http;
            close $cli;
        });
    }
});

warn "dashboard on :$dash_port - try: curl http://127.0.0.1:$dash_port/health\n";

my $sig = EV::signal('INT', sub {
    undef $accept_io; undef $probe;
    close $listener;
    $_->finish for @conns;
    EV::break;
});

EV::run;
