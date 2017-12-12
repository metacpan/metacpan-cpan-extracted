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
plan tests => 158;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::PyramidRows;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::PyramidRows::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::PyramidRows->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::PyramidRows->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::PyramidRows->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::PyramidRows->new;
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
  my $path = Math::PlanePath::PyramidRows->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() default');
  ok ($path->y_negative, 0, 'y_negative() default');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');

  my @pnames = map {$_->{'name'}} $path->parameter_info_list;
  ok (join(',',@pnames), 'step,align,n_start');
}
{
  my $path = Math::PlanePath::PyramidRows->new (step => 0);
  ok ($path->n_start, 1, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative() step=0');
  ok (! $path->y_negative, 1, 'y_negative() step=0');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my $path = Math::PlanePath::PyramidRows->new (step => 1);
  ok ($path->n_start, 1, 'n_start()');
  ok (! $path->x_negative, 1, 'x_negative() step=1');
  ok (! $path->y_negative, 1, 'y_negative() step=1');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my $path = Math::PlanePath::PyramidRows->new (step => 3);
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() step=3');
  ok ($path->y_negative, 0, 'y_negative() step=3');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  foreach my $elem (
                    # step = 2
                    # 5 6 7 8 9  y=2
                    #   2 3 4    y=1
                    #     1      y=0
                    #    x=0
                    [undef,  0,1, 0,1,   3,3],
                    [undef,  0,2, 0,2,   7,7],
                    [2,     -2,0, -1,2,  2,6], # part left
                    [2,      2,0, 1,2,  4,9], # part right

                    # step = 1
                    #  4 5 6  y=2
                    #  2 3    y=1
                    #  1      y=0
                    # x=0
                    [1,  0,1, 0,1,  2,2],
                    [1,  0,2, 0,2,  4,4],
                    [1,  -1,1, 0,2,  2,4], # part left
                    [1,  1,0, 2,2,  3,6], # part right

                    # step = 0
                    #  3   y=2
                    #  2   y=1
                    #  1   y=0
                    # x=0
                    [0,  0,1, 0,1,  2,2],
                    [0,  0,2, 0,2,  3,3],


                    # step = 4
                    # 7  8  9 10 11 12 13 14 15  y=2
                    #       2  3  4  5  6        y=1
                    #             1              y=0
                    #            x=0
                    [4,  -7,-2, -1,1,   2,3],

                   ) {
    my ($step, $x1,$y1, $x2,$y2, $want_lo,$want_hi) = @$elem;
    my $dstep = (defined $step ? $step : 'undef');

    my $path = Math::PlanePath::PyramidRows->new (step => $step);
    my ($got_lo, $got_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
    ### $got_lo
    ### $got_hi
    ok ($got_lo, $want_lo,
        "lo on $x1,$y1 $x2,$y2 step=$dstep");
    ok ($got_hi, $want_hi,
        "hi on $x1,$y1 $x2,$y2 step=$dstep");
  }
}

{
  foreach my $elem (
                    [0,0, 0,0,   1,1],

                    [-1,0, -1,0, 1,0], # off left
                    [1,0, 1,0,   1,0], # off right

                    [-999,-5, -500,3, 1,0], # far off left
                    [ 999,-5,  500,3, 1,0], # far off right

                    [ -10,-1, 10,-6,  1,0], # y negs
                   ) {
    foreach my $step (undef, 0, 1, 2, 3, 4, 5, 10, 20) {
      my ($x1,$y1,$x2,$y2, $want_lo, $want_hi) = @$elem;
      my $dstep = (defined $step ? $step : 'undef');

      my $path = Math::PlanePath::PyramidRows->new (step => $step);
      my ($got_lo, $got_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
      ok ($got_lo, $want_lo,
          "lo on $x1,$y1 $x2,$y2 step=$dstep");
      ok ($got_hi, $want_hi,
          "hi on $x1,$y1 $x2,$y2 step=$dstep");
    }
  }
}

exit 0;
