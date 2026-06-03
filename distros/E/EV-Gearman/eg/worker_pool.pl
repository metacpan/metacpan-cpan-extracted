#!/usr/bin/env perl
# Concurrency-capped async worker.
#
# Async workers auto-grab the next job after dispatch, so by default
# they run with unbounded concurrency: as many in-flight jobs as the
# server has queued. To cap concurrency, call work_stop when at the
# limit and work() again when a slot frees up.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $MAX_CONCURRENT = $ENV{POOL_SIZE} // 4;

my $g = EV::Gearman->new(
    host       => '127.0.0.1',
    port       => 4730,
    client_id  => "pool-$$",
    reconnect  => 1,
);

my $inflight = 0;

sub finish_job {
    --$inflight;
    # Resume grabbing if we were at capacity
    $g->work if $inflight < $MAX_CONCURRENT;
}

$g->register_function(work => { async => 1 }, sub {
    my $job = shift;
    $inflight++;

    # Stop grabbing if we just hit the cap (no-op below the cap).
    $g->work_stop if $inflight >= $MAX_CONCURRENT;

    # Simulate work that takes 0.5–1.5s. Retain the timer: a bare
    # EV::timer in void context is freed when this callback returns, so
    # it would never fire.
    my $duration = 0.5 + rand 1.0;
    my $t; $t = EV::timer $duration, 0, sub {
        $job->complete(sprintf "done in %.2fs: %s", $duration, $job->workload);
        finish_job();
        undef $t;
    };
});

$g->work;
EV::run;
