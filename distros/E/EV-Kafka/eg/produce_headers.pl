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
    $kafka->produce('test-topic', 'event-key', '{"action":"click","page":"/home"}',
        {
            headers => {
                'content-type' => 'application/json',
                'trace-id'     => 'abc-123-def',
                'source'       => 'web-frontend',
            },
        },
        sub {
            my ($result, $err) = @_;
            die "produce failed: $err" if $err;
            print "produced with headers at offset "
                . $result->{topics}[0]{partitions}[0]{base_offset} . "\n";
            $kafka->close(sub { EV::break });
        },
    );
});

EV::run;
