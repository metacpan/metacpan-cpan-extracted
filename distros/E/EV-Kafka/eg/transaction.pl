#!/usr/bin/env perl
# Exactly-once stream processing (consume → transform → produce).
#
# Reads from KAFKA_INPUT, transforms (uppercases) the value, and writes
# to KAFKA_OUTPUT under a transaction. The consumer offsets for the
# input topic are committed inside the same transaction via
# send_offsets_to_transaction so the read-process-write step is atomic
# from the broker's perspective.

use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

my $input  = $ENV{KAFKA_INPUT}  // 'eos-input';
my $output = $ENV{KAFKA_OUTPUT} // 'eos-output';
my $group  = $ENV{KAFKA_GROUP}  // 'eos-demo';
my $txn_id = $ENV{KAFKA_TXN_ID} // 'eos-demo-tx';

my $batch = [];

my $kafka = EV::Kafka->new(
    brokers          => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    transactional_id => $txn_id,
    acks             => -1,
    on_error => sub { warn "kafka: @_\n" },
    on_message => sub {
        my ($t, $p, $off, $k, $v) = @_;
        push @$batch, { topic => $t, partition => $p, offset => $off,
                        key => $k, value => uc($v // '') };
    },
);

$SIG{INT} = sub {
    print "\nshutting down...\n";
    $kafka->abort_transaction(sub { $kafka->close(sub { EV::break }) });
};

$kafka->connect(sub {
    $kafka->subscribe($input, group_id => $group, auto_commit => 0);

    # Drive the consume-process-produce loop.
    my $tick; $tick = EV::timer 0, 1, sub {
        return unless @$batch;

        $kafka->begin_transaction;
        for my $msg (@$batch) {
            $kafka->produce($output, $msg->{key}, $msg->{value});
        }
        my @processed = @$batch;
        $batch = [];

        $kafka->send_offsets_to_transaction($group, sub {
            $kafka->commit_transaction(sub {
                printf "committed transaction with %d records\n",
                    scalar @processed;
            });
        });
    };
    # keep ref alive
    $kafka->{_eos_tick} = $tick;

    $kafka->poll;  # kick the fetch loop
});

EV::run;
