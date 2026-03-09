#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use threads;
use Thread::Queue;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;

my $loop  = Linux::Event->new(model => 'reactor');
my $waker = $loop->waker;
my $queue = Thread::Queue->new;

$loop->watch(
  $waker->fh,
  read => sub ($loop, $fh, $watcher) {
    my $count = $waker->drain;
    say "waker drained count=$count";

    while (defined(my $job = $queue->dequeue_nb)) {
      say "job=$job";
      if ($job eq 'quit') {
        $loop->stop;
        last;
      }
    }
  },
);

threads->create(sub {
  for my $i (1 .. 3) {
    $queue->enqueue("task-$i");
    $waker->signal;
    sleep 1;
  }

  $queue->enqueue('quit');
  $waker->signal;
})->detach;

$loop->run;
