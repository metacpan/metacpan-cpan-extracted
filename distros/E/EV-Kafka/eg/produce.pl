#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

my $kafka = EV::Kafka->new(
    brokers  => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    acks     => 1,
    on_error => sub { warn "kafka error: @_\n" },
);

$kafka->connect(sub {
    print "connected to cluster\n";

    my $sent = 0;
    for my $i (1..10) {
        $kafka->produce('test-topic', "key-$i", "message number $i", sub {
            my ($result, $err) = @_;
            die "produce failed: $err" if $err;
            my $offset = $result->{topics}[0]{partitions}[0]{base_offset};
            print "  produced message $i at offset $offset\n";
            if (++$sent == 10) {
                print "all messages produced\n";
                $kafka->close(sub { EV::break });
            }
        });
    }
});

EV::run;
