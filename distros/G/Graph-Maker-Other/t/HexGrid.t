#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 12;

require Graph::Maker::HexGrid;


#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::HexGrid::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::HexGrid->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::HexGrid->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::HexGrid->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # empty
  my $graph = Graph::Maker->new('hex_grid', dims => [0,0,0]);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
  my $num_edges = $graph->edges;
  ok ($num_edges, 0);
}
{
  # dims empty
  my $graph = Graph::Maker->new('hex_grid', dims => [0,0,0]);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
  my $num_edges = $graph->edges;
  ok ($num_edges, 0);
}

foreach my $undirected (0, 1) {
  # 1x1x1 = 6-cycle
  my $graph = Graph::Maker->new('hex_grid', dims => [1,1,1],
                                undirected => $undirected);
  ### graph: "$graph"
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 6);

  my $num_edges = $graph->edges;
  ok ($num_edges, 6 * ($undirected ? 1 : 2));
}


# ENHANCE-ME: How many by dimensions ?
#
# foreach my $a (1 .. 4) {
#   foreach my $b (1 .. 4) {
#     foreach my $c (1 .. 4) {
#       foreach my $undirected (0, 1) {
#         foreach my $multiedged (0, 1) {
#           # 1x1x1 = 6-cycle
#           my $graph = Graph::Maker->new('hex_grid', dims => [$a,$b,$c],
#                                         undirected => $undirected,
#                                         multiedged => $multiedged);
#           ### graph: "$graph"
#           my $num_vertices = $graph->vertices;
#           ok ($num_vertices, $a*$b*$c);
# 
#           my $num_edges = $graph->edges;
#           ok ($num_edges, 6 * ($undirected ? 1 : 2));
#         }
#       }
#     }
#   }
# }

#------------------------------------------------------------------------------
exit 0;
