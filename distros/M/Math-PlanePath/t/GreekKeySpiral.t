#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 2251;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::GreekKeySpiral;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::GreekKeySpiral::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::GreekKeySpiral->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::GreekKeySpiral->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::GreekKeySpiral->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::GreekKeySpiral->new;
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
  my $path = Math::PlanePath::GreekKeySpiral->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->default_n_start, 1, 'default_n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');

  my @pnames = map {$_->{'name'}} $path->parameter_info_list;
  ok (join(',',@pnames), 'turns');
}

#------------------------------------------------------------------------------
# first few points

{
  my @groups = ([ { turns => 0 },
                  [ 1,  0,0 ],
                  [ 2,  1,0 ],
                  [ 3,  1,1 ],
                  [ 4,  0,1 ],
                  [ 5,  -1,1 ],
                  [ 6,  -1,0 ],
                  [ 7,  -1,-1 ],
                ],
                [ { turns => 1 },
                  [ 1,  0,0 ],
                  [ 2,  0,1 ],
                  [ 3,  1,1 ],
                  [ 4,  1,0 ],

                  [ 5,  2,0 ],
                  [ 6,  3,0 ],
                  [ 7,  3,1 ],
                  [ 8,  2,1 ],
                ],

                [ { turns => 2 },
                  [ 1,  0,0 ],
                  [ 2,  1,0 ],
                  [ 3,  1,1 ],
                  [ 4,  0,1 ],
                  [ 5,  0,2 ],
                  [ 6,  1,2 ],
                  [ 7,  2,2 ],
                  [ 8,  2,1 ],
                  [ 9,  2,0 ],

                  [ 10,  3,0 ],
                ],
               );
  foreach my $group (@groups) {
    my ($options, @data) = @$group;
    my $path = Math::PlanePath::GreekKeySpiral->new (%$options);
    my $turns = $options->{'turns'};

    foreach my $elem (@data) {
      my ($n, $x,$y) = @$elem;
      {
        my ($got_x,$got_y) = $path->n_to_xy($n);
        ok ($got_x == $x, 1, "turns=$turns n=$n");
        ok ($got_y == $y, 1);
      }
      {
        my @got_n_list = $path->xy_to_n_list($x,$y);
        ok (scalar(@got_n_list), 1);
        my $got_n_str = join(',', @got_n_list);
        ok ($got_n_str, $n);
      }
      {
        my $got_n = $path->xy_to_n($x,$y);
        ok ($got_n, $n);
      }
    }
  }
}

#------------------------------------------------------------------------------
# n_to_xy() fractions part way between integer points

{
  foreach my $turns (0, 1, 2, 3, 4, 5, 20) {
    my $path = Math::PlanePath::GreekKeySpiral->new (turns => $turns);
    my $bad = 0;

  PATH: foreach my $n ($path->n_start .. $path->n_start + 500) {
      my ($x,$y) = $path->n_to_xy ($n);
      my ($x2,$y2) = $path->n_to_xy ($n+1);

      foreach my $frac (0.25, 0.5, 0.75) {
        my $nfrac = $n + $frac;
        my ($got_xfrac,$got_yfrac) = $path->n_to_xy ($nfrac);
        my $want_xfrac = $x + $frac*($x2-$x);
        my $want_yfrac = $y + $frac*($y2-$y);
        if ($got_xfrac != $want_xfrac
            || $got_yfrac != $want_yfrac) {
          MyTestHelpers::diag ("xy frac at n=$nfrac");
          last PATH if $bad++ > 10;
        }
      }
    }
    ok ($bad, 0, "n_to_xy() fraction turns=$turns");
  }
}

#------------------------------------------------------------------------------
# xy_to_n() reversals

foreach my $turns (0, 1, 2, 3, 4, 5, 20) {
  my $path = Math::PlanePath::GreekKeySpiral->new (turns => $turns);
  my $bad = 0;

 PATH: foreach my $n ($path->n_start .. $path->n_start + $turns*$turns*128) {
    my ($x,$y) = $path->n_to_xy ($n);
    my $got_n = $path->xy_to_n ($x, $y);

    if ($got_n != $n) {
      MyTestHelpers::diag ("n=$n is $x,$y xy_to_n()=$got_n");
      last PATH if $bad++ > 10;
    }
  }
  ok ($bad, 0, "xy_to_n() reversals");
}

#------------------------------------------------------------------------------
# rect_to_n_range() first and last

foreach my $turns (2, 3, 4, 5, 20, 1, 0) {
  my $side = $turns+1;
  my $path = Math::PlanePath::GreekKeySpiral->new (turns => $turns);
  foreach my $i (1 .. 100) {

    my $x = $side*$i + $side-1;
    my $y = -$side*$i;
    my $n = $path->xy_to_n ($x,$y);
    my ($n_lo, $n_hi) = $path->rect_to_n_range (0,0, $x,$y);
    ok ($n_hi, $n, "rect_to_n_range() turns=$turns i=$i hi last x=$x,y=$y");

    $x++;
    $n++;
    ok ($path->xy_to_n($x,$y), $n);
    ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo, $n, "rect_to_n_range() turns=$turns  i=$i lo first x=$x,y=$y  n=$n");
  }
}

exit 0;
