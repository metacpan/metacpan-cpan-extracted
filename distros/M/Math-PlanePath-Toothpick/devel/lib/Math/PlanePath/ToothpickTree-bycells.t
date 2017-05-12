#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


# Compare ToothpickTree.pm and ToothpickTreeByCells.pm.
#

use 5.004;
use strict;
use Test;
plan tests => 376;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::ToothpickTree;
require Math::PlanePath::ToothpickTreeByCells;

require Math::PlanePath::SquareSpiral;
my $sq = Math::PlanePath::SquareSpiral->new;


#------------------------------------------------------------------------------
# n_to_xy()

my $bad = 0;
my $report = sub {
  MyTestHelpers::diag ('bad: ', @_);
  $bad++;
  if ($bad > 10) {
    die "Too many errors";
  }
};

foreach my $parts ('two_horiz', 'wedge', '1', 'octant', 'octant_up', '3', '4', '2',
                  ) {
  MyTestHelpers::diag ($parts);

  my $path = Math::PlanePath::ToothpickTree->new (parts => $parts);
  my $cells = Math::PlanePath::ToothpickTreeByCells->new (parts => $parts);

  my $n = $path->n_start;
  my $sqn = $sq->n_start;
  my $sq_limit = 0;

  for (my $depth = 0; $depth < 64+10; $depth++) {
    my ($n_depth, $n_depth_end) = $path->tree_depth_to_n_range($depth);
    {
      my $cells_n_depth = $cells->tree_depth_to_n($depth);
      unless ($n_depth == $cells_n_depth) {
        &$report("parts=$parts tree_depth_to_n($depth) = $n_depth cf cells $cells_n_depth");
      }
    }

    for ( ; $n <= $n_depth_end; $n++) {
      {
        my $got_depth = $path->tree_n_to_depth($n);
        unless (equal($got_depth, $depth)) {
          &$report("parts=$parts tree_n_to_depth($n) got $got_depth want $depth");
        }
      }
      {
        my ($x,$y) = $path->n_to_xy($n);
        my ($cx,$cy) = $cells->n_to_xy($n);
        unless (equal($x,$cx) && equal($y,$cy)) {
          &$report("parts=$parts n_to_xy($n) depth=$depth got $x,$y cf cells $cx,$cy");
        }
      }
    }
    next;
    for (;;) {
      my ($x,$y) = $sq->n_to_xy($sqn++);
      my $n = $path->xy_to_n($x,$y);
      my $cn = $cells->xy_to_n($x,$y);
      unless (equal($n,$cn)) {
        &$report("parts=$parts xy_to_n($x,$y) got ",$n," cf cells ",$cn);
      }
      last if abs($x) > $sq_limit && abs($y) > $sq_limit;
    }
    $sq_limit++;

    ok (1,1);
  }
}

sub equal {
  my ($x,$y) = @_;
  return ((! defined $x && ! defined $y)
          || (defined $x && defined $y && $x == $y));
}

#------------------------------------------------------------------------------
exit 0;
