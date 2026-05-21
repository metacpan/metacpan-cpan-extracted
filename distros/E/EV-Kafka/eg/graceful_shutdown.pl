#!/usr/bin/env perl
# Graceful shutdown for a long-running consumer.
#
# On SIGINT/SIGTERM:
#   1. stop accepting new work (via $running flag)
#   2. let in-flight on_message handlers finish
#   3. commit current offsets to the group coordinator
#   4. leave the group (sends LeaveGroup so the next member rebalances fast)
#   5. close all broker connections
#   6. break out of the EV loop

use strict;
use warnings;
use EV;
use EV::Kafka;

$| = 1;

my $topic    = $ENV{KAFKA_TOPIC}    // 'shutdown-demo';
my $group    = $ENV{KAFKA_GROUP_ID} // 'shutdown-demo-group';

my $running = 1;
my $in_flight = 0;
my $processed = 0;

my $kafka = EV::Kafka->new(
    brokers => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    on_error => sub { warn "kafka: @_\n" },
    on_message => sub {
        my ($t, $p, $off, $k, $v) = @_;
        return unless $running;
        $in_flight++;
        # ... do work here ...
        $processed++;
        $in_flight--;
    },
);

my $shutdown = sub {
    return unless $running;
    $running = 0;
    print "\nshutting down (processed=$processed, in_flight=$in_flight)\n";

    # Wait for in-flight handlers, then commit + leave.
    my $w; $w = EV::timer 0, 0.05, sub {
        return if $in_flight > 0;
        undef $w;
        $kafka->commit(sub {
            print "offsets committed\n";
            $kafka->unsubscribe(sub {
                print "left group, closing\n";
                $kafka->close(sub { EV::break });
            });
        });
    };
};
$SIG{INT}  = $shutdown;
$SIG{TERM} = $shutdown;

$kafka->connect(sub {
    print "subscribing to $topic as $group; press ^C to exit cleanly\n";
    $kafka->subscribe($topic,
        group_id    => $group,
        auto_commit => 0,    # we commit manually on shutdown
    );
});

EV::run;
