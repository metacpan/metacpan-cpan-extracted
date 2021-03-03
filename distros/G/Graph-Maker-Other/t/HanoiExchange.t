#!/usr/bin/perl -w

# Copyright 2021 Kevin Ryde
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
$|=1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 69;

require Graph::Maker::HanoiExchange;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::HanoiExchange::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::HanoiExchange->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::HanoiExchange->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::HanoiExchange->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  foreach my $N (0 .. 5) {
    my $graph = Graph::Maker->new('hanoi_exchange',
                                  discs => $N,
                                  undirected => 1);
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 3**$N,
        "N=$N num vertices");

    # per Stockmeyer et al section 2
    my $num_edges    = $graph->edges;
    ok ($num_edges, (3**($N+1) - 3)/2,
        "N=$N num edges");
  }
}

#------------------------------------------------------------------------------

{
  # discs=0
  foreach my $spindles (0 .. 5) {
    my $graph = Graph::Maker->new('hanoi_exchange',
                                  discs => 0,
                                  spindles => $spindles);
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 1);
  }
}
{
  # discs=1, directed
  my $graph = Graph::Maker->new('hanoi_exchange', discs => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 3);
  ok ($graph->is_directed?1:0, 1);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(1,0)?1:0, 1);

  ok ($graph->has_edge(1,2)?1:0, 1);
  ok ($graph->has_edge(2,1)?1:0, 1);

  ok ($graph->has_edge(2,1)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);
}
{
  my $graph = Graph::Maker->new('hanoi_exchange', discs => 2);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 9);

  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(0,2)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);

  ok ($graph->has_edge(0,4)?1:0, 0);
}

{
  # discs=3 per POD
  my $graph = Graph::Maker->new('hanoi_exchange', discs => 3,
                                undirected => 1, countedged => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 27);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(0,2)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);

  ok ($graph->has_edge(5,11)?1:0, 1);
  ok ($graph->has_edge(7,19)?1:0, 1);
  ok ($graph->has_edge(15,21)?1:0, 1);
}

#------------------------------------------------------------------------------

{
  foreach my $elem ([0,0],[1,0],[2,0],
                    # [3,0],
                    #                     [0,1],[1,1],[2,1],[3,1],
                    #                     [0,2],[1,2],[2,2],[3,2],[4,2],
                    #                     [0,3],[1,3],[2,3],[3,3],[4,3],
                    #                     [0,4],[1,4],[2,4],[5,4],
                   ) {
    my ($discs,$spindles) = @$elem;
    foreach my $undirected (0,1) {
      my $graph = Graph::Maker->new
        ('hanoi_exchange',
         discs      => $discs,
         spindles   => $spindles,
         undirected => $undirected,
         countedged => 1);

      my $bad = 0;
      my $want = $undirected ? 1 : 2;
      foreach my $edge ($graph->edges) {
        my $count = $graph->get_edge_count(@$edge);
        unless ($count == 1) {
          $bad++;     # a duplicate edge
        }
        my ($from,$to) = @$edge;
        if ($from eq $to) { $bad++; }
        unless ($undirected) {
          unless ($graph->has_edge($to,$from)) {
            $bad++;   # when directed graph, edge both ways
          }
        }
      }
      ok ($bad, 0, "no duplicate edges");
    }
  }
}

#------------------------------------------------------------------------------
# spindles = 1 or 2 per POD

{
  # spindles=1
  foreach my $discs (1 .. 5) {
    my $graph = Graph::Maker->new('hanoi_exchange', discs => $discs, spindles => 1);
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 1);
  }
}

{
  # spindles=2
  foreach my $undirected (0,1) {
    foreach my $discs (1..4) {
      my $graph = Graph::Maker->new
        ('hanoi_exchange',
         discs      => $discs,
         spindles   => 2,
         undirected => $undirected,
         multiedged => 1);
      ### graph: "$graph"
      ### edges: $graph->edges

      { my $num_vertices = $graph->vertices;
        ok ($num_vertices, 2**$discs);
      }
      { my $num_edges = $graph->edges;
        my $want = $discs == 1 ? 1 : 3 * 2**($discs-2);
        unless ($undirected) { $want *= 2; }
        ok ($num_edges, $want,
            "spindles=2 discs=$discs undirected=$undirected");
      }
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
