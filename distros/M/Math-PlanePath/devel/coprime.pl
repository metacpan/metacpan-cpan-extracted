#!/usr/bin/perl -w

# Copyright 2010, 2011, 2014 Kevin Ryde

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
use Math::Factor::XS 0.39 'factors', 'prime_factors'; # version 0.39 for prime_factors()
use List::MoreUtils 'uniq';
use Math::PlanePath::CoprimeColumns;

{
  my $coprime = sub {
    my ($x,$y) = @_;
    return $x > 0 && Math::PlanePath::CoprimeColumns::_coprime($x,$y);
  };
  foreach my $n (2*2*2*3, 3*3*3*5) {
    my $tot = Math::PlanePath::CoprimeColumns::_totient($n);
    my @factors = uniq(prime_factors($n));
    my $factors_str = join(',',@factors);
    print "n=$n  totient=$tot  factors=$factors_str\n";
    my @coprimes = grep {$coprime->($_,$n)} 0 .. $n-1;
    my @coprime_dots = map {($coprime->($_,$n)?'*':'_')
                              .($_ % 3 == 2 ? ',' : '')} 0 .. $n-1;
    my $want_str = join(',',@coprimes);
    my $dots_str = join('',@coprime_dots);
    print "dots $dots_str\n";
    print "want $want_str\n";
    my @got;
    foreach my $i (0 .. $#coprimes) {
      my $c = $i+1;
      foreach my $f (@factors) {
        $c += int($i/($f-1));
      }
      push @got, $c;
    }
    my $got_str = join(',',@got);
    my $diff = ($want_str eq $got_str ? '' : ' ***');
    print "got  $got_str$diff";
    print "\n";
    print "\n";
  }
  exit 0;
}

{
  require Math::PlanePath::CoprimeColumns;
  my $n = 0;
  foreach my $x (3 .. 1000) {
    foreach my $y (1 .. $x-1) {
      $n += Math::PlanePath::CoprimeColumns::_coprime($x,$y);
    }
    my $square = $x*$x;
    my $frac = $n / $square;
    printf "%d %d  %d %.3g\n", $x, $n, $square, $frac;
  }
  exit 0;
}
{
  require Math::PlanePath::CoprimeColumns;
  foreach my $x (2 .. 100) {
    my $n = 0;
    my @list;
    foreach my $y (1 .. $x-1) {
      if (Math::PlanePath::CoprimeColumns::_coprime($x,$y)) {
        $n++;
        push @list, $y;
      }
    }
    my $c = Math::PlanePath::CoprimeColumns::_totient_count($x);
    if ($c != $n) {
      die "x=$x  tot $c step $n\n";
    }
    printf "%d %d   %s\n", $x, $n, join(',',@list);
  }
  exit 0;
}




sub _coprime {
  my ($x, $y) = @_;
  ### _coprime(): "$x,$y"
  if ($x < $y) {
    ($x,$y) = ($y,$x);
  }
  for (;;) {
    if ($y <= 0) {
      return 0;
    }
    if ($y == 1) {
      return 1;
    }
    $x %= $y;
    ($x,$y) = ($y,$x);
  }
}
