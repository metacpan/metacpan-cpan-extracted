#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event::Backend::Epoll;

# Regression: EPOLLONESHOT must reliably re-arm on modify() even if the effective
# event set is unchanged.

pipe(my $r, my $w) or die "pipe: $!";

my $backend = Linux::Event::Backend::Epoll->new;

my $READABLE = 0x01;
my $ONESHOT  = 0x20;

my $mask = $READABLE | $ONESHOT;

my $count = 0;

$backend->watch($r, $mask, sub ($loop, $fh, $fd, $m, $tag) {
  $count++;

  # Drain one line
  my $buf = '';
  sysread($fh, $buf, 4096);

  # Rearm with the same mask. Without an unconditional re-arm operation, a second
  # write will never trigger.
  $backend->modify($fd, $mask);

}, _loop => undef, tag => undef);

# First event
syswrite($w, "a\n") or die "write: $!";
$backend->run_once(undef, 0.2);

# Second event should fire after re-arm
syswrite($w, "b\n") or die "write: $!";
$backend->run_once(undef, 0.2);

is($count, 2, "oneshot watcher can be re-armed with modify() using same mask");

done_testing;
