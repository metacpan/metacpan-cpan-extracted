#!/usr/bin/perl

use warnings;
use strict;

use Time::HiRes ();

use Device::SerialPins;

my $dev = shift(@ARGV) or
  die "need a device argument (e.g. '/dev/ttyS0')";

srand;

my $sp = Device::SerialPins->new($dev);
$sp->set_dtr(0);
$sp->set_rts(0);

for(1..100) {
  my $method = 'set_' . ((rand > 0.5) ? 'dtr' : 'rts');
  my $bool = (rand > 0.5);
  $sp->$method($bool);
  Time::HiRes::sleep(0.05);
}

# vim:ts=2:sw=2:et:sta
