#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use lib 'blib/lib', 'blib/arch';
$| = 1;  # Autoflush

use EV;
use EV::Etcd;

# Check if etcd is running
my $etcd_running = 0;
eval {
    my $result = `etcdctl endpoint health 2>&1`;
    $etcd_running = 1 if $result =~ /is healthy/;
};
die "etcd not running\n" unless $etcd_running;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my $prefix = "/bench_$$";
my $iterations = $ENV{BENCH_ITER} || 1000;

print "EV::Etcd Benchmark\n";
print "==================\n\n";

# Benchmark 1: Sequential puts
{
    print "1. Sequential PUTs ($iterations iterations)...\n";
    my $completed = 0;
    my $start = time();

    for my $i (1..$iterations) {
        $client->put("$prefix/key$i", "value$i", sub {
            my ($resp, $err) = @_;
            die "PUT error: $err->{message}" if $err;
            $completed++;
            EV::break;
        });
        EV::run;
    }

    my $elapsed = time() - $start;
    printf "   Time: %.3f sec, Rate: %.0f ops/sec, Latency: %.2f ms/op\n\n",
        $elapsed, $iterations / $elapsed, ($elapsed / $iterations) * 1000;
}

# Benchmark 2: Sequential gets
{
    print "2. Sequential GETs ($iterations iterations)...\n";
    my $completed = 0;
    my $start = time();

    for my $i (1..$iterations) {
        $client->get("$prefix/key$i", sub {
            my ($resp, $err) = @_;
            die "GET error: $err->{message}" if $err;
            $completed++;
            EV::break;
        });
        EV::run;
    }

    my $elapsed = time() - $start;
    printf "   Time: %.3f sec, Rate: %.0f ops/sec, Latency: %.2f ms/op\n\n",
        $elapsed, $iterations / $elapsed, ($elapsed / $iterations) * 1000;
}

# Benchmark 3: Pipelined puts (bounded concurrency)
{
    my $concurrency = $ENV{BENCH_CONCURRENCY} || 100;
    print "3. Pipelined PUTs ($iterations iterations, concurrency=$concurrency)...\n";
    my $completed = 0;
    my $sent = 0;
    my $in_flight = 0;
    my $start = time();

    my $send_batch; $send_batch = sub {
        while ($sent < $iterations && $in_flight < $concurrency) {
            $sent++;
            $in_flight++;
            my $i = $sent;
            $client->put("$prefix/pipe$i", "value$i", sub {
                my ($resp, $err) = @_;
                die "PUT error: $err->{message}" if $err;
                $completed++;
                $in_flight--;
                if ($completed == $iterations) {
                    EV::break;
                } else {
                    $send_batch->();
                }
            });
        }
    };
    $send_batch->();
    EV::run;

    my $elapsed = time() - $start;
    printf "   Time: %.3f sec, Rate: %.0f ops/sec, Latency: %.2f ms/op\n\n",
        $elapsed, $iterations / $elapsed, ($elapsed / $iterations) * 1000;
}

# Benchmark 4: Pipelined gets (bounded concurrency)
{
    my $concurrency = $ENV{BENCH_CONCURRENCY} || 100;
    print "4. Pipelined GETs ($iterations iterations, concurrency=$concurrency)...\n";
    my $completed = 0;
    my $sent = 0;
    my $in_flight = 0;
    my $start = time();

    my $send_batch; $send_batch = sub {
        while ($sent < $iterations && $in_flight < $concurrency) {
            $sent++;
            $in_flight++;
            my $i = $sent;
            $client->get("$prefix/pipe$i", sub {
                my ($resp, $err) = @_;
                die "GET error: $err->{message}" if $err;
                $completed++;
                $in_flight--;
                if ($completed == $iterations) {
                    EV::break;
                } else {
                    $send_batch->();
                }
            });
        }
    };
    $send_batch->();
    EV::run;

    my $elapsed = time() - $start;
    printf "   Time: %.3f sec, Rate: %.0f ops/sec, Latency: %.2f ms/op\n\n",
        $elapsed, $iterations / $elapsed, ($elapsed / $iterations) * 1000;
}

# Benchmark 5: Watch latency
{
    print "5. Watch event latency (100 events)...\n";
    my $watch_key = "$prefix/watch_test";
    my @latencies;
    my $events_received = 0;
    my $puts_sent = 0;
    my @send_times;
    my $watch_ready = 0;

    my $watch = $client->watch($watch_key, {}, sub {
        my ($resp, $err) = @_;
        return if $err;
        # Watch created response (no events) means watch is ready
        if (!$resp->{events} || @{$resp->{events}} == 0) {
            $watch_ready = 1;
            return;
        }
        for my $event (@{$resp->{events}}) {
            my $sent = shift @send_times;
            my $latency = (time() - $sent) * 1000;
            push @latencies, $latency;
            $events_received++;
        }
    });

    # Wait for watch to be established
    my $wait_start = time();
    while (!$watch_ready && (time() - $wait_start) < 2) {
        EV::run(EV::RUN_ONCE);
    }

    if (!$watch_ready) {
        print "   Warning: Watch setup timeout\n";
    }

    # Send 100 puts, measuring latency for each
    for my $i (1..100) {
        push @send_times, time();
        my $put_done = 0;
        $client->put($watch_key, "event$i", sub {
            $put_done = 1;
        });

        # Wait for put to complete and watch event to arrive
        my $iter_start = time();
        while (($events_received < $i || !$put_done) && (time() - $iter_start) < 1) {
            EV::run(EV::RUN_ONCE);
        }
    }

    if (@latencies) {
        my $sum = 0;
        $sum += $_ for @latencies;
        my $avg = $sum / @latencies;
        my @sorted = sort { $a <=> $b } @latencies;
        my $p50 = $sorted[int(@sorted * 0.5)];
        my $p99 = $sorted[int(@sorted * 0.99)];
        printf "   Events: %d, Avg: %.2f ms, P50: %.2f ms, P99: %.2f ms\n\n",
            scalar(@latencies), $avg, $p50, $p99;
    }

    $watch->cancel(sub {});
    EV::run(EV::RUN_ONCE);
}

# Cleanup
print "Cleaning up...\n";
$client->delete($prefix, { prefix => 1 }, sub {
    EV::break;
});
EV::run;

print "Done.\n";
