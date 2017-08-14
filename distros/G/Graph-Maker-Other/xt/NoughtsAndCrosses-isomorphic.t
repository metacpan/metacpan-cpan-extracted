#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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


plan tests => 7;

use Graph::Maker::NoughtsAndCrosses;

use lib
  'devel/lib';
use MyGraphs;


#------------------------------------------------------------------------------
# 2x2

{
  #  2x2 1-player equivalent to half a tesseract
  #
  my $noughts = Graph::Maker->new('noughts_and_crosses',
                                  N => 2,
                                  players => 1,
                                  undirected => 1);
  ok (scalar($noughts->vertices), 11);
  ok (scalar($noughts->edges), 16);

  my @centres = $noughts->centre_vertices;
  ok (scalar(@centres), 1);
  ok (join(',',sort @centres), '0000');

  require Graph::Maker::Hypercube;
  my $tesseract = Graph::Maker->new('hypercube',
                                    N => 4,
                                    undirected => 1);
  ok (scalar($tesseract->edges), 2*16);

  ok (!! MyGraphs::Graph_is_induced_subgraph($tesseract,$noughts), 1);


  # half by deleting one vertex and its neighbours
  my @vertices = $tesseract->vertices;
  my $v = $vertices[0];
  my @delete = ($vertices[0]);
  $tesseract->delete_vertices($v, $tesseract->neighbours($v));

  ok (!! MyGraphs::Graph_is_isomorphic($tesseract,$noughts), 1);

  # MyGraphs::Graph_view($tesseract);
  # MyGraphs::Graph_view($noughts);
}

#------------------------------------------------------------------------------
exit 0;
