#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use POSIX ();
use Fcntl ();
use Time::HiRes qw(time);

use Linux::Event;

# Stress / semantic test for EPOLLONESHOT under edge-triggered epoll.
#
# Key points:
#   * With EPOLLET (edge-triggered), the read callback MUST drain until EAGAIN.
#   * epoll wakeups represent kernel readiness only. If you read-ahead into a
#     userland buffer, epoll will NOT wake you again to process the buffered data.
#     Therefore, any "process a little at a time" behavior MUST be driven by
#     userland scheduling (timers) or by processing the buffer immediately.
#
# This script supports both modes:
#   - PROCESS_LIMIT=0 (default): process the entire userland buffer immediately.
#   - PROCESS_LIMIT>0: process at most that many lines per slice, then schedule
#     another slice via after(0) until the buffer is empty.
#
# Env knobs:
#   N              number of lines to send (default 10000)
#   EDGE           1=edge-triggered (default 1)
#   ONESHOT        1=oneshot watcher (default 1)
#   READ_SIZE      sysread size in bytes (default 8192)
#   PROCESS_LIMIT  max lines processed per slice; 0 means "all" (default 0)
#   HB_S           heartbeat period seconds (default 0.5)
#   TIMEOUT_S      timeout seconds (default 30)

my $N             = $ENV{N}             // 10_000;
my $EDGE          = $ENV{EDGE}          // 1;
my $ONESHOT       = $ENV{ONESHOT}       // 1;
my $READ_SIZE     = $ENV{READ_SIZE}     // 8192;
my $PROCESS_LIMIT = $ENV{PROCESS_LIMIT} // 0;
my $HB_S          = $ENV{HB_S}          // 0.5;
my $TIMEOUT_S     = $ENV{TIMEOUT_S}     // 30;

die "N must be > 0\n" if $N <= 0;
die "READ_SIZE must be > 0\n" if $READ_SIZE <= 0;
die "HB_S must be > 0\n" if $HB_S <= 0;
die "TIMEOUT_S must be > 0\n" if $TIMEOUT_S <= 0;

my $loop = Linux::Event->new;

pipe(my $r, my $w) or die "pipe: $!";

# nonblocking read end
my $flags = fcntl($r, Fcntl::F_GETFL(), 0) or die "fcntl(F_GETFL): $!";
fcntl($r, Fcntl::F_SETFL(), $flags | Fcntl::O_NONBLOCK()) or die "fcntl(F_SETFL): $!";

my $pid = fork();
die "fork: $!" if !defined $pid;

if ($pid == 0) {
  close $r;
  # Use syswrite (not buffered print) so the writer reliably pushes all data.
  my $payload = "X\n" x $N;
  my $off = 0;
  my $len = length($payload);
  while ($off < $len) {
    my $n = syswrite($w, $payload, $len - $off, $off);
    next if !defined($n) && ($!{EINTR});
    last if !defined($n);
    $off += $n;
  }
  close $w;
  POSIX::_exit(0);
}

close $w;

my $t0 = time;
my $lines = 0;
my $buf = '';
my $eof = 0;

print "START edge_safe oneshot: N=$N EDGE=$EDGE ONESHOT=$ONESHOT READ_SIZE=$READ_SIZE PROCESS_LIMIT=$PROCESS_LIMIT TIMEOUT_S=$TIMEOUT_S\n";

# Heartbeat: proves timer+timeout machinery is alive and shows progress.
my $hb;
$hb = sub ($loop) {
  my $dt = time - $t0;
  printf "HB t=%.1fs lines=%d buf=%d eof=%d\n", $dt, $lines, length($buf), $eof;
  my $wp = waitpid($pid, POSIX::WNOHANG());
  my $alive = ($wp == 0) ? 1 : 0;
  printf "HB child_alive=%d\n", $alive;
  $loop->after($HB_S, $hb);
};
$loop->after($HB_S, $hb);

my $wtr;

my $done = sub ($why) {
  my $dt = time - $t0;
  printf "DONE\n  why      = %s\n  expected = %d\n  lines    = %d\n  rate     = %.1f lines/sec\n",
    $why, $N, $lines, ($dt > 0 ? $lines / $dt : 0);
  $wtr->cancel if $wtr;
  close $r;
  $loop->stop;
};

my $process_buf;
$process_buf = sub ($loop) {
  my $limit = $PROCESS_LIMIT;
  my $did = 0;

  while (1) {
    last if $limit && $did >= $limit;
    last unless $buf =~ s/\AX\n//;
    $lines++;
    $did++;

    if ($lines >= $N) {
      $done->("ok");
      return;
    }
  }

  # If we still have buffered lines, schedule another slice immediately.
  if ($buf =~ /\AX\n/) {
    $loop->after(0, $process_buf);
  }
  elsif ($eof) {
    # We drained kernel + userland and hit EOF but not enough lines.
    $done->("eof_early");
  }
};

$wtr = $loop->watch(
  $r,
  edge_triggered => $EDGE ? 1 : 0,
  oneshot        => $ONESHOT ? 1 : 0,

  read => sub ($loop, $fh, $watcher) {
    # Drain to EAGAIN (required for EPOLLET correctness).
    while (1) {
      my $n = sysread($fh, my $chunk, $READ_SIZE);
      if (!defined $n) {
        last if $!{EAGAIN} || $!{EWOULDBLOCK};
        $done->("sysread_error:$!");
        return;
      }
      if ($n == 0) { $eof = 1; last; }
      $buf .= $chunk;
    }

    # Process userland buffer (immediate or sliced).
    $process_buf->($loop);

    # Rearm oneshot interest. If ONESHOT is off, this is a no-op-ish update.
    if ($ONESHOT) {
      $watcher->disable_read;
      $watcher->enable_read;
    }

    return;
  },
);

# Hard timeout: if we got stuck, print current state.
$loop->after($TIMEOUT_S, sub ($loop) {
  $done->("timeout_${TIMEOUT_S}s");
});

$loop->run;

exit 0;
