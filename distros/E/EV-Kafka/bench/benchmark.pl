#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
$| = 1;
use EV;
use EV::Kafka;

my $broker     = $ENV{BENCH_BROKER}     // '127.0.0.1:9092';
my $num_msgs   = $ENV{BENCH_MESSAGES}   // 10000;
my $value_size = $ENV{BENCH_VALUE_SIZE} // 100;
my $topic      = $ENV{BENCH_TOPIC}      // 'ev-kafka-bench';

my $value = 'x' x $value_size;

print "=" x 60, "\n";
print "EV::Kafka Benchmark\n";
print "=" x 60, "\n";
print "Broker: $broker\n";
print "Messages per test: $num_msgs\n";
print "Value size: $value_size bytes\n";
print "Topic: $topic\n";
print "=" x 60, "\n\n";

sub format_rate {
    my ($count, $elapsed) = @_;
    my $rate = $count / ($elapsed || 0.001);
    if ($rate >= 1_000_000) {
        return sprintf("%.2fM msg/sec", $rate / 1_000_000);
    } elsif ($rate >= 1_000) {
        return sprintf("%.1fK msg/sec", $rate / 1_000);
    } else {
        return sprintf("%.0f msg/sec", $rate);
    }
}

sub format_time {
    my ($seconds) = @_;
    if ($seconds < 0.001) {
        return sprintf("%.1f us", $seconds * 1_000_000);
    } elsif ($seconds < 1) {
        return sprintf("%.2f ms", $seconds * 1_000);
    } else {
        return sprintf("%.3f s", $seconds);
    }
}

sub format_bytes {
    my ($bytes) = @_;
    if ($bytes >= 1_000_000_000) {
        return sprintf("%.2f GB/s", $bytes / 1_000_000_000);
    } elsif ($bytes >= 1_000_000) {
        return sprintf("%.1f MB/s", $bytes / 1_000_000);
    } else {
        return sprintf("%.1f KB/s", $bytes / 1_000);
    }
}

sub create_conn {
    my ($host, $port) = split /:/, $broker;
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->on_error(sub { die "error: @_\n" });
    $conn->on_connect(sub { EV::break });
    $conn->connect($host, $port + 0, 10.0);
    my $t = EV::timer 10, 0, sub { die "connect timeout" };
    EV::run;
    $conn->on_connect(undef);
    return $conn;
}

sub ensure_topic {
    my ($conn) = @_;
    $conn->metadata([$topic], sub { EV::break });
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;
    # wait for topic creation
    my $t2 = EV::timer 1, 0, sub { EV::break };
    EV::run;
}

# --- 1. Pipeline produce (acks=1) ---
{
    print "1. Pipeline produce (acks=1, with callbacks)\n";
    print "-" x 50, "\n";

    my $conn = create_conn();
    ensure_topic($conn);
    my $completed = 0;
    my $start = time();

    for my $i (1 .. $num_msgs) {
        $conn->produce($topic, 0, "k$i", $value, sub {
            my ($res, $err) = @_;
            die "produce failed: $err" if $err;
            if (++$completed == $num_msgs) {
                $conn->disconnect;
            }
        });
    }

    EV::run;
    my $elapsed = time() - $start;
    my $bytes = $num_msgs * ($value_size + 10); # approx key+value

    printf "  %d messages in %s  %s  %s\n",
        $completed, format_time($elapsed), format_rate($completed, $elapsed),
        format_bytes($bytes / $elapsed);
    print "\n";
}

# --- 2. Pipeline produce (acks=0, fire-and-forget) ---
{
    print "2. Pipeline produce (acks=0, fire-and-forget)\n";
    print "-" x 50, "\n";

    my $conn = create_conn();
    my $start = time();

    for my $i (1 .. $num_msgs) {
        $conn->produce($topic, 0, "k$i", $value, { acks => 0 });
    }

    # acks=0 means no response — send one acks=1 produce as fence
    $conn->produce($topic, 0, 'fence', 'x', sub {
        $conn->disconnect;
    });

    EV::run;
    my $elapsed = time() - $start;
    my $bytes = $num_msgs * ($value_size + 10);

    printf "  %d messages in %s  %s  %s\n",
        $num_msgs, format_time($elapsed), format_rate($num_msgs, $elapsed),
        format_bytes($bytes / $elapsed);
    print "\n";
}

