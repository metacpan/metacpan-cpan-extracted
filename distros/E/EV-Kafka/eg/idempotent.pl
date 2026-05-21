#!/usr/bin/env perl
# Idempotent producer.
#
# With idempotent => 1, EV::Kafka calls InitProducerId on connect and
# attaches producer_id / producer_epoch / sequence to every batch. The
# broker deduplicates retries so a network blip cannot result in
# duplicate writes. Only one batch per (topic, partition) is in-flight
# at a time, which trades a bit of throughput for the guarantee.

use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

my $topic = $ENV{KAFKA_TOPIC} // 'idempotent-demo';
my $count = $ENV{KAFKA_COUNT} // 100;

my $kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    idempotent => 1,
    acks       => -1,                  # required for idempotence
    on_error   => sub { warn "kafka: @_\n" },
);

$kafka->connect(sub {
    print "connected; producer_id assigned, beginning produce\n";

    my $produced = 0;
    my $errors   = 0;
    for my $i (1..$count) {
        $kafka->produce($topic, "k$i", "payload $i", sub {
            my ($r, $err) = @_;
            $errors++ if $err;
            if (++$produced == $count) {
                printf "done: %d produced, %d errors\n", $produced, $errors;
                $kafka->close(sub { EV::break });
            }
        });
    }
});

EV::run;
