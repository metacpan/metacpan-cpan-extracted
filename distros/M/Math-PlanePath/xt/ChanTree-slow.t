#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2019 Kevin Ryde

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

use 5.004;
use strict;
use Test;
plan tests => 22;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::ChanTree;

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;

use Math::PlanePath::GcdRationals;
*_gcd = \&Math::PlanePath::GcdRationals::_gcd;

#------------------------------------------------------------------------------
# n_to_xy() reversal

{
  require Math::PlanePath::GcdRationals;
  foreach my $k (3 .. 7) {
    foreach my $reduced (0, 1) {
      my $path = Math::PlanePath::ChanTree->new (k => $k,
                                                 reduced => $reduced);
      foreach my $n ($path->n_start .. 500) {
        my ($x,$y) = $path->n_to_xy($n);
        my $rev = $path->xy_to_n($x,$y);
        if (! defined $rev || $rev != $n) {
          $rev = (defined $rev ? $rev : 'undef');
          die "k=$k reduced=$reduced n_to_xy($n)=$x,$y but reverse xy_to_n($x,$y) is rev=$rev";
        }

        if ($reduced) {
          my $gcd = Math::PlanePath::GcdRationals::_gcd($x,$y);
          if ($gcd > 1) {
            die "k=$k reduced=$reduced n_to_xy($n)=$x,$y common factor $gcd";
          }
        }
      }
      ok ($k, $k);
    }
  }
}

#------------------------------------------------------------------------------
# block of points

eval 'use Math::BigInt try=>q{GMP}; 1'
  || eval 'use Math::BigInt; 1'
  || die;
{
  my $size = 100;
  foreach my $k (2 .. 7) {
    foreach my $reduced (0, 1) {
      my $path = Math::PlanePath::ChanTree->new (k => $k,
                                                 reduced => $reduced);
      my %seen_n;
      foreach my $x (1 .. $size) {
        foreach my $y (1 .. $size) {
          my $n = $path->xy_to_n(Math::BigInt->new($x),
                                 Math::BigInt->new($y));

          if ($reduced) {
            if (is_reduced_xy($k,$x,$y)) {
              if (! defined $n) {
                die "k=$k reduced=$reduced xy_to_n($x,$y) is reduced point but n=undef";
              }
            } else {
              if (defined $n) {
                my $gcd = Math::PlanePath::GcdRationals::_gcd($x,$y);
                die "k=$k reduced=$reduced xy_to_n($x,$y) is not reduced point (gcd=$gcd) but still have n=$n";
              }
            }
          }

          if (defined $n) {
            if ($seen_n{$n}) {
              die "k=$k xy_to_n($x,$y) is n=$n, but previously xy_to_n($seen_n{$n}) was n=$n";
            }
            $seen_n{$n} = "$x,$y";
          }
        }
      }
      ok ($k, $k);
    }
  }
}
sub is_reduced_xy {
  my ($k, $x, $y) = @_;
  if (! _coprime($x,$y)) {
    return 0;
  }
  if (($k & 1) && is_both_odd($x,$y)) {
    return 0;
  }
  return 1;
}
sub is_both_odd {
  my ($x, $y) = @_;
  return ($x % 2) && ($y % 2);
}


#------------------------------------------------------------------------------
exit 0;
