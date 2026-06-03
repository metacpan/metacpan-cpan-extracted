#!/usr/bin/env perl
# Priority queues.
#
# Gearman has three priorities (low / normal / high). Workers always
# drain high first, then normal, then low — so a flood of low-priority
# jobs cannot starve high-priority work.
#
# Use cases:
#   - high: user-facing, latency-sensitive (paid checkout, password reset)
#   - normal: standard work (default)
#   - low: backfills, batch reports, cleanup
use strict;
use warnings;
use EV;
use EV::Gearman;

my $cli = EV::Gearman->new(host => '127.0.0.1', port => 4730);
my $wkr = EV::Gearman->new(host => '127.0.0.1', port => 4730);

my @order;
$wkr->register_function('task' => sub {
    my $job = shift;
    push @order, $job->workload;
    return "ok";
});

# Submit a mix of priorities. Note that submission order is
# unrelated to execution order — gearmand respects priority class.
my @subs;
$cli->submit_job_low ('task', "low-1");
$cli->submit_job     ('task', "norm-1");
$cli->submit_job_low ('task', "low-2");
$cli->submit_job_high('task', "HIGH-1");
$cli->submit_job     ('task', "norm-2");
$cli->submit_job_high('task', "HIGH-2");

# Wait until all 6 jobs are done, then start the worker — this
# proves priority ordering since the queue is fully populated
# before any GRAB_JOB happens.
my $remaining = 6;
my $cb = sub { EV::break unless --$remaining };
$cli->submit_job_low ('task', "low-3", $cb);   # 7th, just to count down
$remaining = 7;
my $delay = EV::timer 0.1, 0, sub {
    $wkr->work;
};

my $t = EV::timer 5, 0, sub { warn "timeout\n"; EV::break };
EV::run;

print "execution order: ", join(', ', @order), "\n";
# Expected: HIGH-* first, then norm-*, then low-* (within class
# the order is FIFO).
