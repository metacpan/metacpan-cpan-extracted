#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
plan tests => 625;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::GcdRationals;
my @pairs_order_choices
  = @{Math::PlanePath::GcdRationals->parameter_info_hash
      ->{'pairs_order'}->{'choices'}};

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::GcdRationals::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::GcdRationals->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::GcdRationals->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::GcdRationals->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::GcdRationals->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# rect_to_n_range() various

{
  my @data = ([ 0,0, 19,5,  1,217 ], 
              [ 7,7, 8,8,   35,93 ],   # 35,93
              [ 19,2, 19,4, 200,217 ], # 200,217,205
              [ 5,3, 5,7,   19,30 ],   # 19,30,20,26
             );
  my $path = Math::PlanePath::GcdRationals->new;
  foreach my $elem (@data) {
    my ($x1,$y1, $x2,$y2, $want_nlo, $want_nhi) = @$elem;
    my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
    ok ($got_nlo <= $want_nlo,
        1,
        "got_nlo=$got_nlo  want_nlo=$want_nlo");
    ok ($got_nhi >= $want_nhi,
        1,
        "got_nhi=$got_nhi  want_nhi=$want_nhi");
  }
}

# exact ones
# {
#   my @data = ([ 3,7, 3,8,   24,31 ],
#               [ 7,8, 7,13,  35,85 ],
#               [ 1,1, 1,1,   1,1 ],
#               [ 1,1, 1,2,   1,2 ],
#               [ 1,1, 2,1,   1,3 ],
#               [ 1,1, 8,1,   1,36 ],
#               [ 6,1, 8,1,   21,36 ],
#              );
#   my $path = Math::PlanePath::GcdRationals->new;
#   foreach my $elem (@data) {
#     my ($x1,$y1, $x2,$y2, $want_nlo, $want_nhi) = @$elem;
#     my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
#     ok ($got_nlo == $want_nlo,
#         1,
#         "got_nlo=$got_nlo  want_nlo=$want_nlo");
#     ok ($got_nhi == $want_nhi,
#         1,
#         "got_nhi=$got_nhi  want_nhi=$want_nhi");
#   }
# }


#------------------------------------------------------------------------------
# pairs_order n_to_xy()

{
  foreach my $group
    ([ 'rows',
       [ 1, 1,1 ],

       [ 2, 1,2 ],
       [ 3, 2,2 ],

       [ 4, 1,3 ],
       [ 5, 2,3 ],
       [ 6, 3,3 ],

       [ 7, 1,4 ],
       [ 8, 2,4 ],
       [ 9, 3,4 ],
       [10, 4,4 ],

       [11, 1,5 ],
       [12, 2,5 ],
       [13, 3,5 ],
       [14, 4,5 ],
       [15, 5,5 ],
     ],
     [ 'rows_reverse',
       [ 1, 1,1 ],

       [ 2, 2,2 ],
       [ 3, 1,2 ],

       [ 4, 3,3 ],
       [ 5, 2,3 ],
       [ 6, 1,3 ],

       [ 7, 4,4 ],
       [ 8, 3,4 ],
       [ 9, 2,4 ],
       [10, 1,4 ],

       [11, 5,5 ],
       [12, 4,5 ],
       [13, 3,5 ],
       [14, 2,5 ],
       [15, 1,5 ],
     ],
     [ 'diagonals_down',
       [ 1, 1,1 ],

       [ 2, 1,2 ],

       [ 3, 1,3 ],
       [ 4, 2,2 ],

       [ 5, 1,4 ],
       [ 6, 2,3 ],

       [ 7, 1,5 ],
       [ 8, 2,4 ],
       [ 9, 3,3 ],

       [10, 1,6 ],
       [11, 2,5 ],
       [12, 3,4 ],

       [13, 1,7 ],
       [14, 2,6 ],
       [15, 3,5 ],
       [16, 4,4 ],

       [17, 1,8 ],
       [18, 2,7 ],
       [19, 3,6 ],
       [20, 4,5 ],

       [21, 1,9 ],
       [22, 2,8 ],
       [23, 3,7 ],
       [24, 4,6 ],
       [25, 5,5 ],

       [26, 1,10 ],
       [27, 2,9 ],
       [28, 3,8 ],
       [29, 4,7 ],
       [30, 5,6 ],
     ],
     [ 'diagonals_up',
       [ 1, 1,1 ],

       [ 2, 1,2 ],

       [ 3, 2,2 ],
       [ 4, 1,3 ],

       [ 5, 2,3 ],
       [ 6, 1,4 ],

       [ 7, 3,3 ],
       [ 8, 2,4 ],
       [ 9, 1,5 ],

       [10, 3,4 ],
       [11, 2,5 ],
       [12, 1,6 ],

       [13, 4,4 ],
       [14, 3,5 ],
       [15, 2,6 ],
       [16, 1,7 ],

       [17, 4,5 ],
       [18, 3,6 ],
       [19, 2,7 ],
       [20, 1,8 ],

       [21, 5,5 ],
       [22, 4,6 ],
       [23, 3,7 ],
       [24, 2,8 ],
       [25, 1,9 ],

       [26, 5,6 ],
       [27, 4,7 ],
       [28, 3,8 ],
       [29, 2,9 ],
       [30, 1,10],
     ],
    ) {
    my ($pairs_order, @points) = @$group;
    {
      my $func = Math::PlanePath::GcdRationals
        ->can("_pairs_order__${pairs_order}__n_to_xy");
      ok (defined $func, 1, $pairs_order);
      foreach my $point (@points) {
        my ($n, $want_x,$want_y) = @$point;
        my ($got_x,$got_y) = &$func($n);
        ok ($got_x, $want_x, "$pairs_order n=$n");
        ok ($got_y, $want_y, "$pairs_order n=$n");
      }
    }
    {
      my $func = Math::PlanePath::GcdRationals
        ->can("_pairs_order__${pairs_order}__xygr_to_n");
      ok (defined $func, 1, $pairs_order);
      foreach my $point (@points) {
        my ($want_n, $x,$y) = @$point;
        my $q = 0; # imagining x=q*y+r has q=0,r=x
        my $r = $x;
        my $g = $q+1;
        my $got_n = &$func($x,$y, $g,$r);
        ok ($got_n, $want_n, "$pairs_order xygr=$x,$y,$g,$r");
      }
    }
  }
}


