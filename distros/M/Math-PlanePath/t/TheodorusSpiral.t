#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 28;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::TheodorusSpiral;
my $path = Math::PlanePath::TheodorusSpiral->new;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::TheodorusSpiral::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::TheodorusSpiral->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::TheodorusSpiral->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::TheodorusSpiral->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

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
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}

#------------------------------------------------------------------------------

{
  my $n_save = Math::PlanePath::TheodorusSpiral::_SAVE();
  my $n = 2 * $n_save - 10;
  my ($x1,$y1) = $path->n_to_xy ($n);

  $path->n_to_xy ($n + 10); # forward

  my ($x2,$y2) = $path->n_to_xy ($n);

  ok ($x1, $x2);
  ok ($y1, $y2);
}


{
  my ($x,$y) = $path->n_to_xy (0);
  ok ($x, 0);
  ok ($y, 0);
}
{
  my ($x,$y) = $path->n_to_xy (1);
  ok ($x, 1);
  ok ($y, 0);
}
{
  my ($x,$y) = $path->n_to_xy (2);
  ok ($x, 1);
  ok ($y, 1);
}


#------------------------------------------------------------------------------
# n_to_rsquared()

{
  my $path = Math::PlanePath::TheodorusSpiral->new;
  ok ($path->n_to_rsquared(0), 0);
  {
    ok ($path->n_to_rsquared(0.5), 0.25); # X=0.5, Y=0
    my ($x,$y) = $path->n_to_xy(0.5);
    ok ($path->n_to_rsquared(0.5), $x*$x+$y*$y);
  }
  ok ($path->n_to_rsquared(1), 1);
  {
    ok ($path->n_to_rsquared(1.5), 1.25); # X=1, Y=0.5
    my ($x,$y) = $path->n_to_xy(1.5);
    ok ($path->n_to_rsquared(1.5), $x*$x+$y*$y);
  }
  {
    ok ($path->n_to_rsquared(2.5), 2.25); # X=1, Y=0.5
    my ($x,$y) = $path->n_to_xy(2.5);
    ok ($path->n_to_rsquared(2.5), $x*$x+$y*$y);
  }
  {
    ok ($path->n_to_rsquared(123.5), 123.25); # X=1, Y=0.5
    my ($x,$y) = $path->n_to_xy(123.5);
    ok ($path->n_to_rsquared(123.5), $x*$x+$y*$y);
  }
}

exit 0;
