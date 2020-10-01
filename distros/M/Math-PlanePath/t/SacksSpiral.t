#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
plan tests => 153;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::SacksSpiral;


sub numeq_array {
  my ($a1, $a2) = @_;
  if (! ref $a1 || ! ref $a2) {
    return 0;
  }
  my $i = 0; 
  while ($i < @$a1 && $i < @$a2) {
    if ($a1->[$i] ne $a2->[$i]) {
      return 0;
    }
    $i++;
  }
  return (@$a1 == @$a2);
}

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::SacksSpiral::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SacksSpiral->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SacksSpiral->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SacksSpiral->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SacksSpiral->new;
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
  my $path = Math::PlanePath::SacksSpiral->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative() instance method');
  ok ($path->y_negative, 1, 'y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::SacksSpiral->parameter_info_list;
  ok (join(',',@pnames), '');
}


#------------------------------------------------------------------------------
# n_to_rsquared()

{
  my $path = Math::PlanePath::SacksSpiral->new;
  ok ($path->n_to_rsquared(0), 0);
  ok ($path->n_to_rsquared(1), 1);
  ok ($path->n_to_rsquared(20.5), 20.5);
}

#------------------------------------------------------------------------------
# xy_to_n

{
  my @data = ([ 0,0,  [0] ],
              [ 0.001,0.001,  [0] ],
              [ -0.001,0.001,  [0] ],
              [ 0.001,-0.001,  [0] ],
              [ -0.001,-0.001,  [0] ],
             );
  my $path = Math::PlanePath::SacksSpiral->new;
  foreach my $elem (@data) {
    my ($x, $y, $want_n_aref) = @$elem;
    my @got_n = $path->xy_to_n ($x,$y);
    ### @got_n
    ok (numeq_array (\@got_n, $want_n_aref),
        1, "xy_to_n x=$x y=$y");
  }
}

#------------------------------------------------------------------------------
# _rect_to_radius_range()

{
  foreach my $elem (
                    # single isolated point
                    [ 0,0, 0,0,  0,0 ],
                    [ 1,0, 1,0,  1,1 ],
                    [ -1,0, -1,0,  1,1 ],
                    [ 0,1, 0,1,  1,1 ],
                    [ 0,-1, 0,-1,  1,1 ],

                    [ 0,0, 1,0,  0,1 ],  # strip of x axis
                    [ 1,0, 0,0,  0,1 ],
                    [ 6,0, 3,0,   3,6 ],
                    [ -6,0, -3,0, 3,6 ],
                    [ -6,0, 3,0,  0,6 ],
                    [ 6,0, -3,0,  0,6 ],

                    [ 0,0, 0,1,  0,1 ],  # strip of y axis
                    [ 0,1, 0,0,  0,1 ],
                    [ 0,6, 0,3,   3,6 ],
                    [ 0,-6, 0,3,  0,6 ],
                    [ 0,-6, 0,-3, 3,6 ],
                    [ 0,6, 0,-3,  0,6 ],


                    [ 3,1, -3,4,   1,5 ],
                    [ -3,1, 3,4,   1,5 ],
                    [ -3,4, 3,1,   1,5 ],
                    [ 3,4, -3,1,   1,5 ],

                    [ 1,3, 4,-3,   1,5 ],
                    [ 1,-3, 4,3,   1,5 ],
                    [ 4,-3, 1,3,   1,5 ],
                    [ 4,3, 1,-3,   1,5 ],

                    [ -3,-4, 3,4,  0,5 ],
                    [ 3,-4, -3,4,  0,5 ],
                    [ 3,4, -3,-4,  0,5 ],
                    [ -3,4, 3,-4,  0,5 ],


                    [ 0,0, 3,4, 0,5 ],
                    [ 0,0, 3,-4, 0,5 ],
                    [ 0,0, -3,4, 0,5 ],
                    [ 0,0, -3,-4, 0,5 ],

                    [ 6,8, 3,4, 5,10 ],
                    [ 6,8, -3,-4, 0,10 ],
                    [ -6,-8, 3,4, 0,10 ],

                    [ -3,0, 3,4, 0,5 ],
                    [ 0,-3, 4,3, 0,5 ],

                    [ -6,1, 6,8,   1,10 ],  # x both, y positive
                    [ -6,-1, 6,-8, 1,10 ],  # x both, y negative
                    [ 1,-6, 8,6, 1,10 ],    # y both, x positive
                    [ -1,-6, -8,6, 1,10 ],  # y both, x negative

                   ) {
    ## no critic (ProtectPrivateSubs)

    my ($x1,$y1, $x2,$y2, $want_rlo,$want_rhi) = @$elem;
    my ($got_rlo,$got_rhi)
      = Math::PlanePath::SacksSpiral::_rect_to_radius_range ($x1,$y1, $x2,$y2);

    my $name = "_rect_to_radius_range()  $x1,$y1, $x2,$y2";
    ok ($got_rlo, $want_rlo, "$name, r lo");
    ok ($got_rhi, $want_rhi, "$name, r hi");
  }
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my $path = Math::PlanePath::SacksSpiral->new;
  foreach my $n (1 .. 50) {
    my ($x, $y) = $path->n_to_xy($n);
    my $x1 = 0;
    my $y1 = 0;
    my ($x2, $y2) = vector_towards_origin($x,$y,0.49);
    my ($got_n_lo, $got_n_hi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
    ### @got_n_lo
    ### @got_n_hi
    ok ($got_n_hi >= $n, 1,
        "hi want=$n got=$got_n_hi, at xy=$x,$y and range $x2,$y2");
  }
}

sub vector_towards_origin {
  my ($x,$y, $dist) = @_;
  my $r = sqrt($x*$x+$y*$y);
  my $frac = ($r-$dist)/$r;
  return ($x * $frac,
          $y * $frac);
}

exit 0;
