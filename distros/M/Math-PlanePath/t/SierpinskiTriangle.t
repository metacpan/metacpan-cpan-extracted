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
plan tests => 206;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::SierpinskiTriangle;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 128;
  ok ($Math::PlanePath::SierpinskiTriangle::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::SierpinskiTriangle->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::SierpinskiTriangle->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::SierpinskiTriangle->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::SierpinskiTriangle->new;
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
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 0, 'class_y_negative()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::SierpinskiTriangle->parameter_info_list;
  ok (join(',',@pnames), 'align,n_start');
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 2); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 8); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 26); }
}

#------------------------------------------------------------------------------
# tree_n_parent()

{
  my @data = ([ 0, undef ],
              [ 1,  0 ],
              [ 2,  0 ],

              [ 3,  1 ],
              [ 4,  2 ],

              [ 5,  3 ],
              [ 6,  3 ],
              [ 7,  4 ],
              [ 8,  4 ],

              [ 9,  5 ],
              [ 10, 8 ],
             );
  foreach my $align ('triangular','left','right','diagonal') {
    my $path = Math::PlanePath::SierpinskiTriangle->new (align => $align);
    foreach my $elem (@data) {
      my ($n, $want_n_parent) = @$elem;
      my $got_n_parent = $path->tree_n_parent ($n);
      ok ($got_n_parent, $want_n_parent,
          "tree_n_parent($n) align=$align");
    }
  }
}

#------------------------------------------------------------------------------
# tree_n_children()
{
  my @data = ([ 0,  '1,2' ],
              [ 1,  '3' ],
              [ 2,  '4' ],
              [ 3,  '5,6' ],
              [ 4,  '7,8' ],

              [ 5,  '9' ],
              [ 6,  '' ],
              [ 7,  '' ],
              [ 8,  '10' ],

              [ 9,  '11,12' ],
              [ 10, '13,14' ],
             );
  foreach my $align ('triangular','left','right','diagonal') {
    my $path = Math::PlanePath::SierpinskiTriangle->new (align => $align);
    foreach my $elem (@data) {
      my ($n, $want_n_children) = @$elem;
      my $got_n_children = join(',',$path->tree_n_children($n));
      ok ($got_n_children, $want_n_children, "tree_n_children($n)");
    }
  }
}

#------------------------------------------------------------------------------
# n_to_xy(),  xy_to_n()

{
  my @data = ([ 0, 0,0 ],
              [ 1, -1,1 ],
              [ 2,  1,1 ],

              [ 3,  -2,2 ],
              [ 4,  2,2 ],

              [ 5,  -3,3 ],
              [ 6,  -1,3 ],
              [ 7,  1,3 ],
              [ 8,  3,3 ],

              [ 9,  -4,4 ],
              [ 10,  4,4 ],

              [ 11,  -5,5 ],
              [ 12,  -3,5 ],
              [ 13,  3,5 ],
              [ 14,  5,5 ],

              [ 15,  -6,6 ],
              [ 16,  -2,6 ],
              [ 17,  2,6 ],
              [ 18,  6,6 ],
             );
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }

  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
    ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
    ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
  }
}


#------------------------------------------------------------------------------
# n_to_xy(), xy_to_n(), reversals

{
  my $bad = 0;
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  my $want_n = $path->n_start;
 OUTER: foreach my $y (0 .. 16) {
    foreach my $x (-$y .. $y) {
      my $got_n = $path->xy_to_n($x,$y);
      if (defined $got_n) {
        if ($want_n != $got_n) {
          MyTestHelpers::diag ("reversal xy=$x,$y  want_n=$want_n got_n=$got_n");
          last OUTER if ++$bad > 10;
        }
        $want_n++;
      }
    }
  }
  ok ($want_n > 10, 1);
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
exit 0;
