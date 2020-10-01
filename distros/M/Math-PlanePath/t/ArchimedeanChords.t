#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
plan tests => 74;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::ArchimedeanChords;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::ArchimedeanChords::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ArchimedeanChords->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ArchimedeanChords->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ArchimedeanChords->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ArchimedeanChords->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}



#------------------------------------------------------------------------------
# xy_to_n()

{
  my @data = ([ 0,0,  0 ],
              [ 0.001,0.001,  0 ],
              [ -0.001,0.001,  0 ],
              [ 0.001,-0.001,  0 ],
              [ -0.001,-0.001,  0 ],
             );
  my $path = Math::PlanePath::ArchimedeanChords->new;

  $path->n_to_xy(600); # provoke some save table filling 

  foreach my $elem (@data) {
    my ($x, $y, $want_n) = @$elem;
    my @got_n = $path->xy_to_n ($x,$y);
    ok (scalar(@got_n), 1, "xy_to_n x=$x y=$y -- return 1 value");
    my $got_n = $got_n[0];
    ok ($got_n, $want_n, "xy_to_n x=$x y=$y -- n value");

    ok (!! $path->xy_is_visited($x,$y), 1,
        "xy_is_visited($x,$y)");
  }
}

#------------------------------------------------------------------------------
# n_start(), x_negative(), y_negative(), etc

{
  my $path = Math::PlanePath::ArchimedeanChords->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 1, 'class_y_negative() instance method');

  my @pnames = map {$_->{'name'}} $path->parameter_info_list;
  ok (join(',',@pnames), '');

  ok (!! $path->xy_is_visited(0,0), 1, 'xy_is_visited(0,0)');

  ok ($path->gcdxy_minimum, 0, 'gcdxy_minimum() is 0 at X=0,Y=0');
}

#------------------------------------------------------------------------------
# _xy_to_nearest_r()

{
  my @data = (
              [    0,    0,  0 ],
              [ -0.0, -0.0,  0 ],
              [ -0.0,    0,  0 ],
              [    0, -0.0,  0 ],

              # positive X axis
              [ .1,0,  0 ],
              [ .4,0,  0 ],

              [ .6,0,  1 ],
              [ .9,0,  1 ],
              [ 1,0,   1 ],
              [ 1.1,0, 1 ],
              [ 1.4,0, 1 ],

              [ 1.6,0,  2 ],
              [ 1.9,0,  2 ],
              [ 2,0,    2 ],
              [ 2.1,0,  2 ],
              [ 2.4,0,  2 ],

              # positive Y axis
              [ 0,.1,  .25 ],
              [ 0,.2,  .25 ],
              [ 0,.25, .25 ],
              [ 0,.7,  .25 ],

              [ 0,.8,   1.25 ],
              [ 0,1.25, 1.25 ],
              [ 0,1.7,  1.25 ],

              [ 0,1.8,  2.25 ],
              [ 0,2.25, 2.25 ],
              [ 0,2.7,  2.25 ],

              # negative X axis
              [ -.1,0, .5 ],
              [ -.5,0, .5 ],
              [ -.9,0, .5 ],

              [ -1.1,0, 1.5 ],
              [ -1.5,0, 1.5 ],
              [ -1.9,0, 1.5 ],

              [ -2.1,0, 2.5 ],
              [ -2.5,0, 2.5 ],
              [ -2.9,0, 2.5 ],

              # negative Y axis
              [ 0,-.1, .75 ],
              [ 0,-.75, .75 ],
              [ 0,-1.2, .75 ],

              [ 0,-1.3,  1.75 ],
              [ 0,-1.75, 1.75 ],
              [ 0,-2.2,  1.75 ],

              [ 0,-2.3,  2.75 ],
              [ 0,-2.75, 2.75 ],
              [ 0,-3.2,  2.75 ],

             );
  foreach my $elem (@data) {
    my ($x, $y, $want) = @$elem;

    my $got = Math::PlanePath::ArchimedeanChords::_xy_to_nearest_r($x,$y);
    ok (abs ($got - $want) < 0.001,
        1,
        "_xy_to_nearest_r() on x=$x,y=$y got $got want $want");
  }
}



#------------------------------------------------------------------------------exit 0;
