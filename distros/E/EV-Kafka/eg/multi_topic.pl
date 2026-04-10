#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# subscribe to multiple topics in one consumer group
$| = 1;

my $kafka;
$kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    on_error   => sub { warn "kafka error: @_\n" },
    on_message => sub {
        my ($topic, $partition, $offset, $key, $value) = @_;
        printf "[%s:%d] @%d  %s\n", $topic, $partition, $offset, $value // '-';
    },
);

$kafka->connect(sub {
    # first produce some test messages to different topics
    my $sent = 0;
    for my $topic (qw(orders payments notifications)) {
        for my $i (1..3) {
            $kafka->produce($topic, "key-$i", "$topic event $i", sub {
                if (++$sent == 9) {
                    print "produced to 3 topics, subscribing...\n";
                    $kafka->subscribe(
                        'orders', 'payments', 'notifications',
                        group_id          => 'multi-topic-group',
                        auto_offset_reset => 'earliest',
                        on_assign         => sub {
                            my $parts = shift;
                            printf "assigned %d partitions across %d topics\n",
                                scalar @$parts,
                                scalar keys %{{ map { $_->{topic} => 1 } @$parts }};
                        },
                    );
                }
            });
        }
    }
});

$SIG{INT} = sub { $kafka->unsubscribe(sub { $kafka->close(sub { EV::break }) }) };
EV::run;
