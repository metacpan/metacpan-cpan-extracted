#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent;
use EV::Kafka;

# AnyEvent integration: EV is the backend, EV::Kafka works seamlessly
$| = 1;

my $cv = AE::cv;

my $kafka = EV::Kafka->new(
    brokers  => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    acks     => 1,
    on_error => sub { warn "kafka: @_\n" },
);

$kafka->connect(sub {
    print "connected via AnyEvent\n";

    $kafka->produce('ae-test', 'key', 'hello from AnyEvent', sub {
        my ($res, $err) = @_;
        die "produce: $err" if $err;
        print "produced at offset " . $res->{topics}[0]{partitions}[0]{base_offset} . "\n";
        $kafka->close(sub { $cv->send });
    });
});

$cv->recv;
print "done\n";
