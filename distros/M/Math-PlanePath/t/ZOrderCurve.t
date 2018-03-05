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
plan tests => 15;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::ZOrderCurve;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::ZOrderCurve::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ZOrderCurve->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ZOrderCurve->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ZOrderCurve->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ZOrderCurve->new;
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
  my $path = Math::PlanePath::ZOrderCurve->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative() instance method');
  ok ($path->y_negative, 0, 'y_negative() instance method');
}


#------------------------------------------------------------------------------
# n_to_rsquared()

{
  my $path = Math::PlanePath::ZOrderCurve->new;
  ok ($path->n_to_rsquared(0), 0);
  ok ($path->n_to_rsquared(1), 1);
  ok ($path->n_to_rsquared(3), 2);
  ok ($path->n_to_rsquared(4), 4);
  ok ($path->n_to_rsquared(6), 5);
}

exit 0;
