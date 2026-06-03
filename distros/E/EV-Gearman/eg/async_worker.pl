#!/usr/bin/perl
# Async worker: completes each job after a delay without blocking the loop.
# Demonstrates timer-driven completion + send_data / status updates.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);

# Track per-job timers so they survive the callback return.
my %jobs;

$g->register_function(slow_echo => { async => 1 }, sub {
    my $job = shift;
    my $id  = $job->handle;

    $jobs{$id}{job}    = $job;
    $jobs{$id}{step}   = 0;
    $jobs{$id}{timer}  = EV::timer 0, 0.5, sub {
        my $j = $jobs{$id}{job};
        my $s = ++$jobs{$id}{step};
        if ($s < 4) {
            $j->status($s, 4);
            $j->send_data("step $s of 4");
        } else {
            $j->complete("done: " . $j->workload);
            delete $jobs{$id};
        }
    };
});

$g->work;
EV::run;
