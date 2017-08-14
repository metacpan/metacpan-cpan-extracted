#!/usr/bin/perl -w

# Copyright 2016, 2017 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 257;

use lib
  'devel/lib';
require Graph::Maker::Dragon;


#------------------------------------------------------------------------------
# _n_to_xy_dxdy vs PlanePath

{
  require Math::PlanePath::DragonCurve;
  my $path = Math::PlanePath::DragonCurve->new;
  foreach my $n (0 .. 256) {
    my ($got_x,$got_y, $got_dx,$got_dy) = Graph::Maker::Dragon::_n_to_xy_dxdy($n);
    my ($want_x,$want_y) = $path->n_to_xy($n);
    my ($want_dx,$want_dy) = $path->n_to_dxdy($n);
    ok ("$got_x,$got_y $got_dx,$got_dy",
        "$want_x,$want_y $want_dx,$want_dy",
        "at N=$n");
  }
}

#------------------------------------------------------------------------------
exit 0;
