#!/usr/bin/perl -w

use lib '../lib';

use strict;

use Math::Big qw/hailstone/;
use Math::BigInt;

my $n = shift || 100;

$n = Math::BigInt->new($n);
my $x = Math::BigInt->new(1);

print "$n: ",scalar hailstone($n),"\n";

print "Hailstone numbers up to $n:\n";
while ($x < $n)
  {
  print "$x: ",scalar hailstone($x),"\n";
  $x++;
  }
