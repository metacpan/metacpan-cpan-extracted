#!/usr/bin/perl

# Copyright 2008 Eric L. Wilhelm, all rights reserved

# Read barcode scanner and lookup at upcdatabase.com.

use warnings;
use strict;

use Linux::USBKeyboard;

my @args = @ARGV;
(@args) or
  die 'run `lsusb` to determine your vendor_id, product_id';
my ($vendor, $product) = map({hex($_)}
  $#args ? @args[0,1] : split(/:/, $args[0]));
$product or die "bah";

my $kb = Linux::USBKeyboard->open($vendor, $product);

my $base_url = 'http://www.upcdatabase.com/item/';

while(my $barcode = <$kb>) {
  chomp($barcode);
  unless(fork) {
    close(STDIN); close(STDERR); close(STDOUT);
    exec('dillo', $base_url . $barcode) or die;
  }
}

# vim:ts=2:sw=2:et:sta
