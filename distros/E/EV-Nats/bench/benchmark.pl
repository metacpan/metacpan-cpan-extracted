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

# $setup gets a $done->() to call when the last message is through
sub run_bench {
    my ($name, $setup, $count, $psz) = @_;
    $count //= $n_msgs;
    $psz   //= $payload_sz;

    my ($t0, $elapsed);
    my $done = sub {
        $elapsed = time - $t0;
        $nats->disconnect;
        EV::break;
    };
    $nats = EV::Nats->new(
        host       => $host,
        port       => $port,
        on_error   => sub { die "nats error: @_\n" },
        on_connect => sub { $setup->(sub { $t0 = time }, $done) },
    );
    EV::run;

    if ($elapsed && $elapsed > 0) {
        printf "  %-30s %8.0f msgs/sec  %6.1f MB/s  (%.3fs)\n",
               $name, $count / $elapsed, ($count * $psz) / $elapsed / 1024 / 1024, $elapsed;
    }
}

# the subscriber is in place before the clock starts
sub pubsub_bench {
    my ($name, $subject, $body) = @_;
    run_bench($name, sub {
        my ($start, $done) = @_;
        my $received = 0;
        $nats->subscribe($subject, sub { $done->() if ++$received >= $n_msgs });
        my $go; $go = EV::timer 0.05, 0, sub {
            undef $go;
            $start->();
            $nats->publish($subject, $body) for 1 .. $n_msgs;
        };
    }, $n_msgs, length $body);
}

# flush() so the time covers the server confirming every PUB
run_bench("PUB fire-and-forget", sub {
    my ($start, $done) = @_;
    $start->();
    $nats->publish('bench.pub', $payload) for 1 .. $n_msgs;
    $nats->flush($done);
});

pubsub_bench("PUB + SUB (loopback)", 'bench.echo', $payload);

my $req_msgs = $n_msgs > 10000 ? 10000 : $n_msgs;
run_bench("REQ/REP (64 in flight)", sub {
    my ($start, $done) = @_;
    $nats->subscribe('bench.req', sub {
        my ($subject, $body, $reply) = @_;
        $nats->publish($reply, $body) if $reply;
    });

    my ($completed, $inflight, $sent) = (0, 0, 0);
    my $send_batch;
    $send_batch = sub {
        while ($sent < $req_msgs && $inflight < 64) {
            $sent++;
            $inflight++;
            $nats->request('bench.req', $payload, sub {
                $inflight--;
                return $send_batch->() if ++$completed < $req_msgs;
                undef $send_batch;
                $done->();
            }, 10000);
        }
    };
    my $go; $go = EV::timer 0.05, 0, sub {
        undef $go;
        $start->();
        $send_batch->();
    };
}, $req_msgs);

pubsub_bench("PUB + SUB (8B payload)", 'bench.small', 'x' x 8);

print "\ndone.\n";
