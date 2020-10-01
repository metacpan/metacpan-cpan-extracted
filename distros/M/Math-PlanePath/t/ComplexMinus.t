#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
plan tests => 473;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::ComplexMinus;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::ComplexMinus::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ComplexMinus->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ComplexMinus->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ComplexMinus->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ComplexMinus->new;
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
  my $path = Math::PlanePath::ComplexMinus->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 1, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::ComplexMinus->parameter_info_list;
  ok (join(',',@pnames), 'realpart');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              # [ 0, 0,0 ],
              # [ 1, 1,0 ],
              # [ 2, 1,1 ],
              # [ 3, 0,1 ],
              # [ 4, 0,2 ],
              #
              # [ 0.25,  0.25, 0 ],
              # [ 1.25,  1, 0.25 ],
              # [ 2.25,  0.75, 1 ],
              # [ 3.25,  0, 1.25 ],

              # claimed in the POD
              [ 0x1D0,  4,0 ],
              [ 0x1D1,  5,0 ],
              [ 0x1DC,  6,0 ],
              [ 0x1DD,  7,0 ],
              [ 0x1C0,  8,0 ],
              [ 0x1C1,  9,0 ],
              [ 0x1CC, 10,0 ],
              [ 0x1CD, 11,0 ],
              [ 0x110, 12,0 ],
              [ 0x111, 13,0 ],
              [ 0x11C, 14,0 ],
              [ 0x11D, 15,0 ],
              [ 0x100, 16,0 ],
              [ 0x101, 17,0 ],
              [ 0x10C, 18,0 ],
              [ 0x10D, 19,0 ],
              [ 0xCD0, 20,0 ],
              [ 0xCD1, 21,0 ],
              [ 0xCDC, 22,0 ],
              [ 0xCDD, 23,0 ],

             );
  my $path = Math::PlanePath::ComplexMinus->new;
  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
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
    {
      $n = int($n);
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
    }
  }
}


#------------------------------------------------------------------------------
# random rect_to_n_range()

foreach my $realpart (1 .. 6) {
  my $path = Math::PlanePath::ComplexMinus->new (realpart => $realpart);

  for (1 .. 20) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits));  # 0 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);

    my $rev_n = $path->xy_to_n ($x,$y);
    ok (defined $rev_n, 1, "xy_to_n($x,$y) realpart=$realpart reverse n, got undef");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1,
        "rect_to_n_range() realpart=$realpart n=$n at xy=$x,$y cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1,
        "rect_to_n_range() realpart=$realpart n=$n at xy=$x,$y cf got n_hi=$n_hi");
  }
}


#------------------------------------------------------------------------------
# many rect_to_n_range()

if (0) {
  my $bad = 0;
  foreach my $realpart (1 .. 6) {
    my $path = Math::PlanePath::ComplexMinus->new (realpart => $realpart);

    foreach my $n (1 .. 500000) {
      my ($x,$y) = $path->n_to_xy ($n);

      my $rev_n = $path->xy_to_n ($x,$y);
      if (! defined $rev_n || $rev_n != $n) {
        MyTestHelpers::diag ("xy_to_n($x,$y) realpart=$realpart reverse n, got ",$rev_n);
        $bad = 1;
      }

      my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
      if ($n_lo > $n) {
        MyTestHelpers::diag ("rect_to_n_range() realpart=$realpart n=$n at xy=$x,$y cf got n_lo=$n_lo");
        $bad = 1;
      }
      if ($n_hi < $n) {
        MyTestHelpers::diag ("rect_to_n_range() realpart=$realpart n=$n at xy=$x,$y cf got n_hi=$n_hi");
        $bad = 1;
      }
    }
  }
  ok ($bad, 0);
}


exit 0;
