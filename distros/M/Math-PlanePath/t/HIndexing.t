#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
plan tests => 466;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::HIndexing;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 129;
  ok ($Math::PlanePath::HIndexing::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::HIndexing->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::HIndexing->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::HIndexing->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::HIndexing->new;
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
  my $path = Math::PlanePath::HIndexing->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ 0,    0,0 ],
              [ 1,    0,1 ],
              [ 2,    0,2 ],
              [ 3,    0,3 ],
              [ 4,    1,3 ],
              [ 5,    1,2 ],
              [ 6,    2,2 ],
              [ 7,    2,3 ],
             );
  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    my $path = Math::PlanePath::HIndexing->new;
    {
      # n_to_xy()
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
      if ($got_y == 0) { $got_y = 0 }
      ok ($got_x, $x, "n_to_xy() x at n=$n");
      ok ($got_y, $y, "n_to_xy() y at n=$n");
    }
    if ($n==int($n)) {
      # xy_to_n()
      my $got_n = $path->xy_to_n ($x, $y);
      ok ($got_n, $n, "xy_to_n() n at x=$x,y=$y");
    }

    if ($n == int($n)) {
      {
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
        ok ($got_nlo <= $n, 1, "rect_to_n_range(0,0,$x,$y) for n=$n, got_nlo=$got_nlo");
        ok ($got_nhi >= $n, 1, "rect_to_n_range(0,0,$x,$y) for n=$n, got_nhi=$got_nhi");
      }
      {
        $n = int($n);
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
        ok ($got_nlo <= $n, 1, "rect_to_n_range($x,$y,$x,$y) for n=$n, got_nlo=$got_nlo");
        ok ($got_nhi >= $n, 1, "rect_to_n_range($x,$y,$x,$y) for n=$n, got_nhi=$got_nhi");
      }
    }
  }
}


#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my $path = Math::PlanePath::HIndexing->new;
  my ($n_lo, $n_hi) = $path->rect_to_n_range(0,0, 0,0);
  ok ($n_lo == 0, 1, "rect_to_n_range() 0,0  n_lo=$n_lo");
  ok ($n_hi >= 0, 1, "rect_to_n_range() 0,0  n_hi=$n_hi");
}


#------------------------------------------------------------------------------
# random fracs

{
  my $path = Math::PlanePath::HIndexing->new;
  for (1 .. 20) {
    my $bits = int(rand(20));         # 0 to 20, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x1,$y1) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+1);

    foreach my $frac (0.25, 0.5, 0.75) {
      my $want_xf = $x1 + ($x2-$x1)*$frac;
      my $want_yf = $y1 + ($y2-$y1)*$frac;

      my $nf = $n + $frac;
      my ($got_xf,$got_yf) = $path->n_to_xy ($nf);

      ok ($got_xf, $want_xf, "n_to_xy($n) frac $frac, x");
      ok ($got_yf, $want_yf, "n_to_xy($n) frac $frac, y");
    }
  }
}

#------------------------------------------------------------------------------
# random points

{
  my $path = Math::PlanePath::HIndexing->new;
  for (1 .. 50) {
    my $bits = int(rand(20));         # 0 to 20, inclusive
    my $n = int(rand(2**$bits)) + 1;  # 1 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    if (! defined $rev_n) { $rev_n = 'undef'; }
    ok ($rev_n, $n, "xy_to_n($x,$y) reverse to expect n=$n, got $rev_n");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1, "rect_to_n_range() reverse n=$n cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1, "rect_to_n_range() reverse n=$n cf got n_hi=$n_hi");
  }
}

#------------------------------------------------------------------------------
# diagonal

{
  my $path = Math::PlanePath::HIndexing->new;
  for (my $y = 0; $y < 256; $y += 2) {
    my $want_n = $path->xy_to_n ($y, $y);
    my $got_n = duplicate_bits($y);
    ok ($got_n, $want_n);
  }

  sub duplicate_bits {
    my ($k) = @_;
    my $str = sprintf '%b', $k;
    $str =~ s/(.)/$1$1/g;
    return oct("0b$str") / 2;
  }
}

exit 0;
