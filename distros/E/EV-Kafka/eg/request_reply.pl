#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# request-reply pattern using headers for correlation
$| = 1;

my $request_topic = 'rpc-requests';
my $reply_topic   = 'rpc-replies';
my $request_id    = "req-$$-" . time;

my $kafka;
$kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    acks       => 1,
    on_error   => sub { warn "kafka error: @_\n" },
    on_message => sub {
        my ($t, $p, $offset, $key, $value, $headers) = @_;
        if ($t eq $reply_topic && $headers && ($headers->{'correlation-id'} // '') eq $request_id) {
            print "got reply: $value\n";
            $kafka->close(sub { EV::break });
        }
    },
);

$kafka->connect(sub {
    # start listening for replies first
    my $conn = $kafka->{cfg}{bootstrap_conn};
    $conn->list_offsets($reply_topic, 0, -1, sub {
        my ($res) = @_;
        my $latest = $res->{topics}[0]{partitions}[0]{offset} // 0;
        $kafka->assign([{ topic => $reply_topic, partition => 0, offset => $latest }]);

        my $poll; $poll = EV::timer 0, 0.1, sub { $kafka->poll };
        $kafka->{cfg}{_poll_timer} = $poll;

        # send request with correlation header
        print "sending request $request_id...\n";
        $kafka->produce($request_topic, 'rpc', '{"method":"getUser","id":42}', {
            headers => {
                'correlation-id' => $request_id,
                'reply-to'       => $reply_topic,
            },
        }, sub {
            print "request sent, waiting for reply...\n";

            # simulate a responder: produce a reply
            $kafka->produce($reply_topic, 'rpc', '{"result":"Alice"}', {
                headers => { 'correlation-id' => $request_id },
            });
        });
    });
});

my $t = EV::timer 10, 0, sub { print "timeout\n"; EV::break };
EV::run;
