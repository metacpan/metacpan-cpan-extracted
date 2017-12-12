#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 269;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;

use Math::PlanePath::GcdRationals;
*_gcd = \&Math::PlanePath::GcdRationals::_gcd;

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::ChanTree;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::ChanTree::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ChanTree->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ChanTree->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ChanTree->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ChanTree->new;
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
  my $path = Math::PlanePath::ChanTree->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 0, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::ChanTree->parameter_info_list;
  ok (join(',',@pnames), 'k,n_start');
}
{
  my $path = Math::PlanePath::ChanTree->new;
  ok ($path->tree_num_children_minimum, 3, 'tree_num_children_minimum()');
  ok ($path->tree_num_children_maximum, 3, 'tree_num_children_maximum()');
}
{
  my $path = Math::PlanePath::ChanTree->new (k => 123);
  ok ($path->tree_num_children_minimum, 123, 'tree_num_children_minimum()');
  ok ($path->tree_num_children_maximum, 123, 'tree_num_children_maximum()');
}

#------------------------------------------------------------------------------

{
  my @data = (
              [ { k => 8, reduced => 1, n_start => 1 },
                [ 11,  5,6 ],  # 10/12 reduced
              ],
              [ { k => 3, reduced => 1, n_start => 1 },
                # [ 0,  1,84 ],
              ],
              [ { k => 3, reduced => 0, n_start => 1 },
                [ 1,  1,2 ],
                [ 2,  2,1 ],

                [ 3,  1,4 ],
                [ 4,  4,5 ],
                [ 5,  5,2 ],
                [ 6,  2,5 ],
                [ 7,  5,4 ],
                [ 8,  4,1 ],

                [ 9,  1,6 ],
              ],
              [ { k => 4, reduced => 0, n_start => 1 },
                [ 1,  1,2 ],
                [ 2,  2,2 ],
                [ 3,  2,1 ],

                [ 4,  1,4 ],    # under 1
                [ 5,  4,6 ],
                [ 6,  6,5 ],
                [ 7,  5,2 ],

                [ 8,  2,6 ],    # under 2
                [ 9,  6,8 ],
                [ 10, 8,6 ],
                [ 11, 6,2 ],

                [ 12, 2,5 ],    # under 3
                [ 13, 5,6 ],
                [ 14, 6,4 ],
                [ 15, 4,1 ],

                [ 16, 1,6 ],
                [ 17, 6,10 ],   # 1,2 -> 1,4 -> 6,10

                [ 30, 14,9 ],   # 1,2 -> 5,2 -> 14,9

              ],
              [ { k => 4, reduced => 1, n_start => 1 },
                [ 1,  1,2 ],
                [ 2,  1,1 ], # 2,2
                [ 3,  2,1 ],

                [ 4,  1,4 ],
                [ 5,  2,3 ], # 4,6
                [ 6,  6,5 ],
                [ 7,  5,2 ],
                [ 8,  1,3 ], # 2,6
              ],
             );
  foreach my $group (@data) {
    my ($options, @elems) = @$group;
    my $path = Math::PlanePath::ChanTree->new (%$options);
    my $k = $options->{'k'};
    my $n_start = $options->{'n_start'};
    my $reduced = $options->{'reduced'} || 0;

    foreach my $elem (@elems) {
      my ($n, $want_x, $want_y) = @$elem;
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      ok ($got_x, $want_x, "k=$k,r=$reduced x at n=$n");
      ok ($got_y, $want_y, "k=$k,r=$reduced y at n=$n");
    }

    foreach my $elem (@elems) {
      my ($want_n, $x, $y) = @$elem;
      next unless $want_n==int($want_n);
      my $got_n = $path->xy_to_n ($x, $y);
      ok ($got_n, $want_n, "k=$k,r=$reduced xy_to_n($x,$y) sample");
    }

    foreach my $elem (@elems) {
      my ($n, $x, $y) = @$elem;
      if ($n == int($n)) {
        my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
        ok ($got_nlo == $n_start, 1, "rect_to_n_range() got_nlo=$got_nlo at n=$n,x=$x,y=$y");
        ok ($got_nhi >= $n, 1, "rect_to_n_range(0,0,$x,$y) got_nhi=$got_nhi at n=$n,x=$x,y=$y");

        ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
        ok ($got_nlo <= $n, 1, "rect_to_n_range() got_nlo=$got_nlo at n=$n,x=$x,y=$y");
        ok ($got_nhi >= $n, 1, "rect_to_n_range() got_nhi=$got_nhi at n=$n,x=$x,y=$y");
      }
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
