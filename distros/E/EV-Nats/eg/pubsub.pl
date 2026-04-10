#!/usr/bin/env perl
# Basic pub/sub example
use strict;
use warnings;
use EV;
use EV::Nats;

my $nats;
$nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "error: @_\n" },
    on_connect => sub {
        print "connected\n";

        # subscribe to wildcard
        $nats->subscribe('demo.>', sub {
            my ($subject, $payload, $reply) = @_;
            print "[$subject] $payload\n";
        });

        # publish some messages
        my $n = 0;
        my $t; $t = EV::timer 0.5, 0.5, sub {
            $nats->publish('demo.greet', "hello #" . ++$n);
            $nats->publish('demo.time', scalar localtime);
            if ($n >= 5) {
                undef $t;
                $nats->disconnect;
                EV::break;
            }
        };
    },
);

EV::run;
