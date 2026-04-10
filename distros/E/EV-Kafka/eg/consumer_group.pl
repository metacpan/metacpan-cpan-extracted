#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

my $topic    = $ENV{KAFKA_TOPIC}    // 'test-topic';
my $group_id = $ENV{KAFKA_GROUP_ID} // 'my-consumer-group';

my $kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    on_error   => sub { warn "kafka error: @_\n" },
    on_message => sub {
        my ($t, $p, $offset, $key, $value, $headers) = @_;
        printf "[%s:%d] offset=%d key=%s value=%s\n",
            $t, $p, $offset, $key // 'null', $value // 'null';
    },
);

my $running = 1;
$SIG{INT} = sub {
    print "\ncaught SIGINT, shutting down...\n";
    $running = 0;
    $kafka->commit(sub {
        $kafka->unsubscribe;
        $kafka->close(sub { EV::break });
    });
};

$kafka->connect(sub {
    print "connected, subscribing to $topic as group $group_id\n";

    $kafka->subscribe($topic,
        group_id           => $group_id,
        session_timeout    => 30000,
        rebalance_timeout  => 60000,
        heartbeat_interval => 3,
        on_assign => sub {
            my $parts = shift;
            print "assigned partitions:\n";
            for my $p (@$parts) {
                printf "  %s:%d from offset %d\n",
                    $p->{topic}, $p->{partition}, $p->{offset};
            }
        },
        on_revoke => sub {
            my $parts = shift;
            print "partitions revoked\n";
        },
    );
});

EV::run;
