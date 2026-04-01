#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use EV::Websockets;
use Time::HiRes qw(time);

# Benchmark: Latency (Connection + Handshake time)

my $iterations = 50;

sub bench_ev_websockets {
    print "Benchmarking EV::Websockets Latency ($iterations iterations)...\n";
    my $ctx = EV::Websockets::Context->new();
    my %srv_conns;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $srv_conns{$_[0]} = $_[0] },
        on_close => sub { delete $srv_conns{$_[0]} },
    );
    my @latencies;

    for (1..$iterations) {
        my $start = time;
        my $c; $c = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                push @latencies, time - $start;
                $_[0]->close;
            },
            on_close => sub { EV::break; },
            on_error => sub { EV::break; },
        );
        EV::run;
    }

    if (!@latencies) { print "  No latencies recorded.\n"; return 0; }
    my $sum = 0; $sum += $_ for @latencies;
    my $avg = $sum / @latencies;
    printf "  Average Latency: %.4f ms\n\n", $avg * 1000;
    return $avg;
}

sub bench_ae_ws_client {
    print "Benchmarking AnyEvent::WebSocket::Client Latency ($iterations iterations)...\n";
    my $ctx = EV::Websockets::Context->new();
    my %srv_conns;
    my $port = $ctx->listen(
        port => 0,
        on_connect => sub { $srv_conns{$_[0]} = $_[0] },
        on_close => sub { delete $srv_conns{$_[0]} },
    );
    
    my @latencies;

    for (1..$iterations) {
        my $client = AnyEvent::WebSocket::Client->new;
        my $start = time;
        $client->connect("ws://127.0.0.1:$port")->cb(sub {
            my $conn = eval { shift->recv };
            push @latencies, time - $start;
            if ($conn) {
                $conn->on(finish => sub { EV::break; });
                $conn->close;
            } else {
                EV::break;
            }
        });
        EV::run;
    }

    if (!@latencies) { print "  No latencies recorded.\n"; return 0; }
    my $sum = 0; $sum += $_ for @latencies;
    my $avg = $sum / @latencies;
    printf "  Average Latency: %.4f ms\n\n", $avg * 1000;
    return $avg;
}

my $ev_lat = bench_ev_websockets();
my $ae_lat = bench_ae_ws_client();

if ($ev_lat > 0 && $ae_lat > 0) {
    printf "Comparison: EV::Websockets is %.2fx %s than AnyEvent::WebSocket::Client\n",
        ($ev_lat < $ae_lat ? $ae_lat/$ev_lat : $ev_lat/$ae_lat),
        ($ev_lat < $ae_lat ? "FASTER (lower latency)" : "SLOWER (higher latency)");
}
