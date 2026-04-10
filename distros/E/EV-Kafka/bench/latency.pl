#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
$| = 1;
use EV;
use EV::Kafka;

my $broker     = $ENV{BENCH_BROKER}     // '127.0.0.1:9092';
my $num_msgs   = $ENV{BENCH_MESSAGES}   // 1000;
my $value_size = $ENV{BENCH_VALUE_SIZE} // 100;
my $topic      = $ENV{BENCH_TOPIC}      // 'ev-kafka-latency';

my $value = 'x' x $value_size;
my ($host, $port) = split /:/, $broker;

print "=" x 60, "\n";
print "EV::Kafka Latency Histogram\n";
print "=" x 60, "\n";
print "Broker: $broker\n";
print "Messages: $num_msgs\n";
print "Value size: $value_size bytes\n";
print "=" x 60, "\n\n";

my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
$conn->on_error(sub { die "error: @_\n" });
$conn->on_connect(sub { EV::break });
$conn->connect($host, $port + 0, 10.0);
my $t = EV::timer 10, 0, sub { die "connect timeout" };
EV::run;
$conn->on_connect(undef);

# ensure topic
$conn->metadata([$topic], sub { EV::break });
$t = EV::timer 5, 0, sub { EV::break };
EV::run;
$t = EV::timer 1, 0, sub { EV::break };
EV::run;

# --- sequential produce latency ---
{
    print "Sequential produce latency (acks=1)\n";
    print "-" x 50, "\n";

    my @latencies;
    my $completed = 0;

    my $do_produce; $do_produce = sub {
        my $start = time();
        $conn->produce($topic, 0, "lat-$completed", $value, sub {
            my $elapsed = time() - $start;
            push @latencies, $elapsed;
            if (++$completed >= $num_msgs) {
                $conn->disconnect;
                return;
            }
            $do_produce->();
        });
    };
    $do_produce->();

    EV::run;

    @latencies = sort { $a <=> $b } @latencies;
    my $n = scalar @latencies;

    my $sum = 0; $sum += $_ for @latencies;
    my $avg = $sum / $n;

    printf "  count:  %d\n", $n;
    printf "  min:    %.1f us\n", $latencies[0] * 1e6;
    printf "  avg:    %.1f us\n", $avg * 1e6;
    printf "  median: %.1f us\n", $latencies[int($n * 0.5)] * 1e6;
    printf "  p90:    %.1f us\n", $latencies[int($n * 0.9)] * 1e6;
    printf "  p95:    %.1f us\n", $latencies[int($n * 0.95)] * 1e6;
    printf "  p99:    %.1f us\n", $latencies[int($n * 0.99)] * 1e6;
    printf "  max:    %.1f us\n", $latencies[-1] * 1e6;

    print "\n  histogram:\n";
    my @buckets = (25, 50, 100, 200, 500, 1000, 2000, 5000, 10000);
    my $prev = 0;
    for my $b (@buckets) {
        my $count = grep { $_ * 1e6 >= $prev && $_ * 1e6 < $b } @latencies;
        my $pct = $count / $n * 100;
        my $bar = '#' x int($pct / 2);
        printf "    %5d-%5d us: %5d (%5.1f%%) %s\n", $prev, $b, $count, $pct, $bar
            if $count;
        $prev = $b;
    }
    my $over = grep { $_ * 1e6 >= $buckets[-1] } @latencies;
    printf "    %5d+    us: %5d (%5.1f%%)\n", $buckets[-1], $over, $over / $n * 100
        if $over;
}

print "\n";
print "=" x 60, "\n";
print "Done.\n";
