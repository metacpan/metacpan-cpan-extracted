#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

# Direct Linux::Epoll EPOLLONESHOT+EPOLLET re-arm test.
#
# This is intentionally independent of Linux::Event, so we can determine whether
# any re-arm issue comes from the underlying epoll wrapper.
#
# Env:
#   N=10000      total lines the child writes
#   CHUNK=1      lines to process per oneshot wake
#   REARM=modify (or readd) how to re-arm
#
# Expected:
#   - With REARM=modify, should steadily reach N.
#   - If REARM=readd misbehaves on your system, that implicates re-entrant
#     delete+add while inside a Linux::Epoll callback.

use POSIX ();
use Time::HiRes qw(time);

use Linux::Epoll;
require Fcntl;

my $N     = $ENV{N}     // 10_000;
my $CHUNK = $ENV{CHUNK} // 1;
my $REARM = $ENV{REARM} // 'modify'; # modify | readd
my $TIMEOUT_S = $ENV{TIMEOUT_S} // 30;

pipe(my $r, my $w) or die "pipe: $!";

my $flags = fcntl($r, Fcntl::F_GETFL(), 0) or die "fcntl get: $!";
fcntl($r, Fcntl::F_SETFL(), $flags | Fcntl::O_NONBLOCK()) or die "fcntl set: $!";

my $pid = fork();
die "fork: $!" if !defined $pid;

if ($pid == 0) {
  close $r;
  for (1..$N) { print {$w} "X\n" }
  close $w;
  POSIX::_exit(0);
}
close $w;

my $ep = Linux::Epoll->new;

my $t0 = time;
my $last = $t0;

my $buf = '';
my $lines = 0;

my $cb; $cb = sub ($ev) {
  my $processed = 0;

  while ($processed < $CHUNK) {
    my $n = sysread($r, my $chunk, 2); # avoid read-ahead

    if (!defined $n) {
      last if $!{EAGAIN} || $!{EWOULDBLOCK};
      die "read error: $!";
    }

    if ($n == 0) {
      # EOF
      return;
    }

    $buf .= $chunk;

    while ($buf =~ s/\AX\n//) {
      $lines++;
      $processed++;
      $last = time;
      last if $processed >= $CHUNK;
    }
  }

  # re-arm oneshot
  my $events = [ 'in', 'et', 'oneshot' ];

  if ($REARM eq 'modify') {
    $ep->modify($r, $events, $cb);
  } elsif ($REARM eq 'readd') {
    $ep->delete($r);
    $ep->add($r, $events, $cb);
  } else {
    die "Unknown REARM=$REARM (expected modify or readd)";
  }
};

$ep->add($r, [ 'in', 'et', 'oneshot' ], $cb);

while (1) {
  # Linux::Epoll expects maxevents first, then timeout.
  # Passing a fractional timeout as the first argument gets truncated to 0.
  $ep->wait(64, 0.25);

  if ($lines >= $N) {
    my $dt = time - $t0;
    print "DONE\n";
    print "  why      = ok\n";
    print "  expected = $N\n";
    print "  lines    = $lines\n";
    print "  chunk    = $CHUNK\n";
    print "  rearm    = $REARM\n";
    printf "  rate     = %.1f lines/sec\n", ($lines / ($dt || 1e-6));
    last;
  }

  if ((time - $last) > $TIMEOUT_S) {
    my $dt = time - $t0;
    print "DONE\n";
    print "  why      = timeout_no_progress_${TIMEOUT_S}s\n";
    print "  expected = $N\n";
    print "  lines    = $lines\n";
    print "  chunk    = $CHUNK\n";
    print "  rearm    = $REARM\n";
    printf "  rate     = %.1f lines/sec\n", ($lines / ($dt || 1e-6));
    exit 2;
  }
}

exit 0;