# --- 3. Fetch throughput ---
{
    print "3. Fetch throughput (consume all messages)\n";
    print "-" x 50, "\n";

    my $conn = create_conn();

    # find latest offset to know how many to fetch
    my $earliest;
    $conn->list_offsets($topic, 0, -2, sub {
        my ($res, $err) = @_;
        $earliest = $res->{topics}[0]{partitions}[0]{offset} // 0;
        EV::break;
    });
    my $t1 = EV::timer 5, 0, sub { EV::break };
    EV::run;

    my $latest;
    $conn->list_offsets($topic, 0, -1, sub {
        my ($res, $err) = @_;
        $latest = $res->{topics}[0]{partitions}[0]{offset} // 0;
        EV::break;
    });
    my $t2 = EV::timer 5, 0, sub { EV::break };
    EV::run;

    my $total = $latest - $earliest;
    printf "  range: offset %d..%d (%d messages)\n", $earliest, $latest, $total;

    my $fetched = 0;
    my $start = time();
    my $offset = $earliest;

    my $do_fetch; $do_fetch = sub {
        $conn->fetch($topic, 0, $offset, sub {
            my ($res, $err) = @_;
            die "fetch failed: $err" if $err;
            my $records = $res->{topics}[0]{partitions}[0]{records} // [];
            $fetched += scalar @$records;
            if (@$records) {
                $offset = $records->[-1]{offset} + 1;
            }
            if ($fetched >= $total || !@$records) {
                $conn->disconnect;
                return;
            }
            $do_fetch->();
        });
    };
    $do_fetch->();

    EV::run;
    my $elapsed = time() - $start;
    my $bytes = $fetched * ($value_size + 10);

    printf "  %d messages in %s  %s  %s\n",
        $fetched, format_time($elapsed), format_rate($fetched, $elapsed),
        format_bytes($bytes / $elapsed);
    print "\n";
}

# --- 4. Produce latency (sequential round-trip) ---
{
    print "4. Sequential round-trip produce (acks=1)\n";
    print "-" x 50, "\n";

    my $conn = create_conn();
    my $completed = 0;
    my $n = $num_msgs > 1000 ? 1000 : $num_msgs;
    my $start = time();

    my $do_produce; $do_produce = sub {
        $conn->produce($topic, 0, "seq-$completed", $value, sub {
            my ($res, $err) = @_;
            die "produce failed: $err" if $err;
            if (++$completed >= $n) {
                $conn->disconnect;
                return;
            }
            $do_produce->();
        });
    };
    $do_produce->();

    EV::run;
    my $elapsed = time() - $start;
    my $avg_latency = $elapsed / $completed;

    printf "  %d round-trips in %s  %s  avg latency %s\n",
        $completed, format_time($elapsed), format_rate($completed, $elapsed),
        format_time($avg_latency);
    print "\n";
}

# --- 5. Produce with varying value sizes ---
{
    print "5. Produce throughput by value size (acks=1, pipelined)\n";
    print "-" x 50, "\n";

    for my $sz (10, 100, 1000, 10000) {
        my $conn = create_conn();
        my $val = 'x' x $sz;
        my $n = $num_msgs > 10000 ? 10000 : $num_msgs;
        my $completed = 0;
        my $start = time();

        for my $i (1..$n) {
            $conn->produce($topic, 0, "sz$i", $val, sub {
                if (++$completed == $n) { $conn->disconnect }
            });
        }

        EV::run;
        my $elapsed = time() - $start;
        my $bytes = $n * ($sz + 5);

        printf "  %5d bytes: %s  %s\n",
            $sz, format_rate($n, $elapsed), format_bytes($bytes / $elapsed);
    }
    print "\n";
}

# --- 6. Metadata latency ---
{
    print "6. Metadata request latency\n";
    print "-" x 50, "\n";

    my $conn = create_conn();
    my $n = 100;
    my $completed = 0;
    my $start = time();

    my $do_meta; $do_meta = sub {
        $conn->metadata(undef, sub {
            if (++$completed >= $n) {
                $conn->disconnect;
                return;
            }
            $do_meta->();
        });
    };
    $do_meta->();

    EV::run;
    my $elapsed = time() - $start;

    printf "  %d requests in %s  avg %s/req\n",
        $completed, format_time($elapsed), format_time($elapsed / $completed);
    print "\n";
}

print "=" x 60, "\n";
print "Done.\n";
