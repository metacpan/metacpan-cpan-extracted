#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';

use Linux::USBKeyboard;

# e.g. 0x0e6a, 0x0001
(@ARGV) or
  die 'run `lsusb` to determine your vendor_id, product_id';
my ($vendor, $product) = map({hex($_)} @ARGV);
$product = 1 unless(defined($product));

{
  my $fh = Linux::USBKeyboard->open($vendor, $product);
  warn $fh, " ", $fh->pid;

  # this returns a zero-length char (non-blocking)
  for(0..3) {
    my $c = getc($fh);
    warn "char: '$c'\n";
  }

  # this buffers at lines
  my $line = <$fh>;
  warn "child said: $line";
}

# vim:ts=2:sw=2:et:sta
