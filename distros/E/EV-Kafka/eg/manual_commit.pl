#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# at-least-once processing: auto_commit=0, explicit commit after processing
$| = 1;

my $topic = $ENV{KAFKA_TOPIC} // 'test-topic';
my $batch_size = 10;
my $processed = 0;

my $kafka;
$kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    on_error   => sub { warn "kafka error: @_\n" },
    on_message => sub {
        my ($t, $p, $offset, $key, $value) = @_;
        # process the message
        print "processing: $t:$p offset=$offset key=$key\n";
        $processed++;

        # commit every $batch_size messages
        if ($processed % $batch_size == 0) {
            print "committing after $processed messages...\n";
            $kafka->commit(sub {
                my $err = shift;
                print $err ? "commit failed: $err\n" : "committed\n";
            });
        }
    },
);

$kafka->connect(sub {
    $kafka->subscribe($topic,
        group_id           => 'manual-commit-group',
        auto_commit        => 0,
        auto_offset_reset  => 'earliest',
        heartbeat_interval => 3,
        on_assign => sub {
            my $parts = shift;
            print "assigned " . scalar(@$parts) . " partitions\n";
        },
    );
});

$SIG{INT} = sub {
    print "\nfinal commit...\n";
    $kafka->commit(sub {
        $kafka->unsubscribe(sub {
            $kafka->close(sub { EV::break });
        });
    });
};

EV::run;
