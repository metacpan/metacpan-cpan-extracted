#!/usr/bin/env perl
# Compressed batches.
#
# Produces a batch of records with the configured compression codec,
# then consumes them back and reports wire-side and uncompressed sizes.
# Set KAFKA_COMPRESS to 'lz4' (default) or 'gzip'.

use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

my $topic    = $ENV{KAFKA_TOPIC}    // 'compress-demo';
my $codec    = $ENV{KAFKA_COMPRESS} // 'lz4';
my $count    = $ENV{KAFKA_COUNT}    // 1000;
my $val_size = $ENV{KAFKA_VALUE}    // 200;

my $payload = 'a' x $val_size;

my $kafka = EV::Kafka->new(
    brokers     => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    acks        => -1,
    compression => $codec,
    linger_ms   => 50,            # accumulate before flush so the batch is large
    batch_size  => 1024 * 1024,
    on_error    => sub { warn "kafka: @_\n" },
);

$kafka->connect(sub {
    printf "producing %d x %d-byte records with %s compression\n",
        $count, $val_size, $codec;

    my $left = $count;
    for my $i (1..$count) {
        $kafka->produce($topic, "k$i", $payload, sub {
            return if --$left;
            $kafka->flush(sub {
                printf "flushed; uncompressed payload bytes: %d\n",
                    $count * $val_size;
                $kafka->close(sub { EV::break });
            });
        });
    }
});

EV::run;
