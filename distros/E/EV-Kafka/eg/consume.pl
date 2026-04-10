#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

my $topic = $ENV{KAFKA_TOPIC} // 'test-topic';
my $count = 0;
my $limit = $ENV{KAFKA_LIMIT} // 0; # 0 = unlimited

my $done = 0;
my $kafka;
$kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    on_error   => sub { warn "kafka error: @_\n" },
    on_message => sub {
        return if $done;
        my ($t, $p, $offset, $key, $value, $headers) = @_;
        printf "[%s:%d] offset=%d key=%s value=%s\n",
            $t, $p, $offset, $key // 'null', $value // 'null';
        if ($limit && ++$count >= $limit) {
            $done = 1;
            print "reached limit ($limit messages)\n";
            $kafka->close(sub { EV::break });
        }
    },
);

$kafka->connect(sub {
    print "connected, resolving earliest offset for $topic:0...\n";
    my $conn = $kafka->{cfg}{bootstrap_conn};
    $conn->list_offsets($topic, 0, -2, sub {
        my ($res, $err) = @_;
        my $earliest = $res->{topics}[0]{partitions}[0]{offset} // 0;
        print "consuming from offset $earliest\n";
        $kafka->assign([{ topic => $topic, partition => 0, offset => $earliest }]);

        my $poll; $poll = EV::timer 0, 0.1, sub { $kafka->poll };
        $kafka->{cfg}{_poll_timer} = $poll;
    });
});

EV::run;
