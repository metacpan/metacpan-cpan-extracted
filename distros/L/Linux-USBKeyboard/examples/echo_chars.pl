#!/usr/bin/perl

use warnings;
use strict;

use Linux::USBKeyboard;
# NOTE either:
#  1. be root
#  2. chgrp plugdev /dev/bus/usb/*/*
#  3. do it with udev
#  /etc/udev/permissions.rules: SUBSYSTEM=="usb_device", GROUP="plugdev"

# e.g. 0x0e6a, 0x0001
my @args = @ARGV;
(@args) or
  die 'run `lsusb` to determine your vendor_id, product_id';
my ($vendor, $product) = map({hex($_)}
  $#args ? @args[0,1] : split(/:/, $args[0]));

my $exit = $args[2];

$product = 1 unless(defined($product));

my $k = eval {Linux::USBKeyboard->new($vendor, $product)};
if($@) { die "$@ - you might have the wrong permissions or address"; }

if(0) {
  print $k->_char, ".1\n";
  print $k->_char, ".2\n";
  print $k->_char, ".3\n";
  print $k->_char, ".4\n";
  print $k->_char, ".5\n";
  print $k->_char, ".6\n";
}
else {
  local $| = 1;
  while(1) {
    my $c = $k->char;
    #print $c, '(', length($c), ')';
    print $c;
    last if($c eq "\n" and $exit);
  }
}

# vim:ts=2:sw=2:et:sta
