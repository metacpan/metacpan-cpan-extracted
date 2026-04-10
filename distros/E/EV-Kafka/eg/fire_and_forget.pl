#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# acks=0 produce: no broker acknowledgment, maximum throughput
$| = 1;

my $n = $ENV{KAFKA_COUNT} // 100_000;

my $kafka = EV::Kafka->new(
    brokers  => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    acks     => 0,
    on_error => sub { warn "kafka error: @_\n" },
);

$kafka->connect(sub {
    print "connected, producing $n messages with acks=0...\n";
    my $start = time;

    for my $i (1..$n) {
        $kafka->produce('bench-topic', "k$i", "payload-$i");
    }

    # fence: one acks=1 produce to confirm all prior messages are sent
    $kafka->produce('bench-topic', 'fence', 'done', { acks => 1 }, sub {
        my $elapsed = time - $start;
        printf "sent %d messages in %.3fs (%.0f msg/sec)\n",
            $n, $elapsed, $n / ($elapsed || 0.001);
        $kafka->close(sub { EV::break });
    });
});

EV::run;
