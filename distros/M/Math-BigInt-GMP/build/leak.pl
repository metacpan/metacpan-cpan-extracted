#!/usr/bin/perl -w

use strict;
use lib 'lib';
use lib 'blib/arch';
use Math::BigInt lib => 'GMP';
use Devel::Leak;

my $x = Math::BigInt->new(44);
my $y = Math::BigInt->new(21);

require Scalar::Util;   # otherwise the first sub would do this

my $xg = Math::BigInt::GMP->_new("44");
my $yg = Math::BigInt::GMP->_new("21");

for my $do (
  [ sub { $xg = Math::BigInt::GMP->_div($xg,$yg); 1; }, 'divide direct' ],
  [ sub { my $z = $x / $y; 1; }, 'divide' ],
  [ sub { my $z = $x - $y; 1; }, 'subtract' ],
  [ sub { my $z = $x + $y; 1; }, 'add' ],
  [ sub { my $z = $x % $y; 1; }, 'mod' ],
  [ sub { my $z = $x ** $y; 1; }, 'pow' ],
  [ sub { my $z = $x ^ $y; 1; }, 'xor' ],
  [ sub { my $z = $x | $y; 1; }, 'ior' ],
  [ sub { my $z = $x & $y; 1; }, 'and' ],
  [ sub { my $z = $x; $z -= $y; 1; }, '-=' ],
  [ sub { my $z = $x; $z += $y; 1; }, '+=' ],
  [ sub { my $z = $x; $z %= $y; 1; }, '%=' ],
  [ sub { my $z = $x; $z /= $y; 1; }, '/=' ],
  [ sub { my ($q,$r) = $x->copy()->bdiv($y); 1; }, '(q,r) = x / y' ],
  [ sub { $x->_trailing_zeros(); }, '_zeros(x)' ],			# needs an even number!
 )
  {
  my $handle;
  my $count = Devel::Leak::NoteSV($handle);
  for (1..13) { &{$do->[0]}; }
  print "$do->[1] leaked ", Devel::Leak::CheckSV($handle) - $count, " things\n";
  }

exit;
