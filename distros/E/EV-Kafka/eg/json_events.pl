#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;
use JSON::PP ();

# produce and consume JSON-encoded events
$| = 1;

my $json  = JSON::PP->new->utf8->canonical;
my $topic = 'json-events';

my $kafka;
$kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    acks       => 1,
    on_error   => sub { warn "kafka error: @_\n" },
    on_message => sub {
        my ($t, $p, $offset, $key, $value) = @_;
        my $event = eval { $json->decode($value) };
        if ($event) {
            printf "  consumed: type=%s user=%s ts=%s\n",
                $event->{type}, $event->{user_id}, $event->{timestamp};
        }
    },
);

$kafka->connect(sub {
    print "producing JSON events...\n";
    my @events = (
        { type => 'login',    user_id => 'alice', timestamp => time },
        { type => 'purchase', user_id => 'bob',   timestamp => time, amount => 42.50 },
        { type => 'logout',   user_id => 'alice', timestamp => time },
    );

    my $sent = 0;
    for my $evt (@events) {
        my $key   = $evt->{user_id};
        my $value = $json->encode($evt);
        $kafka->produce($topic, $key, $value, sub {
            if (++$sent == scalar @events) {
                print "\nconsuming them back...\n";
                my $conn = $kafka->{cfg}{bootstrap_conn};
                $conn->list_offsets($topic, 0, -2, sub {
                    my ($res) = @_;
                    my $off = $res->{topics}[0]{partitions}[0]{offset} // 0;
                    $kafka->assign([{ topic => $topic, partition => 0, offset => $off }]);
                    my $done = 0;
                    my $poll; $poll = EV::timer 0, 0.1, sub {
                        $kafka->poll(sub {
                            return if $done++;
                            undef $poll;
                            $kafka->close(sub { EV::break });
                        });
                    };
                    $kafka->{cfg}{_poll_timer} = $poll;
                });
            }
        });
    }
});

EV::run;
