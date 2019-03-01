#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019 Kevin Ryde
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

plan tests => 22;

require Graph::Maker::RookGrid;


#------------------------------------------------------------------------------
{
  my $want_version = 13;
  ok ($Graph::Maker::RookGrid::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::RookGrid->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::RookGrid->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::RookGrid->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # empty
  my $graph = Graph::Maker->new('rook_grid');
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
}
{
  # dims empty
  my $graph = Graph::Maker->new('rook_grid', dims => []);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
}

{
  # 3x4 per POD
  my $graph = Graph::Maker->new('rook_grid', dims => [3,4],
                                undirected => 1);
  ### graph: "$graph"
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 12);

  ok (join(',', sort {$a<=>$b} $graph->neighbours(1)), '2,3,4,5,9');
  ok (join(',', sort {$a<=>$b} $graph->neighbours(2)), '1,3,4,6,10');
  ok (join(',', sort {$a<=>$b} $graph->neighbours(7)), '3,5,6,8,11');
}

# 2x2,2x3 = circular ladder, per POD
# CircularLadder 1 rung gets self loops
foreach my $N (2..4) {
  my $rook = Graph::Maker->new('rook_grid', undirected => 1, dims => [2,$N]);
  require Graph::Maker::CircularLadder;
  my $circular_ladder = Graph::Maker->new('circular_ladder', undirected => 1,
                                          rungs => $N);
  ok ($circular_ladder->eq($rook)?1:0, ($N<=3 ? 1 : 0));

  # print "$rook\n";
  # print "$circular_ladder\n";
  # require MyGraphs; MyGraphs::Graph_view($rook);
}


#------------------------------------------------------------------------------

# Not N=1 since Graph::Maker::Complete version 0.01 gives an empty graph for
# that.
#
require Graph::Maker::Complete;
foreach my $N (2 .. 5) {
  # 1xN same as Complete
  my $rook = Graph::Maker->new('rook_grid', dims => [1,$N], undirected => 1);
  my $comp = Graph::Maker->new('complete', N => $N, undirected => 1);
  ok ("$rook", "$comp", "Rook = Complete $N");

  # require MyGraphs;
  # MyGraphs::Graph_view($rook);
  # MyGraphs::Graph_view($comp);
}

# Not N=1 since Graph::Maker::Complete version 0.01 gives an empty graph for
# that.
#
require Graph::Maker::Hypercube;
foreach my $N (1 .. 5) {
  # 1xN same as Hypercube
  my $rook = Graph::Maker->new('rook_grid', dims => [(2)x$N], undirected => 1);
  my $comp = Graph::Maker->new('hypercube', N => $N, undirected => 1);
  ok ("$rook", "$comp", "Rook = Hypercube $N");

  # require MyGraphs;
  # MyGraphs::Graph_view($rook);
  # MyGraphs::Graph_view($comp);
}



#------------------------------------------------------------------------------
exit 0;
