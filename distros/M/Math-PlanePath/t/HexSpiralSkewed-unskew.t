#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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
plan tests => 168;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::HexSpiral;
use Math::PlanePath::HexSpiralSkewed;


foreach my $n_start (1, 0) {
  my $plain  = Math::PlanePath::HexSpiral->new (n_start => $n_start);
  my $skewed = Math::PlanePath::HexSpiralSkewed->new (n_start => $n_start);

  foreach my $n ($n_start .. $n_start+20) {
    my ($plain_x, $plain_y)   = $plain->n_to_xy ($n);
    my ($skewed_x, $skewed_y) = $skewed->n_to_xy ($n);
    {
      my ($conv_x,$conv_y) = (($plain_x-$plain_y)/2, $plain_y);
      ok ($conv_x == $skewed_x, 1,
          "plain->skewed x at n=$n plain $plain_x,$plain_y skewed $skewed_x,$skewed_y");
      ok ($conv_y == $skewed_y, 1,
          "plain->skewed y at n=$n");
    }
    {
      my ($conv_x,$conv_y) = ((2*$skewed_x+$skewed_y), $plain_y);
      ok ($conv_x == $plain_x, 1, "skewed->plain x at n=$n");
      ok ($conv_y == $plain_y, 1, "skewed->plain y at n=$n");
    }
  }
}

exit 0;
