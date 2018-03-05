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
plan tests => 510;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::MultipleRings;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::MultipleRings::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::MultipleRings->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::MultipleRings->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::MultipleRings->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::MultipleRings->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# exact points

my $base_r3 = Math::PlanePath::MultipleRings->new(step=>3)->{'base_r'};
my $base_r4 = Math::PlanePath::MultipleRings->new(step=>4)->{'base_r'};

foreach my $elem (
                  # step=0 horizontal
                  [ [step=>0], 1, 0,0 ],
                  [ [step=>0], 2, 1,0 ],
                  [ [step=>0], 3, 2,0 ],

                  # step=1
                  [ [step=>1], 1, 0,0 ],
                  [ [step=>1], 1.25, 0,0 ],
                  [ [step=>1], 2, 1,0 ],
                  [ [step=>1], 2.25, 0.5,0 ],
                  [ [step=>1], 2.75, -0.5,0 ],
                  [ [step=>1], 3, -1,0 ],
                  [ [step=>1], 3.25, -0.5,0 ],
                  [ [step=>1], 3.75, 0.5,0 ],
                  [ [step=>1], 4, 2,0 ],
                  [ [step=>1], 7, 3,0 ],
                  [ [step=>1], 8, 0,3 ],
                  [ [step=>1], 9, -3,0 ],
                  [ [step=>1], 10, 0,-3 ],
                  [ [step=>1], 11, 4,0 ],
                  [ [step=>1], 16, 5,0 ],
                  [ [step=>1], 19, -5,0 ],

                  # step=2
                  [ [step=>2], 1, 0.5, 0 ],
                  [ [step=>2], 2, -0.5, 0 ],
                  [ [step=>2], 3, 1.5, 0 ],
                  [ [step=>2], 4, 0, 1.5 ],
                  [ [step=>2], 5, -1.5, 0 ],
                  [ [step=>2], 6, 0,-1.5 ],
                  [ [step=>2], 7, 2.5, 0 ],
                  [ [step=>2], 10, -2.5, 0 ],
                  [ [step=>2], 13, 3.5, 0 ],
                  [ [step=>2], 17, -3.5, 0 ],
                  [ [step=>2], 21, 4.5, 0 ],
                  [ [step=>2], 26, -4.5, 0 ],

                  # step=3
                  [ [step=>3], 1, $base_r3+1, 0 ],
                  [ [step=>3], 4, $base_r3+2, 0 ],
                  [ [step=>3], 7, -($base_r3+2), 0 ],
                  [ [step=>3], 10, $base_r3+3, 0 ],
                  [ [step=>3], 19, $base_r3+4, 0 ],
                  [ [step=>3], 25, -($base_r3+4), 0 ],

                  # step=4
                  [ [step=>4], 1, $base_r4+1, 0 ],
                  [ [step=>4], 2, 0, $base_r4+1 ],
                  [ [step=>4], 3, -($base_r4+1), 0 ],
                  [ [step=>4], 4, 0, -($base_r4+1) ],
                  [ [step=>4], 5, $base_r4+2, 0 ],
                  [ [step=>4], 7, 0, $base_r4+2 ],
                  [ [step=>4], 9, -($base_r4+2), 0 ],
                  [ [step=>4], 11, 0, -($base_r4+2) ],

                  # step=6
                  [ [step=>6],  1,   1, 0 ],
                  [ [step=>6],  4,  -1, 0 ],
                  [ [step=>6],  7,   2, 0 ],
                  [ [step=>6], 13,  -2, 0 ],

                  [ [step=>6,ring_shape=>'polygon'],  1,   1, 0 ],
                  [ [step=>6,ring_shape=>'polygon'],  4,  -1, 0 ],

                 ) {
  my ($parameters, $n, $x, $y) = @$elem;
  my $path = Math::PlanePath::MultipleRings->new (@$parameters);
  my $name = join(',',@$parameters);

  {
    # n_to_xy()
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
    if ($got_y == 0) { $got_y = 0 }
    ok ($got_x, $x, "$name n_to_xy() x at n=$n");
    ok ($got_y, $y, "$name n_to_xy() y at n=$n");
  }
  {
    # n_to_rsquared()
    my $rsquared = $x*$x + $y*$y;
    my @got_rsquared = $path->n_to_rsquared($n);
    my $got_rsquared = $got_rsquared[0];
    ok (scalar(@got_rsquared), 1);
    ok (defined $got_rsquared, 1);
    ok ($got_rsquared == $rsquared,
        1,
        "$name n_to_rsquared() at n=$n  want $rsquared got $got_rsquared");
  }
}


#------------------------------------------------------------------------------
# n_to_rsquared()

