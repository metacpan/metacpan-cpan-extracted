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
my $k = eval {Linux::USBKeyboard->open_keys(
  vendor  => $vendor,
  product => $product,
  xmap    => {
    map({("num_$_" => join(', ', ('bacon')x$_))} 1..9),
    num_5     => 'chunky',
    num_0     => 'yummy',
    num_star  => 'kevin',
    num_plus  => 'and',
    num_minus => 'no!',
    num_lock  => 'gimme',
    num_slash => 'or',
    num_enter => 'wrapped in',
    num_dot   => 'bits',
  },
)};
if($@) { die "$@ - you might have the wrong permissions or address"; }

$SIG{INT} = sub { warn "bye\n"; exit};
local $| = 1;
while(my $line = <$k>) {
  chomp($line);
  print $line, ' ';
}


# vim:ts=2:sw=2:et:sta
