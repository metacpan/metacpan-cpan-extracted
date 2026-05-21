#!/usr/bin/env perl
# EV::Nats benchmark suite
use strict;
use warnings;
use EV;
use EV::Nats;
use Time::HiRes qw(time);

my $host       = $ENV{BENCH_HOST}       // '127.0.0.1';
my $port       = $ENV{BENCH_PORT}       // 4222;
my $n_msgs     = $ENV{BENCH_MESSAGES}   // 100_000;
my $payload_sz = $ENV{BENCH_PAYLOAD}    // 100;

my $payload = 'x' x $payload_sz;

print "EV::Nats benchmark\n";
print "  host=$host:$port msgs=$n_msgs payload=${payload_sz}B\n\n";

my $nats;

sub run_bench {
    my ($name, $setup) = @_;

    my $done = 0;
    my ($t0, $elapsed);

    $nats = EV::Nats->new(
        host       => $host,
        port       => $port,
        on_error   => sub { die "nats error: @_\n" },
        on_connect => sub {
            $setup->(\$done, \$t0, \$elapsed);
        },
    );

    EV::run;

    if ($elapsed && $elapsed > 0) {
        my $ops = $n_msgs / $elapsed;
        my $mbps = ($n_msgs * $payload_sz) / $elapsed / 1024 / 1024;
        printf "  %-30s %8.0f msgs/sec  %6.1f MB/s  (%.3fs)\n",
               $name, $ops, $mbps, $elapsed;
    }
}

# 1. Fire-and-forget publish (no subscriber).
# Uses flush() so timing reflects when the server has confirmed receipt
# of every PUB, not just when the local write buffer was scheduled.
run_bench("PUB fire-and-forget", sub {
    my ($done, $t0, $elapsed) = @_;

    $$t0 = time;
    for my $i (1 .. $n_msgs) {
        $nats->publish('bench.pub', $payload);
    }
    $nats->flush(sub {
        $$elapsed = time - $$t0;
        $nats->disconnect;
        EV::break;
    });
});

# 2. PUB with subscriber receiving
run_bench("PUB + SUB (loopback)", sub {
    my ($done, $t0, $elapsed) = @_;

    my $received = 0;
    $nats->subscribe('bench.echo', sub {
        $received++;
        if ($received >= $n_msgs) {
            $$elapsed = time - $$t0;
            $nats->disconnect;
            EV::break;
        }
    });

    my $go; $go = EV::timer 0.05, 0, sub {
        undef $go;
        $$t0 = time;
        for my $i (1 .. $n_msgs) {
            $nats->publish('bench.echo', $payload);
        }
    };
});

# 3. Request/reply throughput
my $req_msgs = $n_msgs > 10000 ? 10000 : $n_msgs;
run_bench("REQ/REP (${req_msgs} msgs)", sub {
    my ($done, $t0, $elapsed) = @_;

    # responder
    $nats->subscribe('bench.req', sub {
        my ($subject, $payload, $reply) = @_;
        $nats->publish($reply, $payload) if $reply;
    });

    my $completed = 0;
    my $inflight  = 0;
    my $sent      = 0;
    my $max_inflight = 64;

    my $send_batch;
    $send_batch = sub {
        while ($sent < $req_msgs && $inflight < $max_inflight) {
            $sent++;
            $inflight++;
            $nats->request('bench.req', $payload, sub {
                $inflight--;
                $completed++;
                if ($completed >= $req_msgs) {
                    $$elapsed = time - $$t0;
                    $nats->disconnect;
                    EV::break;
                } else {
                    $send_batch->();
                }
            }, 10000);
        }
    };

    my $go; $go = EV::timer 0.05, 0, sub {
        undef $go;
        $$t0 = time;
        $send_batch->();
    };
});

# 4. Small message throughput (8 bytes)
{
    my $small = 'x' x 8;
    run_bench("PUB + SUB (8B payload)", sub {
        my ($done, $t0, $elapsed) = @_;

        my $received = 0;
        $nats->subscribe('bench.small', sub {
            $received++;
            if ($received >= $n_msgs) {
                $$elapsed = time - $$t0;
                $nats->disconnect;
                EV::break;
            }
        });

        my $go; $go = EV::timer 0.05, 0, sub {
            undef $go;
            $$t0 = time;
            for my $i (1 .. $n_msgs) {
                $nats->publish('bench.small', $small);
            }
        };
    });
}

print "\ndone.\n";
