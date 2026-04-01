#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;

$| = 1;

my $listen_port  = $ARGV[0] || 9090;
my $upstream_url = $ARGV[1] || 'wss://ws.postman-echo.com/raw';
my $ctx = EV::Websockets::Context->new();

my $relayed  = 0;
my $sessions = 0;

my $actual_port = $ctx->listen(
    port => $listen_port,
    on_connect => sub {
        my ($client) = @_;
        $sessions++;
        print "[proxy] client connected (sessions=$sessions), connecting upstream...\n";

        my $upstream = $ctx->connect(
            url => $upstream_url,
            on_connect => sub {
                my ($u) = @_;
                print "[proxy] upstream connected\n";
                my $buf = delete $client->stash->{buffer} || [];
                for my $msg (@$buf) {
                    $msg->[1] ? $u->send_binary($msg->[0]) : $u->send($msg->[0]);
                }
            },
            on_message => sub {
                my ($u, $data, $is_binary) = @_;
                $relayed++;
                print "[upstream->client] ", length($data), " bytes (relayed=$relayed)\n";
                $is_binary ? $client->send_binary($data) : $client->send($data);
            },
            on_close => sub {
                print "[proxy] upstream closed, closing client\n";
                $client->close(1000, "upstream closed");
            },
            on_error => sub {
                my ($u, $err) = @_;
                warn "[proxy] upstream error: $err\n";
                $client->close(1011, "upstream error");
            },
        );

        $client->stash->{upstream} = $upstream;
    },
    on_message => sub {
        my ($client, $data, $is_binary) = @_;
        my $upstream = $client->stash->{upstream} // return;
        $relayed++;
        print "[client->upstream] ", length($data), " bytes (relayed=$relayed)\n";
        if ($upstream->is_connected) {
            $is_binary ? $upstream->send_binary($data) : $upstream->send($data);
        } else {
            push @{$client->stash->{buffer} ||= []}, [$data, $is_binary];
        }
    },
    on_close => sub {
        my ($client) = @_;
        $sessions--;
        print "[proxy] client disconnected (sessions=$sessions)\n";
        my $upstream = delete $client->stash->{upstream} // return;
        $upstream->close(1000, "client left");
    },
    on_error => sub {
        my ($c, $err) = @_;
        warn "[proxy] error: $err\n";
    },
);

print "WebSocket proxy on ws://127.0.0.1:$actual_port -> $upstream_url\n";
print "Usage: wscat -c ws://127.0.0.1:$actual_port\n";
EV::run;
