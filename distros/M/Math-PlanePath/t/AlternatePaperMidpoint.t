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
plan tests => 176;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Devel::Comments;

require Math::PlanePath::AlternatePaperMidpoint;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::AlternatePaperMidpoint::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::AlternatePaperMidpoint->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::AlternatePaperMidpoint->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::AlternatePaperMidpoint->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::AlternatePaperMidpoint->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# first few values

{
  my @data = ([ 0,     0,0 ],
              [ 0.25,  0.25, 0 ],
              [ 0.75,  0.75, 0 ],
              [ 1,     1,0 ],
              [ 1.25,  1.25, 0 ],
              [ 1.75,  1.75, 0 ],
              [ 2,     2,0 ],
              [ 2.25,  2, 0.25 ],
              [ 2.75,  2, 0.75 ],
              [ 3,     2,1 ],
             );
  my $path = Math::PlanePath::AlternatePaperMidpoint->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n == int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::AlternatePaperMidpoint->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative ? 1 : 0, 0, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
  ok ($path->class_x_negative, 1, 'class_x_negative()');
  ok ($path->class_y_negative, 1, 'class_y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::AlternatePaperMidpoint->parameter_info_list;
  ok (join(',',@pnames), 'arms');
}

{
  my $path = Math::PlanePath::AlternatePaperMidpoint->new (arms => 2);
  ok ($path->x_negative ? 1 : 0, 0, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaperMidpoint->new (arms => 3);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaperMidpoint->new (arms => 4);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 0, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaperMidpoint->new (arms => 5);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 1, 'y_negative() instance method');
}
{
  my $path = Math::PlanePath::AlternatePaperMidpoint->new (arms => 8);
  ok ($path->x_negative ? 1 : 0, 1, 'x_negative() instance method');
  ok ($path->y_negative ? 1 : 0, 1, 'y_negative() instance method');
}

#------------------------------------------------------------------------------
# random rect_to_n_range()

foreach my $arms (1 .. 8) {
  my $path = Math::PlanePath::AlternatePaperMidpoint->new (arms => $arms);
  for (1 .. 5) {
    my $bits = int(rand(25));     # 0 to 25, inclusive
    my $n = int(rand(2**$bits));  # 0 to 2^bits, inclusive

    my ($x,$y) = $path->n_to_xy ($n);

    my $rev_n = $path->xy_to_n ($x,$y);
    ok (defined $rev_n, 1,
        "arms=$arms  xy_to_n($x,$y) reverse n, got undef");

    my ($n_lo, $n_hi) = $path->rect_to_n_range ($x,$y, $x,$y);
    ok ($n_lo <= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_lo=$n_lo");
    ok ($n_hi >= $n, 1,
        "rect_to_n_range() n=$n at xy=$x,$y cf got n_hi=$n_hi");
  }
}

#------------------------------------------------------------------------------
# matching AlternatePaper

require Math::PlanePath::AlternatePaper;
foreach my $arms (1 .. 8) {
  my $bad = 0;
  my $paper    = Math::PlanePath::AlternatePaper->new (arms => $arms);
  my $midpoint = Math::PlanePath::AlternatePaperMidpoint->new (arms => 8);
 NN: foreach my $n (0 .. 64) {
    foreach my $arm (0 .. $arms-1) {
      my $pn = $n*$arms + $arm;
      my $mn = $n*8 + (($arm+1)%8);
      my ($x1,$y1) = $paper->n_to_xy($pn);
      my ($x2,$y2) = $paper->n_to_xy($pn+$arms);
      my ($mx,$my) = $midpoint->n_to_xy($mn);

      my $x = $x1+$x2;    # midpoint*2
      my $y = $y1+$y2;
      ($x,$y) = (($x-$y+1)/2,
                 ($x+$y+1)/2);  # rotate -45 and shift

      if ($x != $mx || $y != $my) {
        MyTestHelpers::diag("arms=$arms n=$n,arm=$arm pn=$pn paper $x1,$y1 to $x2,$y2 is $x,$y cf midpoint mn=$mn $mx,$my");
        last NN if $bad++ > 10;
      }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# matching AlternatePaper, 8arms at arm-1

{
  require Math::PlanePath::AlternatePaper;
  my $paper    = Math::PlanePath::AlternatePaper->new (arms => 8);
  my $midpoint = Math::PlanePath::AlternatePaperMidpoint->new (arms => 8);
  my @arm_map = (7,0,1,2,3,4,5,6);

  my $bad = 0;
  foreach my $n (0 .. 256) {
    my ($x1,$y1) = $paper->n_to_xy($n);
    my ($x2,$y2) = $paper->n_to_xy($n+8);

    my $mn = ($n & ~7) | $arm_map[$n&7];
    my ($mx,$my) = $midpoint->n_to_xy($mn);

    my $x = $x1+$x2;    # midpoint*2
    my $y = $y1+$y2;
    ($x,$y) = (($x+$y-1)/2,
               ($y-$x-1)/2);

    if ($x != $mx || $y != $my) {
      MyTestHelpers::diag("8arm n=$n paper $x1,$y1 to $x2,$y2 is $x,$y cf midpoint mn=$mn $mx,$my");
      last if $bad++ > 10;
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
exit 0;
