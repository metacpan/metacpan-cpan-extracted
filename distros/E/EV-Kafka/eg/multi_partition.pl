#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# produce to multiple partitions using key-based routing (murmur2)
$| = 1;

my $topic = $ENV{KAFKA_TOPIC} // 'multi-part-test';

my $kafka = EV::Kafka->new(
    brokers  => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    acks     => 1,
    on_error => sub { warn "kafka error: @_\n" },
);

$kafka->connect(sub {
    my $meta = shift;
    my $np = 0;
    for my $t (@{$meta->{topics} // []}) {
        $np = scalar @{$t->{partitions}} if $t->{name} eq $topic;
    }
    print "topic $topic has $np partition(s)\n";

    my $sent = 0;
    my $n = 20;
    for my $i (1..$n) {
        my $key = "user-$i";
        $kafka->produce($topic, $key, "event for $key", sub {
            my ($result, $err) = @_;
            die "produce: $err" if $err;
            my $p = $result->{topics}[0]{partitions}[0];
            printf "  key=%-10s -> partition %d  offset %d\n",
                $key, $p->{partition} // '?', $p->{base_offset};
            if (++$sent == $n) {
                $kafka->close(sub { EV::break });
            }
        });
    }
});

EV::run;
