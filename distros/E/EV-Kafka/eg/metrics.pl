#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Kafka;

# periodic metrics dump: message rate, consumer lag, pending requests
$| = 1;

my $topic = $ENV{KAFKA_TOPIC} // 'test-topic';
my $msg_count = 0;
my $last_count = 0;
my $last_time = time;

my $kafka;
$kafka = EV::Kafka->new(
    brokers    => $ENV{KAFKA_BROKER} // '127.0.0.1:9092',
    on_error   => sub { warn "kafka: @_\n" },
    on_message => sub { $msg_count++ },
);

$kafka->connect(sub {
    print "connected, subscribing to $topic...\n";

    $kafka->subscribe($topic,
        group_id          => 'metrics-demo',
        auto_offset_reset => 'latest',
        on_assign => sub {
            my $parts = shift;
            print "assigned " . scalar(@$parts) . " partitions\n";
        },
    );

    # periodic metrics every 5 seconds
    my $stats; $stats = EV::timer 5, 5, sub {
        my $now = time;
        my $elapsed = $now - $last_time;
        my $delta = $msg_count - $last_count;
        my $rate = $elapsed > 0 ? $delta / $elapsed : 0;

        printf "[%s] messages: %d  rate: %.1f msg/sec",
            scalar localtime($now), $msg_count, $rate;

        # get lag
        $kafka->lag(sub {
            my $lag_info = shift;
            my $total_lag = 0;
            for my $key (sort keys %$lag_info) {
                $total_lag += $lag_info->{$key}{lag};
            }
            printf "  lag: %d\n", $total_lag;
        });

        $last_count = $msg_count;
        $last_time = $now;
    };
    $kafka->{cfg}{_stats_timer} = $stats;
});

$SIG{INT} = sub {
    $kafka->unsubscribe(sub { $kafka->close(sub { EV::break }) });
};

EV::run;
