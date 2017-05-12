#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 355;;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Math::PlanePath::ToothpickReplicate;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 18;
  ok ($Math::PlanePath::ToothpickReplicate::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ToothpickReplicate->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ToothpickReplicate->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ToothpickReplicate->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ToothpickReplicate->new;
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
  my $path = Math::PlanePath::ToothpickReplicate->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 1, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::ToothpickReplicate->parameter_info_list;
  ok (join(',',@pnames), 'parts');
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::ToothpickReplicate->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 10); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 42); }
}
{
  my $path = Math::PlanePath::ToothpickReplicate->new (parts => 1);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 1); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 9); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 41); }
}
{
  my $path = Math::PlanePath::ToothpickReplicate->new (parts => 2);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 4); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 20); }
}
{
  my $path = Math::PlanePath::ToothpickReplicate->new (parts => 3);
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 7); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 31); }
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ [ parts => 3 ],

                [ 0,    0,0 ],
                [ 1,    0,1 ],

                [ 2,    0,-1 ], # quad 3
                [ 3,    1,-1 ],

                [ 4,    1,1 ], # quad 1
                [ 5,    1,2 ],

                [ 6,   -1,1 ], # quad 2
                [ 7,   -1,2 ],

                # [ 8,    2,2 ], # A
                # [ 9,    2,3 ], # B
                #
                # [ 10,   2,1 ], # 1
                # [ 11,   3,1 ],
                # [ 10,   3,3 ], # 2
                # [ 11,   3,4 ],
                # [ 12,   1,3 ], # 3
                # [ 13,   1,4 ],
                #
                # [ 11,   4,4 ], # A
                # [ 12,   4,5 ], # B
                #
                # # part 1
                # [ 13,   4,3 ], # 0
                # [ 14,   5,3 ],
                # [ 15,   5,2 ], # A
                # [ 16,   6,2 ], # B
                # [ 17,   4,2 ], # 1
                # [ 18,   4,1 ],
                # [ 19,   6,1 ], # 2
                # [ 20,   7,1 ],
                # [ 21,   6,3 ], # 3
                # [ 22,   7,3 ],
                #
                # # part 2
                # [ 23,   5,5 ], # 0
                # [ 24,   5,6 ], # 0
                #
                # # part 3
                # [ 33,   3,5 ], # 0
                # [ 34,   3,6 ], # 0
                # [ 35,   2,6 ], # A
                # [ 36,   2,7 ], # B
                # [ 37,   2,5 ], # 1
                # [ 38,   1,5 ],
                # [ 39,   1,7 ], # 2
                # [ 40,   1,8 ],
                # [ 41,   3,7 ], # 3
                # [ 42,   3,8 ],
              ],

              [ [ parts => 4 ],

                [ 0,    0,0 ],
                [ 1,    0,1 ],
                [ 2,    0,-1 ],

                [ 3,    1,1 ], # quad 0
                [ 4,    1,2 ],

                [ 5,   -1,1 ], # quad 1
                [ 6,   -1,2 ],

                [ 7,   -1,-1 ], # quad 2
                [ 8,   -1,-2 ],

                [ 9,   1,-1 ], # quad 3
                [ 10,  1,-2 ],

                # [ 6,    2,2 ], # A
                # [ 7,    2,3 ], # B
                #
                # [ 8,    2,1 ], # 1
                # [ 9,    3,1 ],
                # [ 10,   3,3 ], # 2
                # [ 11,   3,4 ],
                # [ 12,   1,3 ], # 3
                # [ 13,   1,4 ],
                #
                # [ 11,   4,4 ], # A
                # [ 12,   4,5 ], # B
                #
                # # part 1
                # [ 13,   4,3 ], # 0
                # [ 14,   5,3 ],
                # [ 15,   5,2 ], # A
                # [ 16,   6,2 ], # B
                # [ 17,   4,2 ], # 1
                # [ 18,   4,1 ],
                # [ 19,   6,1 ], # 2
                # [ 20,   7,1 ],
                # [ 21,   6,3 ], # 3
                # [ 22,   7,3 ],
                #
                # # part 2
                # [ 23,   5,5 ], # 0
                # [ 24,   5,6 ], # 0
                #
                # # part 3
                # [ 33,   3,5 ], # 0
                # [ 34,   3,6 ], # 0
                # [ 35,   2,6 ], # A
                # [ 36,   2,7 ], # B
                # [ 37,   2,5 ], # 1
                # [ 38,   1,5 ],
                # [ 39,   1,7 ], # 2
                # [ 40,   1,8 ],
                # [ 41,   3,7 ], # 3
                # [ 42,   3,8 ],
              ],

              [ [ parts => 1 ],
                [ 0,    1,1 ],
                [ 1,    1,2 ],
                [ 2,    2,2 ], # A
                [ 3,    2,3 ], # B

                [ 4,    2,1 ], # 1
                [ 5,    3,1 ],
                [ 6,    3,3 ], # 2
                [ 7,    3,4 ],
                [ 8,    1,3 ], # 3
                [ 9,    1,4 ],

                [ 10,   4,4 ], # A
                [ 11,   4,5 ], # B

                # part 1
                [ 12,   4,3 ], # 0
                [ 13,   5,3 ],
                [ 14,   5,2 ], # A
                [ 15,   6,2 ], # B
                [ 16,   4,2 ], # 1
                [ 17,   4,1 ],
                [ 18,   6,1 ], # 2
                [ 19,   7,1 ],
                [ 20,   6,3 ], # 3
                [ 21,   7,3 ],

                # part 2
                [ 22,   5,5 ], # 0
                [ 23,   5,6 ], # 0
                [ 24,   6,6 ], # 0

                # part 3
                [ 32,   3,5 ], # 0
                [ 33,   3,6 ], # 0
                [ 34,   2,6 ], # A
                [ 35,   2,7 ], # B
                [ 36,   2,5 ], # 1
                [ 37,   1,5 ],
                [ 38,   1,7 ], # 2
                [ 39,   1,8 ],
                [ 40,   3,7 ], # 3
                [ 41,   3,8 ],
              ],
             );
  foreach my $elem (@data) {
    my ($options, @points) = @$elem;
    my $path = Math::PlanePath::ToothpickReplicate->new (@$options);
    foreach my $point (@points) {
      my ($n, $x, $y) = @$point;
      {
        # n_to_xy()
        my ($got_x, $got_y) = $path->n_to_xy ($n);
        if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
        if ($got_y == 0) { $got_y = 0 }
        ok ($got_x, $x, "n_to_xy($n) X ".join(',',@$options));
        ok ($got_y, $y, "n_to_xy($n) Y ".join(',',@$options));
      }
      # if ($n==int($n)) {
      #   # xy_to_n()
      #   my $got_n = $path->xy_to_n ($x, $y);
      #   ok ($got_n, $n, "xy_to_n() n at x=$x,y=$y");
      # }

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
}


# #------------------------------------------------------------------------------
# # N on leading diagonal
# 
# {
#   my $path = Math::PlanePath::ToothpickReplicate->new;
#   foreach my $i (1 .. 32) {
#     my $n = $path->xy_to_n($i,$i);
#     printf "%b %d %b %b\n", $i, $n,$n, 3*$n;
#   }
# }
# exit 0;


exit 0;
