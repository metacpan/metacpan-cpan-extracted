#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Test::More;
use Linux::Event;

require Fcntl;

my $N = 10_000;

pipe(my $r, my $w) or die "pipe: $!";

my $flags = fcntl($r, Fcntl::F_GETFL(), 0) or die "fcntl get: $!";
fcntl($r, Fcntl::F_SETFL(), $flags | Fcntl::O_NONBLOCK()) or die "fcntl set: $!";

for (1..$N) {
  print {$w} "X\n" or die "write: $!";
}
close $w or die "close w: $!";

my $loop = Linux::Event->new;

my $buf = '';
my $lines = 0;
my $eof   = 0;

my $watcher;
$watcher = $loop->watch(
  $r,
  edge_triggered => 1,
  oneshot        => 1,
  read => sub ($loop, $fh, $w) {
    # Edge-triggered epoll requires draining until EAGAIN.
    while (1) {
      my $n = sysread($fh, my $chunk, 8192);

      if (!defined $n) {
        last if $!{EAGAIN} || $!{EWOULDBLOCK};
        fail("read error: $!");
        $loop->stop;
        return;
      }

      if ($n == 0) {
        $eof = 1;
        last;
      }

      $buf .= $chunk;
    }

    while ($buf =~ s/\AX\n//) {
      $lines++;
    }

    if ($eof && $lines == $N) {
      $w->cancel;
      close $fh;
      $loop->stop;
      return;
    }

    if ($eof && $lines < $N) {
      fail("EOF before expected lines (got=$lines expected=$N)");
      $loop->stop;
      return;
    }

    # Rearm EPOLLONESHOT: force an epoll_ctl MOD by toggling interest.
    $w->disable_read;
    $w->enable_read;

    return;
  },
);

ok($watcher && $watcher->is_active, 'watcher created and active');

# Watchdog: if we don't finish quickly, the oneshot fd is likely not being rearmed.
$loop->after(5.0, sub ($loop) {
  fail("timeout waiting for oneshot processing (lines=$lines expected=$N)");
  $loop->stop;
});

$loop->run;

is($lines, $N, 'processed all lines under oneshot+edge');

done_testing;
