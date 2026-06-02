#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

# Keep a connection alive with periodic pings and detect a dead peer when a
# pong does not come back in time.
#
# Usage: perl eg/keepalive.pl [ws://host:port/path] [ping_interval] [pong_timeout]

my $url      = shift // 'ws://127.0.0.1:8080/';
my $interval = shift // 15;    # seconds between pings
my $timeout  = shift // 10;    # seconds to wait for each pong

my $ctx = EV::Websockets::Context->new;
my ($ping_timer, $pong_deadline);

my $conn = $ctx->connect(
    url => $url,
    on_connect => sub {
        my ($c) = @_;
        warn "connected; pinging every ${interval}s\n";
        $ping_timer = EV::timer($interval, $interval, sub {
            return unless $c->is_connected;
            $c->send_ping("keepalive");
            # Expect a pong within $timeout, else treat the peer as dead.
            $pong_deadline = EV::timer($timeout, 0, sub {
                warn "no pong within ${timeout}s; closing dead connection\n";
                $c->close(1000);
            });
        });
    },
    on_pong => sub {
        $pong_deadline = undef;    # peer is alive; cancel the deadline
    },
    on_message => sub {
        my ($c, $data) = @_;
        warn "message: $data\n";
    },
    on_close => sub {
        warn "closed\n";
        $ping_timer = $pong_deadline = undef;
        EV::break;
    },
    on_error => sub {
        my ($c, $err) = @_;
        warn "error: $err\n";
        $ping_timer = $pong_deadline = undef;
        EV::break;
    },
);

EV::run;
