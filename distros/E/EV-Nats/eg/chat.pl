#!/usr/bin/env perl
# Chat room — multiple users on named channels
# Usage: perl eg/chat.pl <username> [channel]
# Run multiple instances to chat between them
use strict;
use warnings;
use EV;
use EV::Nats;

my $user    = shift || "user$$";
my $channel = shift || 'general';

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: @_\n" },
    on_connect => sub {
        print "[$user] joined #$channel\n";

        # Subscribe to channel
        $nats->subscribe("chat.$channel", sub {
            my ($subj, $payload) = @_;
            print "$payload\n" unless $payload =~ /^\[$user\]/;
        });

        # Announce join
        $nats->publish("chat.$channel", "[$user] joined");
    },
);

# Read stdin lines and publish
my $stdin; $stdin = EV::io *STDIN, EV::READ, sub {
    my $line = <STDIN>;
    unless (defined $line) {
        $nats->publish("chat.$channel", "[$user] left");
        $nats->drain(sub { EV::break });
        undef $stdin;
        return;
    }
    chomp $line;
    $nats->publish("chat.$channel", "[$user] $line") if length $line;
};

EV::run;