foreach my $elem (
                  # step=0
                  [ [step=>0], 1,   0*0 ],
                  [ [step=>0], 2,   1*1 ],
                  [ [step=>0], 2.5, 1.5*1.5 ],
                  [ [step=>0], 3,   2*2 ],
                  [ [step=>0], 4,   3*3 ],

                  #-------------------------------------------
                  # step=1
                  [ [step=>1], 1,  0*0 ],        # origin    R=0

                  [ [step=>1], 2,    1*1 ],      # horiz, right    R=1
                  [ [step=>1], 2.25,  0.5*0.5 ],
                  [ [step=>1], 2.5,  0 ],
                  [ [step=>1], 2.75,  0.5*0.5 ],
                  [ [step=>1], 3,    1*1 ],      # left
                  [ [step=>1], 3.25,  0.5*0.5 ],
                  [ [step=>1], 3.5,  0 ],
                  [ [step=>1], 3.75,  0.5*0.5 ],

                  [ [step=>1], 4,    2*2 ],      # triangle, right    R=2
                  [ [step=>1], 4.5,  1*1 ],
                  [ [step=>1], 4.25, 7/4 ],
                  [ [step=>1], 4.75, 7/4 ],
                  [ [step=>1], 5,    2*2 ],      # up    R=2 at 120deg
                  [ [step=>1], 5.25, 7/4 ],
                  [ [step=>1], 5.75, 7/4 ],
                  [ [step=>1], 6,    2*2 ],      # down  R=2 at 240deg
                  [ [step=>1], 6.25, 7/4 ],
                  [ [step=>1], 6.75, 7/4 ],

                  [ [step=>1], 7,     3*3 ],     # square
                  [ [step=>1], 7.5,   4.5 ],
                  [ [step=>1], 7.25,  45/8 ],
                  [ [step=>1], 10,    3*3 ],
                  [ [step=>1], 10.5,  4.5 ],
                  [ [step=>1], 10.75,  45/8 ],

                  [ [step=>1], 16,    5*5 ],     # hexagon
                  [ [step=>1], 16.25,  325/16 ],
                  [ [step=>1], 16.5,  75/4 ],
                  [ [step=>1], 21,    5*5 ],
                  [ [step=>1], 21.75,  325/16 ],

                  #-------------------------------------------
                  # step=6
                  [ [step=>6], 1,     1*1 ],  # 1..6 inclusive
                  [ [step=>6], 6,     1*1 ],
                  # [ [step=>6], 6.75, undef ],

                  [ [step=>6], 7,     2*2 ],  # 7..18 inclusive
                  [ [step=>6], 18,    2*2 ],

                  [ [step=>6], 19,    3*3 ],  # 19..36 inclusive
                  [ [step=>6], 36,    3*3 ],

                  [ [step=>6,ring_shape=>'polygon'], 1,     1*1 ],
                  [ [step=>6,ring_shape=>'polygon'], 6,     1*1 ],
                  # [ [step=>6,ring_shape=>'polygon'], 7,    undef ],

                 ) {
  my ($parameters, $n, $want_rsquared) = @$elem;
  my $path = Math::PlanePath::MultipleRings->new (@$parameters);
  my $name = join(',',@$parameters);

  {
    my ($x,$y) = $path->n_to_xy($n);
    my $xy_rsquared = $x*$x + $y*$y;
    ok (abs($xy_rsquared-$want_rsquared) < 0.0001);
  }
  {
    my $got_rsquared = $path->n_to_rsquared($n);
    my $got_rsquared_str = (defined $got_rsquared
                            ? sprintf('%.22f', $got_rsquared)
                            : '[undef]');
    my $want_rsquared_str = (defined $want_rsquared
                             ? sprintf('%.22f', $want_rsquared)
                             : '[undef]');
    ok (equal($got_rsquared,$want_rsquared), 1,
        "$name n_to_rsquared() at n=$n  got $got_rsquared_str want $want_rsquared_str");
  }
  {
    my $got_radius = $path->n_to_radius($n);
    my $got_radius_str = sprintf('%.22f', $got_radius);
    my $want_radius = sqrt($want_rsquared);
    my $want_radius_str = sprintf('%.22f', $want_radius);
    if ($want_radius*$want_radius == $want_rsquared) {
      ok (equal($got_radius,$want_radius), 1,
          "$name n_to_radius() at n=$n  got $got_radius_str want $want_radius_str");
    } else {
      ok (abs($got_radius-$want_radius) < 0.0001, 1,
          "$name n_to_radius() at n=$n  got $got_radius_str want $want_radius_str");
    }
  }
}

