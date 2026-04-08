#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
$| = 1;
use EV;
use EV::Memcached;

# Configuration
my $host          = $ENV{BENCH_HOST}        // '127.0.0.1';
my $port          = $ENV{BENCH_PORT}        // 11211;
my $num_commands  = $ENV{BENCH_COMMANDS}    // 10000;
my $value_size    = $ENV{BENCH_VALUE_SIZE}  // 100;
my $mget_batch    = $ENV{BENCH_MGET_BATCH}  // 100;

my $value = 'x' x $value_size;

print "=" x 60, "\n";
print "EV::Memcached Benchmark\n";
print "=" x 60, "\n";
print "Server: $host:$port\n";
print "Commands per test: $num_commands\n";
print "Value size: $value_size bytes\n";
print "Mget batch size: $mget_batch\n";
print "=" x 60, "\n\n";

sub format_rate {
    my ($count, $elapsed) = @_;
    my $rate = $count / $elapsed;
    if ($rate >= 1_000_000) {
        return sprintf("%.2fM ops/sec", $rate / 1_000_000);
    } elsif ($rate >= 1_000) {
        return sprintf("%.1fK ops/sec", $rate / 1_000);
    } else {
        return sprintf("%.0f ops/sec", $rate);
    }
}

sub format_time {
    my ($seconds) = @_;
    if ($seconds < 0.001) {
        return sprintf("%.1f us", $seconds * 1_000_000);
    } elsif ($seconds < 1) {
        return sprintf("%.2f ms", $seconds * 1_000);
    } else {
        return sprintf("%.2f s", $seconds);
    }
}

sub create_client {
    my %opts = @_;
    my $mc = EV::Memcached->new(
        host     => $host,
        port     => $port,
        on_error => sub { die "memcached error: @_" },
        %opts,
    );

    # Wait for connect
    $mc->on_connect(sub { EV::break });
    my $t = EV::timer 5, 0, sub { die "connect timeout" };
    EV::run;
    $mc->on_connect(undef);

    return $mc;
}

# --- 1. Pipeline SET ---
{
    print "1. Pipeline SET (with callbacks)\n";
    print "-" x 40, "\n";

    my $mc = create_client();
    my $completed = 0;
    my $start = time();

    for my $i (1 .. $num_commands) {
        $mc->set("bench:$i", $value, sub {
            my ($res, $err) = @_;
            die "SET failed: $err" if $err;
            if (++$completed == $num_commands) {
                $mc->disconnect;
            }
        });
    }

    EV::run;
    my $elapsed = time() - $start;

    printf "  %d commands in %s  %s\n",
        $completed, format_time($elapsed), format_rate($completed, $elapsed);
    print "\n";
}

# --- 2. Pipeline GET ---
{
    print "2. Pipeline GET (with callbacks)\n";
    print "-" x 40, "\n";

    my $mc = create_client();
    my $completed = 0;
    my $start = time();

    for my $i (1 .. $num_commands) {
        $mc->get("bench:$i", sub {
            my ($val, $err) = @_;
            die "GET failed: $err" if $err;
            if (++$completed == $num_commands) {
                $mc->disconnect;
            }
        });
    }

    EV::run;
    my $elapsed = time() - $start;

    printf "  %d commands in %s  %s\n",
        $completed, format_time($elapsed), format_rate($completed, $elapsed);
    print "\n";
}

# --- 3. Fire-and-forget SET ---
{
    print "3. Fire-and-forget SET (no callback)\n";
    print "-" x 40, "\n";

    my $mc = create_client();
    my $start = time();

    for my $i (1 .. $num_commands) {
        $mc->set("bench:ff:$i", $value);
    }

    # NOOP fence to ensure all commands processed
    $mc->noop(sub { $mc->disconnect });

    EV::run;
    my $elapsed = time() - $start;

    printf "  %d commands in %s  %s\n",
        $num_commands, format_time($elapsed), format_rate($num_commands, $elapsed);
    print "\n";
}

# --- 4. Multi-get (GETKQ + NOOP) ---
{
    print "4. Multi-get (GETKQ + NOOP)\n";
    print "-" x 40, "\n";

    my $mc = create_client();
    my $batches = int($num_commands / $mget_batch);
    $batches = 1 if $batches < 1;
    my $total_keys = $batches * $mget_batch;
    my $completed = 0;
    my $total_hits = 0;
    my $start = time();

    for my $b (0 .. $batches - 1) {
        my @keys = map { "bench:" . ($b * $mget_batch + $_) } 1 .. $mget_batch;
        $mc->mget(\@keys, sub {
            my ($results, $err) = @_;
            die "MGET failed: $err" if $err;
            $total_hits += scalar keys %$results;
            if (++$completed == $batches) {
                $mc->disconnect;
            }
        });
    }

    EV::run;
    my $elapsed = time() - $start;

    printf "  %d keys in %d batches  %s\n",
        $total_keys, $batches, format_time($elapsed);
    printf "  %s (per key)  hits: %d/%d\n",
        format_rate($total_keys, $elapsed), $total_hits, $total_keys;
    print "\n";
}

