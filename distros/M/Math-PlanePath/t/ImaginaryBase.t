#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
plan tests => 311;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::ImaginaryBase;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::ImaginaryBase::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ImaginaryBase->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ImaginaryBase->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ImaginaryBase->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ImaginaryBase->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::ImaginaryBase->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# random points

{
  my $radix = 2 + int(rand(20));
  my $path = Math::PlanePath::ImaginaryBase->new (radix => $radix);
  for (1 .. 100) {
    my $bits = int(rand(25));         # 0 to 25, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    if (! defined $rev_n) { $rev_n = 'undef'; }
    ok ($rev_n, $n,
        "xy_to_n($x,$y) radix=$radix reverse to expect n=$n, got $rev_n");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1,
        "rect_to_n_range() radix=$radix reverse n=$n cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1,
        "rect_to_n_range() radix=$radix reverse n=$n cf got n_hi=$n_hi");
  }
}

#------------------------------------------------------------------------------
# cf A039724 negabinary
#    A039723 negadecimal

sub index_to_negaradix {
  my ($n, $radix) = @_;
  my $power = 1;
  my $ret = 0;
  while ($n) {
    my $digit = $n % $radix;  # low to high
    $n = int($n/$radix);
    $ret += $power * $digit;
    $power *= -$radix;
  }
  return $ret;
}

{
  require Math::PlanePath::ZOrderCurve;
  my $bad = 0;
  foreach my $radix (2, 3, 5, 10, 16) {
    my $zorder = Math::PlanePath::ZOrderCurve->new (radix => $radix);
    my $imbase = Math::PlanePath::ImaginaryBase->new (radix => $radix);
    foreach my $n (0 .. 256) {
      my ($zx,$zy) = $zorder->n_to_xy($n);
      my $nx = index_to_negaradix($zx,$radix);
      my $ny = index_to_negaradix($zy,$radix);
      my $in = $imbase->xy_to_n($nx,$ny);
      if ($n != $in) {
        $bad = 1;
      }
    }
  }
  ok ($bad, 0);
}

exit 0;
