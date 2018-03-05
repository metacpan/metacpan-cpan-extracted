#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
plan tests => 349;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;

use Math::PlanePath::GcdRationals;
*_gcd = \&Math::PlanePath::GcdRationals::_gcd;

use Math::PlanePath::ImaginaryHalf;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::ImaginaryHalf::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ImaginaryHalf->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ImaginaryHalf->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ImaginaryHalf->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ImaginaryHalf->new;
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
  my $path = Math::PlanePath::ImaginaryHalf->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::ImaginaryHalf->parameter_info_list;
  ok (join(',',@pnames), 'radix,digit_order');
}


#------------------------------------------------------------------------------

{
  my @data = (
              [ { digit_order => 'XYX' },
                [ 0,  0,0 ],
                [ 1,  1,0 ],
                [ 2,  0,1 ],
                [ 3,  1,1 ],

                [ 4, -2,0 ],
                [ 5, -1,0 ],
                [ 6, -2,1 ],
                [ 7, -1,1 ],
              ],

              [ { digit_order => 'XXY' },
                [ 0,  0,0 ],
                [ 1,  1,0 ],
                [ 2, -2,0 ],
                [ 3, -1,0 ],

                [ 4,  0,1 ],
                [ 5,  1,1 ],
                [ 6, -2,1 ],
                [ 7, -1,1 ],
              ],

              [ { digit_order => 'YXX' },
                [ 0,  0,0 ],
                [ 1,  0,1 ],
                [ 2,  1,0 ],
                [ 3,  1,1 ],

                [ 4, -2,0 ],
                [ 5, -2,1 ],
                [ 6, -1,0 ],
                [ 7, -1,1 ],
              ],


              [ { digit_order => 'XnYX' },
                [ 0,  0,0 ],
                [ 1, -2,0 ],
                [ 2,  0,1 ],
                [ 3, -2,1 ],

                [ 4,  1,0 ],
                [ 5, -1,0 ],
                [ 6,  1,1 ],
                [ 7, -1,1 ],
              ],

              [ { digit_order => 'XnXY' },
                [ 0,  0,0 ],
                [ 1, -2,0 ],
                [ 2,  1,0 ],
                [ 3, -1,0 ],

                [ 4,  0,1 ],
                [ 5, -2,1 ],
                [ 6,  1,1 ],
                [ 7, -1,1 ],
              ],

              [ { digit_order => 'YXnX' },
                [ 0,  0,0 ],
                [ 1,  0,1 ],
                [ 2, -2,0 ],
                [ 3, -2,1 ],

                [ 4,  1,0 ],
                [ 5,  1,1 ],
                [ 6, -1,0 ],
                [ 7, -1,1 ],
              ],
             );
  foreach my $group (@data) {
    my ($options, @elems) = @$group;
    my $path = Math::PlanePath::ImaginaryHalf->new (%$options);
    my $order = $options->{'digit_order'};
    my $n_start = $path->n_start;

    foreach my $elem (@elems) {
      my ($n, $want_x, $want_y) = @$elem;
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      ok ($got_x, $want_x, "order=$order x at n=$n");
      ok ($got_y, $want_y, "order=$order y at n=$n");
    }

    foreach my $elem (@elems) {
      my ($want_n, $x, $y) = @$elem;
      next unless $want_n==int($want_n);
      my $got_n = $path->xy_to_n ($x, $y);
      ok ($got_n, $want_n, "order=$order xy_to_n($x,$y) sample");
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
