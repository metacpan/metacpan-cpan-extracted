#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use POSIX ();
use Fcntl ();
use Time::HiRes qw(time);

use Linux::Event;

# Simple throughput benchmark for pipe readability under epoll.
#
# This measures end-to-end time to receive N newline-delimited messages from
# a child process writing to a pipe.
#
# Env knobs:
#   N         number of lines (default 200000)
#   EDGE      1=edge-triggered (default 1)
#   ONESHOT   1=oneshot watcher (default 1)
#   READ_SIZE sysread size (default 8192)
#
# Output:
#   lines, seconds, lines/sec

my $N         = $ENV{N}         // 200_000;
my $EDGE      = $ENV{EDGE}      // 1;
my $ONESHOT   = $ENV{ONESHOT}   // 1;
my $READ_SIZE = $ENV{READ_SIZE} // 8192;

die "N must be > 0\n" if $N <= 0;

my $loop = Linux::Event->new;

pipe(my $r, my $w) or die "pipe: $!";

my $flags = fcntl($r, Fcntl::F_GETFL(), 0) or die "fcntl(F_GETFL): $!";
fcntl($r, Fcntl::F_SETFL(), $flags | Fcntl::O_NONBLOCK()) or die "fcntl(F_SETFL): $!";

my $pid = fork();
die "fork: $!" if !defined $pid;

if ($pid == 0) {
  close $r;
  for (1..$N) { print {$w} "X\n" or last }
  close $w;
  POSIX::_exit(0);
}
close $w;

my $t0 = time;
my $lines = 0;
my $buf = '';
my $eof = 0;

my $wtr;
$wtr = $loop->watch(
  $r,
  edge_triggered => $EDGE ? 1 : 0,
  oneshot        => $ONESHOT ? 1 : 0,

  read => sub ($loop, $fh, $watcher) {
    while (1) {
      my $n = sysread($fh, my $chunk, $READ_SIZE);
      if (!defined $n) {
        last if $!{EAGAIN} || $!{EWOULDBLOCK};
        die "sysread: $!";
      }
      if ($n == 0) { $eof = 1; last; }
      $buf .= $chunk;
    }

    while ($buf =~ s/\AX\n//) { $lines++ }

    if ($lines >= $N) {
      my $dt = time - $t0;
      printf "bench oneshot=%d edge=%d read_size=%d\n", $ONESHOT, $EDGE, $READ_SIZE;
      printf "lines=%d seconds=%.6f lines/sec=%.1f\n", $lines, $dt, ($dt > 0 ? $lines / $dt : 0);
      $watcher->cancel;
      close $r;
      $loop->stop;
      return;
    }

    if ($ONESHOT) {
      $watcher->disable_read;
      $watcher->enable_read;
    }

    if ($eof && $lines < $N) {
      my $dt = time - $t0;
      printf "bench eof early oneshot=%d edge=%d read_size=%d\n", $ONESHOT, $EDGE, $READ_SIZE;
      printf "lines=%d expected=%d seconds=%.6f\n", $lines, $N, $dt;
      $watcher->cancel;
      close $r;
      $loop->stop;
    }
  },
);

$loop->run;

exit 0;
