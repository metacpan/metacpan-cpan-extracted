#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use Time::HiRes qw(time);
use EV;
use EV::Websockets;

my $ROUNDS = $ARGV[0] || 1000;
my $PAYLOAD = "x" x 64;

print "WebSocket echo benchmark: $ROUNDS round-trips, 64-byte payload\n";
print "=" x 60, "\n\n";

bench_ev_websockets();

eval { require Net::WebSocket::EVx; bench_evx() };
print "Net::WebSocket::EVx: not installed, skipping\n\n" if $@;

# Mojo and Net::Async use different event loops — run in forks
bench_in_fork("Mojolicious", \&bench_mojo);
bench_in_fork("Net::Async::WebSocket", \&bench_async);

sub bench_in_fork {
    my ($name, $code) = @_;
    pipe(my $rd, my $wr) or die;
    my $pid = fork;
    if (!defined $pid) { print "$name: fork failed, skipping\n\n"; return }
    if ($pid == 0) {
        close $rd;
        open STDOUT, '>&', $wr;
        eval { $code->() };
        print "$name: not installed, skipping\n" if $@;
        exit 0;
    }
    close $wr;
    my $out = do { local $/; <$rd> };
    waitpid $pid, 0;
    print $out, "\n" if $out;
}

# --- EV::Websockets ---
sub bench_ev_websockets {
    my $ctx = EV::Websockets::Context->new();
    my $port = $ctx->listen(
        port => 0, on_connect => sub {}, on_message => sub { $_[0]->send($_[1]) },
    );
    my (%k, @lat);
    $k{c} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            my $c = $_[0];
            my ($st, $n) = (0, 0);
            $k{go} = sub { $st = time(); $c->send($PAYLOAD) };
            $k{msg} = sub {
                push @lat, (time() - $st) * 1e6; $n++;
                $n < $ROUNDS ? $k{go}->() : $c->close(1000);
            };
            $k{go}->();
        },
        on_message => sub { $k{msg}->() },
        on_close => sub { delete $k{c}; EV::break },
        on_error => sub { warn "EV::WS: $_[1]"; EV::break },
    );
    EV::timer(30, 0, sub { EV::break });
    EV::run;
    report("EV::Websockets", \@lat);
}

