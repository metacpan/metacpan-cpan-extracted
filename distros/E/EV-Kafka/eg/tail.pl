#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# kafka tail: consume from latest offset (like tail -f)
$| = 1;

my $topic = $ENV{KAFKA_TOPIC} // 'test-topic';

my $kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    on_error   => sub { warn "kafka error: @_\n" },
    on_message => sub {
        my ($t, $p, $offset, $key, $value) = @_;
        printf "%s:%d @%d  %s = %s\n",
            $t, $p, $offset, $key // '-', $value // '-';
    },
);

$kafka->connect(sub {
    # resolve latest offset first via low-level conn
    my $conn = $kafka->{cfg}{bootstrap_conn};
    $conn->list_offsets($topic, 0, -1, sub { # -1 = latest
        my ($res, $err) = @_;
        my $latest = $res->{topics}[0]{partitions}[0]{offset} // 0;
        print "tailing $topic:0 from offset $latest...\n";

        $kafka->assign([{ topic => $topic, partition => 0, offset => $latest }]);
        my $poll; $poll = EV::timer 0, 0.1, sub { $kafka->poll };
        $kafka->{cfg}{_poll_timer} = $poll;
    });
});

$SIG{INT} = sub { $kafka->close(sub { EV::break }) };

EV::run;
