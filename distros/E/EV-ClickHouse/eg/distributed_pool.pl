#!/usr/bin/env perl
# Multi-region production pool combining every reliability primitive:
#
#   - hosts => [...]        round-robin failover across replicas
#   - circuit_threshold     short-circuit dead members after N failures
#   - circuit_cooldown      bring them back into rotation after a wait
#   - reconnect_jitter      desynchronise restart storms
#   - is_healthy            periodic probe to drive an out-of-band health
#                           gauge (e.g. for L4 load balancer membership)
#   - on_failover           emit a metric when the rotation advances
#   - Pool::shutdown        coordinated drain + finish with grace period
#
# Realistic shape for a long-running ingestor / API backend.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my @replicas = split /,/, $ENV{CH_REPLICAS}
            || '127.0.0.1:9000,127.0.0.1:9001,127.0.0.1:9002';

my $pool = EV::ClickHouse::Pool->new(
    size              => 8,
    hosts             => \@replicas,
    protocol          => 'native',
    auto_reconnect    => 1,
    reconnect_delay   => 0.2,
    reconnect_jitter  => 0.5,
    connect_timeout   => 3,
    circuit_threshold => 5,            # 5 consecutive errors → dead
    circuit_cooldown  => 30,           # cooled-off after 30s

    on_failover => sub {
        my ($oh, $op, $nh, $np, $msg) = @_;
        warn "[failover] $oh:$op → $nh:$np (reason: $msg)\n";
    },
);

# Periodic per-member health probe → membership decision.
my %healthy;
my $probe = EV::timer(0, 5, sub {
    for my $i (0 .. $pool->size - 1) {
        my $c = ($pool->conns)[$i];
        $c->is_healthy(sub {
            my ($ok, $err) = @_;
            my $was = $healthy{$i} // -1;
            $healthy{$i} = $ok ? 1 : 0;
            if ($was != $healthy{$i}) {
                printf "[health] member %d: %s%s\n",
                       $i, ($ok ? 'UP' : 'DOWN'), ($err ? " ($err)" : '');
            }
        }, 2);
    }
});

# Per-query timing histogram via on_query_complete.
my @durations;
my $work = EV::timer(0, 0.2, sub {
    for (1 .. 20) {
        $pool->query(
            "select count() from system.numbers limit 100000",
            sub {
                my (undef, $err) = @_;
                # Use the connection-level on_query_complete normally;
                # this callback is just the per-query result handler.
                warn "query err: $err\n" if $err;
            },
        );
    }
});

# Coordinated shutdown on SIGINT: drain in-flight (up to 10s), then close.
my $shutdown = EV::signal('INT', sub {
    undef $work; undef $probe;
    warn "draining (grace 10s)…\n";
    $pool->shutdown(10, sub {
        my ($err) = @_;
        warn "shutdown: ", ($err // 'clean'), "\n";
        EV::break;
    });
});

EV::run;
