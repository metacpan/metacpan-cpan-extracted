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
use List::Util 'min', 'max';

use Test;
plan tests => 28;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::DragonCurve;

#------------------------------------------------------------------------------
# Lmin,Lmax Wmin,Wmax claimed in the pod

{
  my $path = Math::PlanePath::DragonCurve->new;
  my $xmax = 0;
  my $xmin = 0;
  my $ymax = 0;
  my $ymin = 0;
  my $n = 0;
  foreach my $level (2, 4, 8, 10, 12, 14, 16) {
    my $k = $level / 2;
    my $Nlevel = 2**$level;
    for ( ; $n <= $Nlevel; $n++) {
      my ($x,$y) = $path->n_to_xy($n);
      $xmax = max ($xmax, $x);
      $xmin = min ($xmin, $x);
      $ymax = max ($ymax, $y);
      $ymin = min ($ymin, $y);
    }

    my $Lmax = $ymax;
    my $Lmin = $ymin;
    my $Wmax = $xmax;
    my $Wmin = $xmin;
    foreach (2 .. $k) {
      (    $Lmax,  $Lmin,  $Wmax, $Wmin)
        = (-$Wmin, -$Wmax, $Lmax, $Lmin);   # rotate -90
    }

    my $calc_Lmax = calc_Lmax($k);
    my $calc_Lmin = calc_Lmin($k);
    my $calc_Wmax = calc_Wmax($k);
    my $calc_Wmin = calc_Wmin($k);

    ok ($calc_Lmax, $Lmax, "Lmax k=$k");
    ok ($calc_Lmin, $Lmin, "Lmin k=$k");
    ok ($calc_Wmax, $Wmax, "Wmax k=$k");
    ok ($calc_Wmin, $Wmin, "Wmin k=$k");
  }
}

sub calc_Lmax {
  my ($k) = @_;
  #     Lmax = (7*2^k - 4)/6 if k even
  #            (7*2^k - 2)/6 if k odd
  if ($k & 1) {
    return (7*2**$k - 2) / 6;
  } else {
    return (7*2**$k - 4) / 6;
  }
}
sub calc_Lmin {
  my ($k) = @_;
  #     Lmin = - (2^k - 1)/3 if k even
  #            - (2^k - 2)/3 if k odd
  if ($k & 1) {
    return - (2**$k - 2) / 3;
  } else {
    return - (2**$k - 1) / 3;
  }
}
sub calc_Wmax {
  my ($k) = @_;
  #     Wmax = (2*2^k - 1) / 3 if k even
  #            (2*2^k - 2) / 3 if k odd
  if ($k & 1) {
    return (2*2**$k - 1) / 3;
  } else {
    return (2*2**$k - 2) / 3;
  }
}
sub calc_Wmin {
  my ($k) = @_;
  return calc_Lmin($k);
}

#------------------------------------------------------------------------------
exit 0;
