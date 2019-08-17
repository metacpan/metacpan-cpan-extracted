#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
plan tests => 43;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::Columns;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::Columns::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::Columns->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::Columns->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::Columns->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::Columns->new;
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
  my $path = Math::PlanePath::Columns->new (height => 123);
  ok ($path->n_start, 1, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative()');
  ok (! $path->y_negative, 1, 'y_negative()');
  ok (! $path->class_x_negative, 1, 'class_x_negative() instance method');
  ok (! $path->class_y_negative, 1, 'class_y_negative() instance method');
}
{
  # height not a parameter as such ...
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::Columns->parameter_info_list;
  ok (join(',',@pnames), 'n_start');
}

#------------------------------------------------------------------------------
# _UNDOCUMENTED__turn_any_right_at_n()

{
  my $path = Math::PlanePath::Columns->new (height => 5);
  ok ($path->_UNDOCUMENTED__turn_any_right_at_n(), 5);
}

#------------------------------------------------------------------------------
# n_to_xy

{
  my @data = ([ 1, 0,0 ],
              [ 2, 0,1 ],
              [ 2.5, 0,1.5 ],
              [ 5, 0,4 ],

              [ 5.5, 1,-0.5 ],
              [ 6, 1,0 ],
              [ 7, 1,1 ],

             );
  my $path = Math::PlanePath::Columns->new (height => 5);
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next if $want_n != int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  foreach my $elem ([5,  0,0, 0,0,  1,1],
                    [5,  0,1, 0,1,  2,2],
                    [5,  -1,0, -1,1,  -4,-3],
                    [5,  0,0, 0,9999, 1,5 ],
                    [5,  0,3, 0,-9999, 1,4 ],
                   ) {
    my ($height, $x1,$y1,$x2,$y2, $want_lo, $want_hi) = @$elem;
    my $path = Math::PlanePath::Columns->new (height => $height);
    my ($got_lo, $got_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
    ok ($got_lo, $want_lo, "lo on $x1,$y1 $x2,$y2 height=$height");
    ok ($got_hi, $want_hi, "hi on $x1,$y1 $x2,$y2 height=$height");
  }
}

exit 0;
