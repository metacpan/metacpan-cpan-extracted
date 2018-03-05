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
plan tests => 191;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::CubicBase;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::CubicBase::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::CubicBase->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::CubicBase->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::CubicBase->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::CubicBase->new;
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
  my $path = Math::PlanePath::CubicBase->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::CubicBase->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
}
{
  my $path = Math::PlanePath::CubicBase->new (radix => 4);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 15); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 63); }
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ 3,
                [ 0, 0,0 ],
                [ 1, 2,0 ],   # level=0
                [ 2, 4,0 ],

                [ 3, -1,1 ],   # level=1
                [ 4, 1,1 ],
                [ 5, 3,1 ],

                [ 6, -2,2 ],
                [ 7, 0,2 ],
                [ 8, 2,2 ],

                [ 9, -3,-3 ],  # level=2
                [ 27, 6,0 ],   # level=3

                [ 81, -9,9 ],   # level=4
                [ 243, -9,-9 ],   # level=5
              ],

              [ 5,
                [ 0, 0,0 ],
                [ 1, 2,0 ],   # level=0
                [ 2, 4,0 ],
                [ 3, 6,0 ],
                [ 4, 8,0 ],

                [ 5, -1,1 ],   # level=1
                [ 6, 1,1 ],
                [ 7, 3,1 ],
                [ 8, 5,1 ],
                [ 9, 7,1 ],

                [ 10, -2,2 ],
                [ 11, 0,2 ],
                [ 12, 2,2 ],
                [ 13, 4,2 ],
                [ 14, 6,2 ],

                [ 24, 4,4 ],

                [ 25, -5,-5 ],   # level=2
                [ 125, 10,0 ],   # level=3    0deg

                [ 625, -25,25 ],   # level=4   120deg
                [ 3125, -25,-25 ],   # level=5  240deg

                # [ .25,   .# 25, 0 ],
                # [ 1.25,  1, .25 ],
                # [ 2.25,  0.75, 1 ],
                # [ 3.25,  0, 1.25 ],
                #
                # [ 4.25,  0, 2.25 ],
                # [ 5.25,  .25, 3 ],
                # [ 6.25,  1, 2.75 ],
                # [ 7.25,  1.25, 2 ],
                #
                # [ 8.25,  2, 2.25 ],
                # [ 9.25,  2.25, 3 ],
                # [ 10.25,  3, 2.75 ],
                # [ 11.25,  3, 1.75 ],
                #
                # [ 12.25,  2.75, 1 ],
                # [ 13.25,  2, .75 ],
                # [ 14.25,  2.25, 0 ],
                # [ 15.25,  3.25, 0 ],
                #
                # [   19.25,  5.25, 0 ],
                # [   37.25,  7, 4.25 ],
                #
                # [   31.25,  4, 3.25 ],
                # [  127.25,  7.25, 8 ],
                #
                # [   63.25,  0, 7.25 ],
                # [  255.25,  15.25, 0 ],
                # [ 1023.25,  0, 31.25 ],
              ]
             );
  foreach my $elem (@data) {
    my ($radix, @points) = @$elem;
    my $path = Math::PlanePath::CubicBase->new (radix => $radix);

    foreach my $point (@points) {
      my ($n, $want_x, $want_y) = @$point;
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
      if ($got_y == 0) { $got_y = 0 }
      ok ($got_x, $want_x, "n_to_xy() radix=$radix x at n=$n");
      ok ($got_y, $want_y, "n_to_xy() radix=$radix y at n=$n");
    }

    foreach my $point (@points) {
      my ($want_n, $x, $y) = @$point;
      next unless $want_n==int($want_n);
      my $got_n = $path->xy_to_n ($x, $y);
      ok ($got_n, $want_n, "n at x=$x,y=$y");
    }

    foreach my $point (@points) {
      my ($n, $x, $y) = @$point;
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      next unless $n==int($n);
      ok ($got_nlo <= $n, 1,
          "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1,
          "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
    }
  }
}



#------------------------------------------------------------------------------
# X axis claimed in the POD

# wrong

# =head2 Axis Values
# 
# In the default radix=2 the N=0,1,8,9,etc on the positive X axis are those
# integers with zeros at two of every three bits, starting from zeros in the
# second and third least significant bit.
# 
#     X axis Ns = binary ..._00_00_00_     with _ either 0 or 1
#     in octal, digits 0,1 only
# 
# For a radix other than binary the pattern is the same.  Each "_" is any
# digit of the given radix, and each 0 must be 0.

# foreach my $radix (2, 3, 4) {
#   my $path = Math::PlanePath::CubicBase->new (radix => $radix);
#   foreach my $x (0 .. 10) {
#     my $path_n = $path->xy_to_n (2*$x,0);
#     my $calc_n = calc_x_to_n($x,$radix);
#     ok ($calc_n, $path_n,
#        "calc_x_to_n() radix=$radix at x=$x");
#   }
# }
# 
# sub calc_x_to_n {
#   my ($x, $radix) = @_;
#   my $n = 0;
#   my $power = 1;
#   my $grow = 0;
#   $x = index_to_negaradix($x,$radix*$radix);
#   foreach my $xdigit (digit_split_lowtohigh($x,$radix)) {
#     $n += $power*$xdigit;
#     $power *= $radix*$radix*$radix;
#     # if ($grow ^= 1) {
#     #   $power *= $radix*$radix;
#     # }
#   }
#   return $n;
# }
# sub index_to_negaradix {
#   my ($n, $radix) = @_;
#   my $power = 1;
#   my $ret = 0;
#   while ($n) {
#     my $digit = $n % $radix;  # low to high
#     $n = int($n/$radix);
#     $ret += $power * $digit;
#     $power *= -$radix;
#   }
#   return $ret;
# }

exit 0;
