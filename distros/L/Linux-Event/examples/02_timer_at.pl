#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;

# Create loop (epoll backend)
my $loop = Linux::Event->new( model => 'reactor', backend => 'epoll' );

# Refresh cached monotonic time once before computing an absolute deadline
$loop->clock->tick;  # tick() updates the cached monotonic time :contentReference[oaicite:1]{index=1}

# Compute an *absolute* monotonic deadline: cached now_s + 80ms
my $deadline = $loop->clock->now_s + 0.080;  # now_s is cached monotonic seconds :contentReference[oaicite:2]{index=2}

say "timer_at: scheduling at absolute monotonic +80ms";

# at() schedules to that absolute monotonic time (not wall-clock time-of-day)
$loop->at($deadline, sub ($loop) {
  say "timer_at: fired";
  $loop->stop;
});

$loop->run;

say "timer_at: done";
