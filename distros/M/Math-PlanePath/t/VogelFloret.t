#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
plan tests => 29;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::VogelFloret;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 129;
  ok ($Math::PlanePath::VogelFloret::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::VogelFloret->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::VogelFloret->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::VogelFloret->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::VogelFloret->new;
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
  my $path = Math::PlanePath::VogelFloret->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');

  my @pnames = map {$_->{'name'}} $path->parameter_info_list;
  ok (join(',',@pnames), 'rotation_type,rotation_factor,radius_factor');
}

#------------------------------------------------------------------------------
# parameters

{
  my $pp = Math::PlanePath::VogelFloret->new;
  ok ($pp->{'rotation_factor'} >= 0,
      1);
  ok ($pp->{'radius_factor'} >= 0,
      1);

  my $ps2 = Math::PlanePath::VogelFloret->new (rotation_type => 'sqrt2');
  ok ($ps2->{'rotation_factor'} >= 0,
      1,);
  ok ($ps2->{'radius_factor'} >= 0,
      1);

  ok ($pp->{'rotation_factor'} != $ps2->{'rotation_factor'},
     1);

  {
    my $path = Math::PlanePath::VogelFloret->new (rotation_factor => 0.5);
    ok ($path->{'rotation_factor'} == 0.5,
        1);
    ok ($path->{'radius_factor'} >= 1.0,
        1);
  }
  {
    my $path = Math::PlanePath::VogelFloret->new (rotation_type => 'sqrt2',
                                                  radius_factor => 2.0);
    ok ($path->{'rotation_factor'}, $ps2->{'rotation_factor'});
    ok ($path->{'radius_factor'} >= 2.0,
        1);
  }
}

#------------------------------------------------------------------------------
# n_to_rsquared()

{
  my $path = Math::PlanePath::VogelFloret->new (radius_factor => 1);
  ok ($path->n_to_rsquared(0), 0);
  ok ($path->n_to_rsquared(1), 1);
  ok ($path->n_to_rsquared(20.5), 20.5);
}
{
  my $path = Math::PlanePath::VogelFloret->new (radius_factor => 2);
  ok ($path->n_to_rsquared(0), 0);
  ok ($path->n_to_rsquared(1), 1*4);
  ok ($path->n_to_rsquared(20.5), 20.5*4);
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my $path = Math::PlanePath::VogelFloret->new;
  my ($n_lo, $n_hi) = $path->rect_to_n_range (-100,-100, 100,100);
  ok ($n_lo, 1);
  ok ($n_hi > 1,
      1);
  ok ($n_hi < 10*100*100,
      1);
}

exit 0;
