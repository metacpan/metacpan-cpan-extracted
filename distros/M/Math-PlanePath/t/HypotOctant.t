#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
plan tests => 21;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Devel::Comments;

require Math::PlanePath::HypotOctant;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::HypotOctant::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::HypotOctant->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::HypotOctant->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::HypotOctant->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::HypotOctant->new;
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
  my $path = Math::PlanePath::HypotOctant->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative() instance method');
  ok ($path->y_negative, 0, 'y_negative() instance method');
  ok ($path->class_x_negative, 0, 'class_x_negative()');
  ok ($path->class_y_negative, 0, 'class_y_negative()');
  ok ($path->x_minimum, 0, 'x_minimum()');
  ok ($path->y_minimum, 0, 'y_minimum()');
  ok ($path->sumxy_minimum,  0, 'sumxy_minimum()');
  ok ($path->diffxy_minimum, 0, 'diffxy_minimum()');
}
{
  my $path = Math::PlanePath::HypotOctant->new (points => 'odd');
  ok ($path->x_minimum, 1, 'x_minimum()');
  ok ($path->y_minimum, 0, 'y_minimum()');
  ok ($path->sumxy_minimum,  1, 'sumxy_minimum()');
  ok ($path->diffxy_minimum, 1, 'diffxy_minimum()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::HypotOctant->parameter_info_list;
  ok (join(',',@pnames), 'points');
}


#------------------------------------------------------------------------------
# increasing R^2

my @points_choices
 = @{Math::PlanePath::HypotOctant->parameter_info_hash
    ->{'points'}->{'choices'}};

foreach my $points (@points_choices) {
  my $path = Math::PlanePath::HypotOctant->new (points => $points);
  my $prev_h = -1;
  my $prev_x = 0;
  my $prev_y = -1;
  foreach my $n ($path->n_start .. 1000) {
    my ($x, $y) = $path->n_to_xy ($n);
    my $h = $x*$x + $y*$y;
    if ($h < $prev_h) {
      die "decreasing h=$h prev=$prev_h";
    }
    $prev_h = $h;
    $prev_x = $x;
    $prev_y = $y;
  }
}

    # if ($n > 2 && ! _turn_func_Left($prev_x,$prev_y, $x,$y)) {
    #   die "not turn left at n=$n xy=$x,$y prev=$prev_x,$prev_y";
    # }
# sub _turn_func_Left {
#   my ($dx,$dy, $next_dx,$next_dy) = @_;
#   ### _turn_func_Left() ...
#   my $a = $next_dy * $dx;
#   my $b = $next_dx * $dy;
#   return ($a > $b
#           || $dx==-$next_dx && $dy==-$next_dy  # straight opposite 180
#           ? 1
#           : 0);
# }


#------------------------------------------------------------------------------
exit 0;
