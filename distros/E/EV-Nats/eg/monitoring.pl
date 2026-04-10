#!/usr/bin/env perl
# Monitoring example: stats, slow consumer, lame duck mode
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
    },
    on_disconnect => sub {
        print "disconnected\n";
    },

    # Slow consumer: warn when write buffer exceeds 1MB
    slow_consumer_bytes => 1024 * 1024,
    on_slow_consumer    => sub {
        my ($pending_bytes) = @_;
        warn sprintf "SLOW CONSUMER: %d bytes pending\n", $pending_bytes;
    },

    # Lame duck mode: server is shutting down
    on_lame_duck => sub {
        warn "SERVER ENTERING LAME DUCK MODE - migrate connections\n";
    },

    # Reconnect with exponential backoff
    reconnect              => 1,
    reconnect_delay        => 1000,    # start at 1s
    max_reconnect_delay    => 30000,   # cap at 30s
    max_reconnect_attempts => 0,       # unlimited
);

# Periodic stats report
my $stats_timer; $stats_timer = EV::timer 5, 5, sub {
    return unless $nats->is_connected;
    my %s = $nats->stats;
    printf "stats: msgs_in=%d msgs_out=%d bytes_in=%d bytes_out=%d subs=%d\n",
        $s{msgs_in}, $s{msgs_out}, $s{bytes_in}, $s{bytes_out},
        $nats->subscription_count;
};

# Subscribe and publish to generate traffic
my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    $nats->subscribe('monitor.>', sub {});

    my $n = 0;
    my $pub; $pub = EV::timer 0.1, 0.1, sub {
        $nats->batch(sub {
            $nats->publish("monitor.tick", "msg-" . ++$n) for 1..100;
        });
        if ($n >= 1000) {
            undef $pub;
            my %s = $nats->stats;
            printf "\nfinal: %d msgs sent, %d received\n", $s{msgs_out}, $s{msgs_in};
            $nats->drain(sub {
                print "drained\n";
                EV::break;
            });
        }
    };
};

EV::run;
