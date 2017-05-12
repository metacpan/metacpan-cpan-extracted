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
plan tests => 13;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Devel::Comments;

require Math::PlanePath::Hypot;

my $path = Math::PlanePath::Hypot->new;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::Hypot::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::Hypot->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::Hypot->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::Hypot->VERSION($check_version); 1 },
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
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::Hypot->parameter_info_list;
  ok (join(',',@pnames), 'points,n_start');
}


#------------------------------------------------------------------------------
# increasing R^2

foreach my $points (@{Math::PlanePath::Hypot
  ->parameter_info_hash->{'points'}->{'choices'}}) {
  foreach my $n_start (1, 0, 37) {
    my $path = Math::PlanePath::Hypot->new (points => $points,
                                            n_start => $n_start);
    my $prev_h = -1;
    my $prev_x = 0;
    my $prev_y = -1;
    foreach my $n ($n_start .. $n_start + 1000) {
      my ($x, $y) = $path->n_to_xy ($n);
      my $h = $x*$x + $y*$y;
      if ($h < $prev_h) {
        die "decreasing h=$h prev=$prev_h";
      }
      if ($n > $n_start+1 && ! _turn_func_Left($prev_x,$prev_y, $x,$y)) {
        die "not turn left at n=$n xy=$x,$y prev=$prev_x,$prev_y";
      }
      $prev_h = $h;
      $prev_x = $x;
      $prev_y = $y;
    }
  }
}

sub _turn_func_Left {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  ### _turn_func_Left() ...
  my $a = $next_dy * $dx;
  my $b = $next_dx * $dy;
  return ($a > $b
          || $dx==-$next_dx && $dy==-$next_dy  # straight opposite 180
          ? 1
          : 0);
}


#------------------------------------------------------------------------------
exit 0;
