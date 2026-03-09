#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use threads;
use Thread::Queue;

use Linux::Event;

# Demonstrates the single-waker model.
#
# - The loop exposes an eventfd-backed waker via $loop->waker.
# - The waker is watched like any other readable fd.
# - A worker thread enqueues work and signals the waker to wake epoll_wait.

my $loop  = Linux::Event->new( model => 'reactor' );
my $waker = $loop->waker;

my $q = Thread::Queue->new;

$loop->watch(
  $waker->fh,
  read => sub ($loop, $fh, $watcher) {
    my $count = $waker->drain;
    say "[loop] woken ($count)";

    while (defined(my $job = $q->dequeue_nb)) {
      say "[loop] job: $job";
      if ($job eq 'quit') {
        say "[loop] stopping";
        $loop->stop;
        last;
      }
    }
  },
);

threads->create(sub {
  for my $i (1 .. 5) {
    sleep 1;
    my $job = "task-$i";
    $q->enqueue($job);
    say "[worker] queued $job";
    $waker->signal;
  }

  $q->enqueue('quit');
  say "[worker] queued quit";
  $waker->signal;
})->detach;

say "[main] run loop (stops on 'quit')";
$loop->run;