sub equal {
  my ($x,$y) = @_;
  return ((! defined $x && ! defined $y)
          || (defined $x && defined $y && $x == $y));
}

#------------------------------------------------------------------------------
# _xy_to_angle_frac()

{
  my @data = ([    1,    0,  0   ],
              [    0,    1,  .25 ],
              [   -1,    0,  .5  ],
              [    0,   -1,  .75 ],
              [    0,    0,  0   ],
              [ -0.0, -0.0,  0   ],
              [ -0.0,    0,  0   ],
              [    0, -0.0,  0   ],
             );
  foreach my $elem (@data) {
    my ($x, $y, $want) = @$elem;

    my $got = Math::PlanePath::MultipleRings::_xy_to_angle_frac($x,$y);
    ok (abs ($got - $want) < 0.001,
        1,
        "_xy_to_angle_frac() on x=$x,y=$y got $got want $want");
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative(), y_negative()

{
  my $path = Math::PlanePath::MultipleRings->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 1, 'class_y_negative() instance method');
}
{
  my $path = Math::PlanePath::MultipleRings->new (step => 0);
  ok ($path->n_start, 1, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative()');
  ok (! $path->y_negative, 1, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 1, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::MultipleRings->parameter_info_list;
  ok (join(',',@pnames), 'step,ring_shape');
}


#------------------------------------------------------------------------------
# xy_to_n()

{
  my $step = 3;
  my $n = 2;
  my $path = Math::PlanePath::MultipleRings->new (step => $step);
  my ($x,$y) = $path->n_to_xy($n);
  $y -= .1;
  ### try: "n=$n  x=$x,y=$y"
  my $got_n = $path->xy_to_n($x,$y);
  ### $got_n
  ok ($got_n, $n, "xy_to_n() back from n=$n at offset x=$x,y=$y");
}

# step=0 and step=1 centred on 0,0
# step=2 two on ring, rounds to the N=1
foreach my $step (0 .. 2) {
  my $path = Math::PlanePath::MultipleRings->new (step => $step);
  ok ($path->xy_to_n(0,0), 1, "xy_to_n(0,0) step=$step is 1");
  ok ($path->xy_to_n(-0.0, 0), 1, "xy_to_n(-0,0) step=$step is 1");
  ok ($path->xy_to_n(0, -0.0), 1, "xy_to_n(0,-0) step=$step is 1");
  ok ($path->xy_to_n(-0.0, -0.0), 1, "xy_to_n(-0,-0) step=$step is 1");
}
foreach my $step (3 .. 10) {
  my $path = Math::PlanePath::MultipleRings->new (step => $step);
  ok ($path->xy_to_n(0,0), undef,
      "xy_to_n(0,0) step=$step is undef (nothing in centre)");
  ok ($path->xy_to_n(-0.0, 0), undef,
      "xy_to_n(-0,0) step=$step is undef (nothing in centre)");
  ok ($path->xy_to_n(0, -0.0), undef,
      "xy_to_n(0,-0) step=$step is undef (nothing in centre)");
  ok ($path->xy_to_n(-0.0, -0.0), undef,
      "xy_to_n(-0,-0) step=$step is undef (nothing in centre)");
}

foreach my $step (0 .. 3) {
  my $path = Math::PlanePath::MultipleRings->new (step => $step);
  ok ($path->xy_to_n(0.1,0.1), 1,
      "xy_to_n(0.1,0.1) step=$step is 1");
}
foreach my $step (4 .. 10) {
  my $path = Math::PlanePath::MultipleRings->new (step => $step);
  ok ($path->xy_to_n(0.1,0.1), undef,
      "xy_to_n(0.1,0.1) step=$step is undef (nothing in centre)");
}

#------------------------------------------------------------------------------
# rect_to_n_range()

foreach my $step (0 .. 10) {
  my $path = Math::PlanePath::MultipleRings->new (step => $step);
  my ($got_lo, $got_hi) = $path->rect_to_n_range(0,0,0,0);
  ok ($got_lo >= 1,
      1, "rect_to_n_range(0,0) step=$step is lo=$got_lo");
  ok ($got_hi >= $got_lo,
      1, "rect_to_n_range(0,0) step=$step want hi=$got_hi >= lo");
}

foreach my $step (0 .. 10) {
  my $path = Math::PlanePath::MultipleRings->new (step => $step);
  my ($got_lo, $got_hi) = $path->rect_to_n_range(-0.1,-0.1, 0.1,0.1);
  ok ($got_lo >= 1,
      1, "rect_to_n_range(0,0) step=$step is lo=$got_lo");
  ok ($got_hi >= $got_lo,
      1, "rect_to_n_range(0,0) step=$step want hi=$got_hi >= lo");
}

exit 0;
