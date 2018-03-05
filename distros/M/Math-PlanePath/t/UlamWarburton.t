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
plan tests => 1071;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::UlamWarburton;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::UlamWarburton::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::UlamWarburton->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::UlamWarburton->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::UlamWarburton->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::UlamWarburton->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::UlamWarburton->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 1);
    ok ($n_hi, 5); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 1);
    ok ($n_hi, 21); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 1);
    ok ($n_hi, 85); }
}
{
  my $path = Math::PlanePath::UlamWarburton->new (parts => '2');
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 1);
    ok ($n_hi, 4); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 1);
    ok ($n_hi, 14); }
}
{
  my $path = Math::PlanePath::UlamWarburton->new (parts => '1');
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 1);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 1);
    ok ($n_hi, 9); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 1);
    ok ($n_hi, 29); }
}

# depth=2-1=1 is level=0
# depth=4-1=3 is level=1
# depth=8-1=7 is level=2
#
foreach my $parts ('4','2','1') {
  foreach my $n_start (1
                       # , -10, 39
                      ) {
    my $path = Math::PlanePath::UlamWarburton->new (parts => $parts,
                                                    n_start => $n_start);
    foreach my $level (0 .. 6) {
      my ($n_lo,$n_hi) = $path->level_to_n_range($level);
      my $depth = 2**($level+1) - 1;
      my $n_end = $path->tree_depth_to_n_end($depth);
      ok ($n_hi,$n_end, "parts=$parts n_start=$n_start depth=$depth level=$level");
    }
  }
}

#------------------------------------------------------------------------------
# tree_depth_to_n(), tree_n_to_depth()

# 25
# 23
# 19   22
# 15        61
# 11   14   18   60
#  9        59        57
#  5    8        58   17   56
#  3         7        13        19
#  1    2    4    6   10   12   16   18  24

# 1, 3, 5, 9, 11, 15, 19, 29, 31, 35, 39, 49, 53, 63, 73, 101, 103, 107,
# 2  4  6 10  12  16  20  30

{
  my @groups = ([ [ parts => 1 ],
                  [ 8, 30 ], # +1+1

                  [ 0,  1 ], #
                  [ 1,  2 ], # +1+1
                  [ 2,  4 ], # +1+1
                  [ 3,  6 ], # +3+1

                  [ 4, 10 ], # +1+1
                  [ 5, 12 ], # +3+1
                  [ 6, 16 ], # +3+1
                  [ 7, 20 ], # +9+1

                  [ 8, 30 ], # +1+1
                  [ 9, 32 ],

                  [ 15, 74 ],
                ],

                [ [ ], # default parts=4
                  [ 0,  1 ], # +1
                  [ 1,  2 ], # +4
                  [ 2,  6 ], # +4
                  [ 3, 10 ], # +12
                  [ 4, 22 ], # +4
                  [ 5, 26 ], # +12
                  [ 6, 38 ], # +12
                  [ 7, 50 ], # +36
                  [ 8, 86 ], # +4
                  [ 9, 90 ],
                ],
               );
  foreach my $n_start (1, 0, 37, -3) {
    foreach my $group (@groups) {
      my ($options, @data) = @$group;
      my $path = Math::PlanePath::UlamWarburton->new (@$options,
                                                      n_start => $n_start);
      foreach my $elem (@data) {
        my ($depth, $n) = @$elem;
        $n = $n - 1 + $n_start;  # table is in N=1 basis, adjust
        {
          my $want_n = $n;
          my $got_n = $path->tree_depth_to_n ($depth);
          ok ($got_n, $want_n, "n_start=$n_start tree_depth_to_n() depth=$depth");
        }
        {
          my $want_depth = $depth;
          my $got_depth = $path->tree_n_to_depth ($n);
          ok ($got_depth, $want_depth, "@$options n_start=$n_start tree_n_to_depth() n=$n");
        }
        if ($depth > 0) {
          my $want_depth = $depth - 1;
          my $got_depth = $path->tree_n_to_depth ($n-1);
          ok ($got_depth, $want_depth, "@$options n_start=$n_start tree_n_to_depth() n=$n");
        }
      }
    }
  }
}

#------------------------------------------------------------------------------
# tree_n_children()
{
  my @data = ([ 1, '2,3,4,5' ],

              [ 2,  '6' ],
              [ 3,  '7' ],
              [ 4,  '8' ],
              [ 5,  '9' ],

              [ 6,  '10,11,12' ],
              [ 7,  '13,14,15' ],
              [ 8,  '16,17,18' ],
              [ 9,  '19,20,21' ],
             );
  my $path = Math::PlanePath::UlamWarburton->new;
  foreach my $elem (@data) {
    my ($n, $want_n_children) = @$elem;
    my $got_n_children = join(',',$path->tree_n_children($n));
    ok ($got_n_children, $want_n_children, "tree_n_children($n)");
  }
}

#------------------------------------------------------------------------------
# tree_n_parent()
{
  my @data = ([ 1, undef ],

              [ 2,  1 ],
              [ 3,  1 ],
              [ 4,  1 ],
              [ 5,  1 ],

              [ 6,  2 ],
              [ 7,  3 ],
              [ 8,  4 ],
              [ 9,  5 ],

              [ 10,  6 ],
              [ 11,  6 ],
              [ 12,  6 ],
              [ 13,  7 ],
              [ 14,  7 ],
              [ 15,  7 ],
             );
  my $path = Math::PlanePath::UlamWarburton->new;
  foreach my $elem (@data) {
    my ($n, $want_n_parent) = @$elem;
    my $got_n_parent = $path->tree_n_parent ($n);
    ok ($got_n_parent, $want_n_parent);
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::UlamWarburton->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# random points

{
  my $path = Math::PlanePath::UlamWarburton->new;
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
# x,y coverage

{
  my $path = Math::PlanePath::UlamWarburton->new;
  foreach my $x (-10 .. 10) {
    foreach my $y (-10 .. 10) {
      my $n = $path->xy_to_n ($x,$y);
      next if ! defined $n;
      my ($nx,$ny) = $path->n_to_xy ($n);

      ok ($nx, $x, "xy_to_n($x,$y)=$n then n_to_xy() reverse");
      ok ($ny, $y, "xy_to_n($x,$y)=$n then n_to_xy() reverse");
    }
  }
}

exit 0;
