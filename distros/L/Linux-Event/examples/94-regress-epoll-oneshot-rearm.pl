#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event::Backend::Epoll;

# Manual regression runner for EPOLLONESHOT re-arm behavior.
# Expected output: OK: count=2

pipe(my $r, my $w) or die "pipe: $!";

my $backend = Linux::Event::Backend::Epoll->new;

my $READABLE = 0x01;
my $ONESHOT  = 0x20;
my $mask = $READABLE | $ONESHOT;

my $count = 0;

$backend->watch($r, $mask, sub ($loop, $fh, $fd, $m, $tag) {
  $count++;
  my $buf = '';
  sysread($fh, $buf, 4096);
  $backend->modify($fd, $mask);
}, _loop => undef, tag => undef);

syswrite($w, "a\n") or die "write: $!";
$backend->run_once(undef, 0.2);

syswrite($w, "b\n") or die "write: $!";
$backend->run_once(undef, 0.2);

die "FAIL: expected count=2 got count=$count\n" if $count != 2;
print "OK: EPOLLONESHOT re-arm works; count=$count\n";
