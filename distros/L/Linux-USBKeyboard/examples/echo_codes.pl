#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';

use Linux::USBKeyboard;

# e.g. 0x0e6a, 0x0001
my @args = @ARGV;
(@args) or
  die 'run `lsusb` to determine your vendor_id, product_id';
my ($vendor, $product) = map({hex($_)}
  $#args ? @args : split(/:/, $args[0]));

$product = 1 unless(defined($product));

warn "getting $vendor, $product\n";
my $k = eval {Linux::USBKeyboard->new($vendor, $product)};
if($@) { die "$@ - you might have the wrong permissions or address"; }

local $| = 1;

# sorry, no forks
warn "type now\n";
$SIG{INT} = sub {warn "bye\n"; exit};
my $count = 0;
while(1) {
  my ($c, $s) = $k->keycode(timeout => 0);
  #warn "reading\n";# unless($count++ % 100);
  next if($c <= 0);
  warn "shifted: $s\n" if($s);
  if($c == 69) {
    print "NumLock!\n"
  }
  else {
    print Linux::USBKeyboard::code_to_key(0, $c);
    warn " code: $c\n";
  }
}

# vim:ts=2:sw=2:et:sta

