#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;
use Time::HiRes qw(time);

$| = 1;

my $CHUNK_SIZE  = 64 * 1024;
my $QUEUE_LIMIT = 256 * 1024;
my $TARGET_MSGS = 500;

my $ctx = EV::Websockets::Context->new();
my ($total_sent, $total_recv, $t0) = (0, 0, 0);

sub try_send {
    my ($c) = @_;
    while ($c->stash->{sent} < $TARGET_MSGS && $c->send_queue_size < $QUEUE_LIMIT) {
        $c->send("x" x $CHUNK_SIZE);
        $c->stash->{sent}++;
        $total_sent += $CHUNK_SIZE;
    }
}

my $port = $ctx->listen(
    port => 0,
    on_connect => sub {
        my ($c) = @_;
        print "Server: client connected, streaming $TARGET_MSGS chunks of ${\ ($CHUNK_SIZE/1024)}KB\n";
        $c->stash->{sent} = 0;
        $t0 = time;
        try_send($c);
    },
    on_drain => sub {
        my ($c) = @_;
        try_send($c);
    },
    on_close => sub {
        print "Server: client disconnected\n";
    },
    on_error => sub {
        my ($c, $err) = @_;
        warn "Server error: $err\n";
    },
    on_message => sub {},
);

print "Backpressure demo: server on port $port, connecting client...\n";

my $client = $ctx->connect(
    url => "ws://127.0.0.1:$port",
    on_connect => sub {
        print "Client: connected\n";
    },
    on_message => sub {
        my ($c, $data) = @_;
        $total_recv += length $data;
        my $msgs = ++$c->stash->{count};
        if ($msgs % 100 == 0) {
            printf "Client: %d/%d msgs, queue=%d bytes\n",
                $msgs, $TARGET_MSGS, $c->send_queue_size;
        }
        if ($msgs >= $TARGET_MSGS) {
            my $elapsed = time - $t0;
            printf "Done: %d msgs, %.1f MB sent in %.2fs (%.1f MB/s)\n",
                $msgs, $total_sent / 1e6, $elapsed,
                $elapsed > 0 ? $total_sent / 1e6 / $elapsed : 0;
            $c->close(1000, "complete");
        }
    },
    on_close => sub {
        print "Client: closed\n";
        EV::break;
    },
    on_error => sub {
        my ($c, $err) = @_;
        warn "Client error: $err\n";
        EV::break;
    },
);

EV::run;
