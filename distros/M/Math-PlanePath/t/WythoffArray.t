#!/usr/bin/perl -w

# Copyright 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
plan tests => 15;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::WythoffArray;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::WythoffArray::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::WythoffArray->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::WythoffArray->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::WythoffArray->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::WythoffArray->new;
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
  my $path = Math::PlanePath::WythoffArray->new;
  ok ($path->n_start, 1, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative()');
  ok (! $path->y_negative, 1, 'y_negative()');
  ok (! $path->class_x_negative, 1, 'class_x_negative() instance method');
  ok (! $path->class_y_negative, 1, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::WythoffArray->parameter_info_list;
  ok (join(',',@pnames), 'x_start,y_start');
}
{
  my $path = Math::PlanePath::WythoffArray->new (x_start=>123, y_start=>456);
  ok ($path->x_minimum, 123, 'x_minimum()');
  ok ($path->y_minimum, 456, 'y_minimum()');
}

#------------------------------------------------------------------------------

exit 0;
