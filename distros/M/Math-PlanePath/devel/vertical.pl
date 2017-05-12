#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use POSIX 'fmod';
use Math::BigRat;
use Math::Prime::XS;

#use Smart::Comments;

use constant PHI => (1 + sqrt(5)) / 2;

# (3n-1)*n/2 pentagonal

# (3n+1)*n/2 second pentagonal
# http://www.research.att.com/~njas/sequences/A005449
# sum of n consecutive numbers >= n   (n+1)+(n+2)+...+(n+n)
# triangular+square (n+1)*n/2 + n*n

# (3n+1)*n/2-2 = offset (3n+7)*n/2
# http://www.research.att.com/~njas/sequences/A140090
# sum n+1 to n+n-3 or some such

# (3n+1)*n/2
# (3n+1)*n/2 - 1
# (3n+1)*n/2 - 2

sub three {
  my ($i) = @_;
  return (3*$i+1)*$i/2 - 2;
}

sub is_perfect_square {
  my ($n) = @_;
  $n = sqrt($n);
  return ($n == int($n));
}

{
  my $prev_k = 0;
  foreach my $k (0 .. 1000) {
    my $sq = 24*$k+1;
    if (is_perfect_square($sq)) {
      printf "%4d %+4d   %4d  %4d\n", $k, $k-$prev_k, $k%24, $sq;
      $prev_k = $k;
    }
  }
  exit 0;
}

{
  # i==0mod4 or 1mod4 always even
  #
  foreach my $k (0 .. 100) {
    my $i = 4*$k + 2;
    my $n = three($i);
    my $factors = factorize($n);
    printf "%4d  %4d  %s\n", $i,$n,$factors;
#     unless ($factors =~ /\Q*/) {
#       die;
#     }
  }
  exit 0;
}
{
  local $, = ',';
  print map {three($_)} 0..20;
  exit 0;
}

{
  my $a = Math::BigRat->new('3/2');
  my $b = Math::BigRat->new('1/2');
  my $c = Math::BigRat->new('-2');
  my $x = -$b;
  my $sq = ($b*$b-4*$a*$c);
  my $y = $sq;
  $y->bsqrt;
  print "$x $sq $y\n";
  my $r1 = ($x + $y)/(2*$a);
  my $r2 = ($x - $y)/(2*$a);
  print "$r1 $r2\n";
  exit 0;
}

{
  foreach my $i (5 .. 500) {
    my $n = three($i);
    if (Math::Prime::XS::is_prime($n)) {
      say "$i $n";
      last;
    }
  }
  exit 0;
}



sub factorize {
  my ($n) = @_;
  my @factors;
  foreach my $f (2 .. int(sqrt($n)+1)) {
    while (($n % $f) == 0) {
      push @factors, $f;
      ### $n
      $n /= $f;
    }
  }
  if ($n != 1) {
    push @factors, $n;
  }
  return join ('*',@factors);
}
exit 0;

