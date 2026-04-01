#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use EV::Websockets;
use Time::HiRes qw(time);

# Benchmark: Throughput (Messages per second)

my $test_duration = 5;

sub bench_ev_websockets {
    print "Benchmarking EV::Websockets Throughput...\n";
    my $ctx = EV::Websockets::Context->new();
    my $count = 0;
    my $start_time;
    my %srv_conns;

    # 1. Native Listener
    my $port = $ctx->listen(
        port => 0,
        on_message => sub { $_[0]->send($_[1]) },
        on_close => sub { delete $srv_conns{$_[0]} },
        on_connect => sub { $srv_conns{$_[0]} = $_[0] },
    );

    # 2. Client
    my $client_conn;
    my $w = EV::timer(0.5, 0, sub {
        $client_conn = $ctx->connect(
            url => "ws://127.0.0.1:$port",
            on_connect => sub {
                $start_time = time;
                $_[0]->send("ping");
            },
            on_message => sub {
                $count++;
                if (time - $start_time < $test_duration) {
                    $_[0]->send("ping");
                } else {
                    $_[0]->close;
                }
            },
            on_close => sub { EV::break; },
            on_error => sub { warn "EV::WS Error: $_[1]"; EV::break; },
        );
    });

    EV::run;
    my $elapsed = time - ($start_time || time);
    $elapsed = 0.001 if $elapsed <= 0;
    printf "  Total messages: %d\n", $count;
    printf "  Throughput:     %.2f msg/sec\n\n", $count / $elapsed;
    return $count / $elapsed;
}

sub bench_ae_ws_client {
    print "Benchmarking AnyEvent::WebSocket::Client Throughput...\n";
    my $ctx = EV::Websockets::Context->new();
    my %srv_conns;
    
    # Use native listener for server side too, to be fair/efficient
    my $port = $ctx->listen(
        port => 0,
        on_message => sub { $_[0]->send($_[1]) },
        on_connect => sub { $srv_conns{$_[0]} = $_[0] },
        on_close => sub { delete $srv_conns{$_[0]} },
    );

    my $client = AnyEvent::WebSocket::Client->new;
    my $count = 0;
    my $start_time;

    my $w = EV::timer(0.5, 0, sub {
        $client->connect("ws://127.0.0.1:$port")->cb(sub {
            my $conn = eval { shift->recv };
            unless ($conn) { warn "AE::WS Error: $@"; EV::break; return; }
            
            $start_time = time;
            $conn->on(each_message => sub {
                $count++;
                if (time - $start_time < $test_duration) {
                    $conn->send("ping");
                } else {
                    $conn->close;
                }
            });
            $conn->on(finish => sub { EV::break; });
            
            $conn->send("ping");
        });
    });

    EV::run;
    my $elapsed = time - ($start_time || time);
    $elapsed = 0.001 if $elapsed <= 0;
    printf "  Total messages: %d\n", $count;
    printf "  Throughput:     %.2f msg/sec\n\n", $count / $elapsed;
    return $count / $elapsed;
}

my $ev_rate = bench_ev_websockets();
my $ae_rate = bench_ae_ws_client();

if ($ev_rate > 0 && $ae_rate > 0) {
    printf "Comparison: EV::Websockets is %.2fx %s than AnyEvent::WebSocket::Client\n",
        ($ev_rate > $ae_rate ? $ev_rate/$ae_rate : $ae_rate/$ev_rate),
        ($ev_rate > $ae_rate ? "FASTER" : "SLOWER");
}
