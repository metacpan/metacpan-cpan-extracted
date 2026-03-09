#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

# ------------------------------------------------------------------------------
# Setup loop + waker
# ------------------------------------------------------------------------------

my $loop  = Linux::Event->new( model => 'reactor' );
my $waker = $loop->waker;

# ------------------------------------------------------------------------------
# Payload channel: a simple pipe (stand-in for "some external work queue")
# ------------------------------------------------------------------------------
pipe(my $r, my $w) or die "pipe: $!";

# Make read end non-blocking so we can drain it safely.
my $flags = fcntl($r, F_GETFL, 0) or die "fcntl(F_GETFL): $!";
fcntl($r, F_SETFL, $flags | O_NONBLOCK) or die "fcntl(F_SETFL): $!";

# ------------------------------------------------------------------------------
# Watch ONLY the waker fd.
#
# This demonstrates the intended composition:
# - some external agent enqueues payload (here: writes to pipe)
# - then signals the waker
# - loop wakes and drains payload from wherever you keep it
#
# Note: in this demo we do NOT watch the pipe directly on purpose.
# ------------------------------------------------------------------------------

$loop->watch(
  $waker->fh,
  read => sub ($loop, $watcher, $data) {

    my $count = $waker->drain;
    say "[loop] woken ($count)";

    # Drain the pipe (payload channel) until EAGAIN.
    while (1) {
      my $buf = '';
      my $n = sysread($r, $buf, 4096);

      last if !defined $n && $!{EAGAIN};  # nothing available right now
      die  "sysread: $!" if !defined $n;

      last if $n == 0;                   # writer closed

      # Split into lines for this demo.
      for my $line (split /\n/, $buf, -1) {
        next if $line eq '';             # last chunk may be partial
        say "[loop] got: $line";

        # Demo stop condition:
        if ($line eq 'DONE') {
          say "[loop] done";
          exit 0;
        }
      }
    }
  },
);

# ------------------------------------------------------------------------------
# Fork a child to simulate "external agent"
# ------------------------------------------------------------------------------

my $pid = fork();
die "fork: $!" if !defined $pid;

if ($pid == 0) {
  # child
  close $r;

  for my $i (1 .. 5) {
    my $msg = "job-$i\n";
    syswrite($w, $msg) == length($msg) or die "syswrite: $!";

    # IMPORTANT: signal the loop *after* enqueuing payload.
    $waker->signal;

    select undef, undef, undef, 0.10;
  }

  my $done = "DONE\n";
  syswrite($w, $done) == length($done) or die "syswrite: $!";
  $waker->signal;

  close $w;
  exit 0;
}

# parent
close $w;

say "[parent] loop running (child pid=$pid)";
$loop->run;