#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::GcdRationals->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::GcdRationals->parameter_info_list;
  ok (join(',',@pnames), 'pairs_order');
}


#------------------------------------------------------------------------------
# xy_to_n() reversing n_to_xy()

foreach my $pairs_order (@pairs_order_choices) {
  my $path = Math::PlanePath::GcdRationals->new (pairs_order => $pairs_order);
  foreach my $n ($path->n_start .. 50) {
    my ($x,$y) = $path->n_to_xy($n);
    my $rev_n = $path->xy_to_n ($x,$y);
    ok($rev_n,$n, "$pairs_order");
  }
}


#------------------------------------------------------------------------------
# Y=1 horizontal triangular numbers

{
  my $path = Math::PlanePath::GcdRationals->new;
  foreach my $k (1 .. 15) {
    my $n = $path->xy_to_n ($k, 1);
    ok ($n, $k*($k+1)/2);

    my ($x,$y) = $path->n_to_xy($n);
    ok ($x, $k);
    ok ($y, 1);
  }
}

#------------------------------------------------------------------------------
# rect_to_n_range() random

foreach my $pairs_order ('rows') {
  my $path = Math::PlanePath::GcdRationals->new (pairs_order => $pairs_order);
  foreach (1 .. 40) {
    my $x1 = int(rand() * 40) + 1;
    my $x2 = $x1 + int(rand() * 4);
    my $y1 = int(rand() * 40) + 1;
    my $y2 = $y1 + int(rand() * 10);

    my $nlo = 0;
    my $nhi = 0;
    my $nlo_y = 'none';
    my $nhi_y = 'none';

    foreach my $x ($x1 .. $x2) {
      foreach my $y ($y1 .. $y2) {
        my $n = $path->xy_to_n($x,$y);
        next if ! defined $n;

        if (! defined $nlo || $n < $nlo) {
          $nlo = $n;
          $nlo_y = $y;
        }
        if (! defined $nhi || $n > $nhi) {
          $nhi = $n;
          $nhi_y = $y;
        }
      }
    }

    my ($got_nlo,$got_nhi) = $path->rect_to_n_range($x1,$y1, $x2,$y2);

    ok (! $nlo || $got_nlo <= $nlo,
        1,
        "x=$x1..$x2 y=$y1..$y2 nlo=$nlo (at y=$nlo_y) but got_nlo=$got_nlo");
    ok (! $nhi || $got_nhi >= $nhi,
        1,
        "x=$x1..$x2 y=$y1..$y2 nhi=$nhi (at y=$nhi_y) but got_nhi=$got_nhi");
  }
}

#------------------------------------------------------------------------------
# _gcd() on Math::BigInt

{
  require Math::BigInt;
  my $x = Math::BigInt->new(35);
  my $y = Math::BigInt->new(15);
  my $g = Math::PlanePath::GcdRationals::_gcd($x,$y);

  # not a string compare since "+35" in old Math::BigInt
  ok ($x == 35, 1, 'x input unchanged');
  ok ($y == 15, 1, 'y input unchanged');
  ok ($g == 5, 1, 'gcd(35,15) result');
}

exit 0;
