#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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

use Graph::Maker::Beineke;

use lib
  'devel/lib';
use MyGraphs 'Graph_is_isomorphic','Graph_is_subgraph';

plan tests => 25;

# uncomment this to run the ### lines
# use Smart::Comments;

#------------------------------------------------------------------------------
# subgraph relations
# with vertex numbering exactly

{
  my @data = (undef,
              [1,2,3,4,5,6,7,8,9],  # G1 subgraph of all
              [3,5,6],
              [],                   # G3
              [6,7,9],
              [6],                  # G5
              [],
              [6,9],                # G7
             );
  foreach my $sub_g (1 .. $#data) {
    my $subgraph = Graph::Maker->new('Beineke', G=>$sub_g, undirected=>1);
    my $aref = $data[$sub_g];
    foreach my $super_g (@$aref) {
      my $supergraph = Graph::Maker->new('Beineke', G=>$super_g, undirected=>1);
      ### $sub_g
      ### $super_g
      ok (Graph_is_subgraph_exactly($subgraph, $supergraph));
    }
  }
}

sub Graph_is_subgraph_exactly {
  my ($subgraph, $supergraph) = @_;
  foreach my $edge ($subgraph->edges) {
    if (! $supergraph->has_edge(@$edge)) {
      return 0;
    }
  }
  return 1;
}


#------------------------------------------------------------------------------

{
  foreach my $elem (
                    [2,
                     # G2    1--\
                     #      / \  \
                     #     2---3  5
                     #      \ /  /
                     #       4--/
                     # https://hog.grinvin.org/ViewGraphInfo.action?id=438
                     [1,2],[1,3],[1,5],
                     [2,3],[2,4],
                     [3,4],
                     [5,4],
                    ],
                    [3,
                     # G3 = K5-e complete 5 less one edge
                     #      1
                     #     /|\
                     #    / 2 \
                     #   / /|\ \
                     #  / / 3 \ \
                     #  |/ / \ \ |
                     #  4--------5
                     # https://hog.grinvin.org/ViewGraphInfo.action?id=450
                     #
                     [1,2],[1,4],[1,5],
                     [2,3],[2,4],[2,5],
                     [3,4],[3,5],
                     [4,5],
                    ],
                    [4,
                     # G4   1----5
                     #     / \
                     #    2---3
                     #     \ /
                     #      4----6
                     # https://hog.grinvin.org/ViewGraphInfo.action?id=922
                     #
                     [1,2],[1,3],[1,5],
                     [2,3],[2,4],
                     [3,4],
                     [4,6],
                    ],
                    [5,
                     # G5    1
                     #      /|\
                     #     / 3 \
                     #    / / \ \
                     #    2-----4
                     #     \    /
                     #      \  /
                     #       5----6
                     # https://hog.grinvin.org/ViewGraphInfo.action?id=21099
                     #
                     [1,2],[1,5],[1,3],
                     [2,5],[2,3],[2,4],
                     [3,4],[3,5],
                     [4,6],
                    ],
                    [6,
                     # G6    1
                     #      /|\
                     #     / 3 \
                     #    / / \ \
                     #    2-----4
                     #    \ \ / /
                     #     \ 5 /
                     #      \|/
                     #       6
                     # https://hog.grinvin.org/ViewGraphInfo.action?id=744
                     #
                     [1,2],[1,5],[1,3],
                     [2,5],
                     [2,3],[2,6],[2,4],
                     [3,5],[3,6],[3,4],
                     [4,6],
                    ],
                    [7,
                     # G7   1----5
                     #     / \   |
                     #    2---3  |
                     #     \ /   |
                     #      4----6
                     # https://hog.grinvin.org/ViewGraphInfo.action?id=21093
                     #
                     [1,2],[1,3],[1,5],
                     [2,3],[2,4],
                     [3,4],
                     [4,6],
                     [5,6],
                    ],
                    [8,
                     # G8 1---2
                     #    | / |
                     #    3---4
                     #    | / |
                     #    5---6
                     # https://hog.grinvin.org/ViewGraphInfo.action?id=21096
                     #
                     [1,2],[1,3],
                     [2,3],[2,4],
                     [3,4],[3,5],
                     [4,5],[4,6],
                     [5,6],
                    ],
                   ) {
    my ($g, @edges) = @$elem;
    my $prev = Graph->new(undirected=>1);
    $prev->add_edges(@edges);

    my $G = Graph::Maker->new('Beineke', G=>$g, undirected=>1);
    ok (Graph_is_isomorphic($prev,$G), 1, "G$g");

    # if (! Graph_is_isomorphic($prev,$G)) {
    #   print "$g\n";
    #   MyGraphs::Graph_view($prev);
    #   MyGraphs::Graph_view($G);
    # }
  }
}


#------------------------------------------------------------------------------
exit 0;