# --- 5. SET+GET round-trip ---
{
    print "5. SET+GET round-trip (sequential pairs)\n";
    print "-" x 40, "\n";

    my $mc = create_client();
    my $pairs = int($num_commands / 2);
    my $completed = 0;
    my $i = 0;
    my $start = time();

    my $do_next;
    $do_next = sub {
        $i++;
        if ($i > $pairs) {
            $mc->disconnect;
            return;
        }
        $mc->set("bench:rt:$i", $value, sub {
            my ($res, $err) = @_;
            die "SET failed: $err" if $err;
            $completed++;
            $mc->get("bench:rt:$i", sub {
                my ($val, $err) = @_;
                die "GET failed: $err" if $err;
                $completed++;
                $do_next->();
            });
        });
    };

    $do_next->();
    EV::run;
    my $elapsed = time() - $start;

    printf "  %d pairs in %s  %s per pair\n",
        $pairs, format_time($elapsed), format_time($elapsed / $pairs);
    printf "  %s (counting each pair as 1 op)\n",
        format_rate($pairs, $elapsed);
    print "\n";
}

# --- 6. Mixed workload ---
{
    print "6. Mixed workload (60%% GET, 25%% SET, 10%% INCR, 5%% DELETE)\n";
    print "-" x 40, "\n";

    my $mc = create_client();
    # Pre-create a counter key
    $mc->set("bench:counter", "0", sub {});
    $mc->noop(sub {}); # fence

    my $completed = 0;
    my $start = time();

    for my $i (1 .. $num_commands) {
        my $r = rand(100);
        my $k = int(rand($num_commands)) + 1;

        my $cb = sub {
            if (++$completed == $num_commands) {
                $mc->disconnect;
            }
        };

        if ($r < 60) {
            $mc->get("bench:$k", $cb);
        } elsif ($r < 85) {
            $mc->set("bench:$k", $value, $cb);
        } elsif ($r < 95) {
            $mc->incr("bench:counter", 1, $cb);
        } else {
            $mc->delete("bench:$k", $cb);
        }
    }

    EV::run;
    my $elapsed = time() - $start;

    printf "  %d commands in %s  %s\n",
        $completed, format_time($elapsed), format_rate($completed, $elapsed);
    print "\n";
}

# --- 7. Flow control comparison ---
{
    print "7. Flow control (SET with different max_pending)\n";
    print "-" x 40, "\n";

    my @limits = (0, 50, 100, 500);
    my $cmds = int($num_commands / 2);

    for my $limit (@limits) {
        my $mc = create_client(
            $limit > 0 ? (max_pending => $limit) : (),
        );
        my $completed = 0;
        my $max_waiting = 0;
        my $start = time();

        for my $i (1 .. $cmds) {
            $mc->set("bench:fc:$i", $value, sub {
                if (++$completed == $cmds) {
                    $mc->disconnect;
                }
            });
            my $w = $mc->waiting_count;
            $max_waiting = $w if $w > $max_waiting;
        }

        EV::run;
        my $elapsed = time() - $start;

        my $label = $limit == 0 ? "unlimited" : sprintf("%d", $limit);
        printf "  max_pending=%-10s %-18s  max_queue=%d\n",
            $label, format_rate($cmds, $elapsed), $max_waiting;
    }
    print "\n";
}

# --- 8. INCR throughput ---
{
    print "8. INCR pipeline\n";
    print "-" x 40, "\n";

    my $mc = create_client();
    $mc->set("bench:incr_target", "0", sub {});
    $mc->noop(sub {}); # fence

    my $completed = 0;
    my $start = time();

    for my $i (1 .. $num_commands) {
        $mc->incr("bench:incr_target", 1, sub {
            my ($val, $err) = @_;
            die "INCR failed: $err" if $err;
            if (++$completed == $num_commands) {
                printf "  Final value: %d\n", $val;
                $mc->disconnect;
            }
        });
    }

    EV::run;
    my $elapsed = time() - $start;

    printf "  %d increments in %s  %s\n",
        $completed, format_time($elapsed), format_rate($completed, $elapsed);
    print "\n";
}

# --- Cleanup ---
{
    print "Cleaning up...\n";
    my $mc = create_client();
    $mc->flush(sub { $mc->disconnect });
    EV::run;
}

print "=" x 60, "\n";
print "Done.\n";
print "=" x 60, "\n";