# --- Net::WebSocket::EVx ---
sub bench_evx {
    require IO::Socket::INET;
    require Digest::SHA;
    require MIME::Base64;

    my $srv = IO::Socket::INET->new(
        Listen => 10, LocalAddr => '127.0.0.1', LocalPort => 0,
        ReuseAddr => 1, Blocking => 0,
    ) or die;
    my $port = $srv->sockport;
    my (%k, @lat);

    my $sw; $sw = EV::io($srv, EV::READ, sub {
        my $cl = $srv->accept or return;
        $cl->blocking(0);
        my $buf = '';
        my $rw; $rw = EV::io($cl, EV::READ, sub {
            sysread($cl, $buf, 4096, length $buf);
            return unless $buf =~ /\r\n\r\n/;
            undef $rw;
            my ($key) = $buf =~ /Sec-WebSocket-Key:\s*(\S+)/i;
            my $acc = MIME::Base64::encode_base64(
                Digest::SHA::sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'), '');
            syswrite $cl, "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: $acc\r\n\r\n";
            open(my $fh, '+<&', $cl) or die;
            $k{evx} = Net::WebSocket::EVx->new({
                fh => $fh, max_recv_size => 1<<20,
                on_msg_recv => sub { $k{evx}->queue_msg($_[2]) },
                on_close => sub { undef $k{evx} },
            });
        });
    });

    my $ctx = EV::Websockets::Context->new();
    $ctx->listen(port => 0, on_connect => sub {}, on_message => sub {});

    $k{c} = $ctx->connect(
        url => "ws://127.0.0.1:$port",
        on_connect => sub {
            my $c = $_[0];
            my ($st, $n) = (0, 0);
            $k{go} = sub { $st = time(); $c->send($PAYLOAD) };
            $k{msg} = sub {
                push @lat, (time() - $st) * 1e6; $n++;
                $n < $ROUNDS ? $k{go}->() : $c->close(1000);
            };
            $k{go}->();
        },
        on_message => sub { $k{msg}->() },
        on_close => sub { delete $k{c}; undef $sw; EV::break },
        on_error => sub { warn "EVx: $_[1]"; EV::break },
    );
    EV::timer(30, 0, sub { EV::break });
    EV::run;
    report("Net::WebSocket::EVx (server)", \@lat);
}

# --- Mojolicious (forked) ---
sub bench_mojo {
    require Mojolicious;
    require Mojo::Server::Daemon;
    require Mojo::IOLoop;
    require Mojo::UserAgent;

    my $app = Mojolicious->new;
    $app->log->level('fatal');
    $app->routes->websocket('/ws')->to(cb => sub { $_[0]->on(message => sub { $_[0]->send($_[1]) }) });

    my $d = Mojo::Server::Daemon->new(app => $app, listen => ["http://127.0.0.1:0"], silent => 1);
    $d->start;
    my $port = $d->ports->[0];
    my @lat;
    my ($rounds, $st) = (0, 0);
    my $ua = Mojo::UserAgent->new;

    Mojo::IOLoop->next_tick(sub {
        $ua->websocket("ws://127.0.0.1:$port/ws" => sub {
            my (undef, $tx) = @_;
            return Mojo::IOLoop->stop unless $tx->is_websocket;
            $tx->on(message => sub {
                push @lat, (time() - $st) * 1e6; $rounds++;
                if ($rounds < $ROUNDS) { $st = time(); $_[0]->send($PAYLOAD) }
                else { $_[0]->finish; Mojo::IOLoop->stop }
            });
            $st = time(); $tx->send($PAYLOAD);
        });
    });
    Mojo::IOLoop->timer(30 => sub { Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    report("Mojolicious (client+server)", \@lat);
}

# --- Net::Async::WebSocket (forked) ---
sub bench_async {
    require Net::Async::WebSocket::Server;
    require Net::Async::WebSocket::Client;

    # Use UV backend if available, otherwise default
    my $loop;
    eval { require IO::Async::Loop::UV; $loop = IO::Async::Loop::UV->new };
    unless ($loop) { require IO::Async::Loop; $loop = IO::Async::Loop->new }
    my $srv = Net::Async::WebSocket::Server->new(
        on_client => sub {
            my (undef, $client) = @_;
            $client->configure(on_text_frame => sub { $_[0]->send_text_frame($_[1]) });
        },
    );
    $loop->add($srv);
    $srv->listen(addr => { family => "inet", socktype => "stream", port => 0, ip => "127.0.0.1" })->get;
    my $port = ($srv->read_handle->sockport);

    my @lat;
    my $client = Net::Async::WebSocket::Client->new(
        on_text_frame => sub {
            # handled below
        },
    );
    $loop->add($client);
    $client->connect(url => "ws://127.0.0.1:$port/")->get;

    my ($st, $n) = (0, 0);
    my $done = $loop->new_future;
    $client->configure(on_text_frame => sub {
        push @lat, (time() - $st) * 1e6; $n++;
        if ($n < $ROUNDS) { $st = time(); $_[0]->send_text_frame($PAYLOAD) }
        else { $done->done(1) }
    });
    $st = time();
    $client->send_text_frame($PAYLOAD);

    my $timeout = $loop->delay_future(after => 30)->then(sub { $done->done(0) });
    $done->get;
    report("Net::Async::WebSocket (client+server)", \@lat);
}

sub report {
    my ($name, $lat) = @_;
    return unless $lat && @$lat;
    my @s = sort { $a <=> $b } @$lat;
    my $sum = 0; $sum += $_ for @s;
    my $n = scalar @s;
    printf "%-45s %d round-trips\n", $name, $n;
    printf "  avg: %8.1f us   p50: %8.1f us   p99: %8.1f us\n",
        $sum / $n, $s[int($n * 0.5)], $s[int($n * 0.99)];
    printf "  min: %8.1f us   max: %8.1f us   throughput: %d msg/s\n",
        $s[0], $s[-1], int($n / ($sum / 1_000_000));
}
