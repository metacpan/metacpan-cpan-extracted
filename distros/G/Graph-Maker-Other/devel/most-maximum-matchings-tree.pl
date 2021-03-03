#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2019, 2020, 2021 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use 5.010;
use File::Slurp;
use List::Util 'min','max';
use POSIX 'ceil';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::MostMaximumMatchingsTree;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


#------------------------------------------------------------------------------

{
  # HOG
  # 
  my @graphs;
  foreach my $N (
                 # 6.5, 34.5, 0 .. 40
                 # 34,34.5,
                 # 26 .. 35,
                 35 .. 40
                ) {
    my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                  N => $N,
                                  coordinate_type => 'HW',
                                  undirected=>1);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  # MyGraphs::hog_upload_html($graphs[7]);
  exit 0;
}

{
  foreach my $N (2 .. 6) {
    print "n=$N\n";
    my $graph = Graph::Maker->new('most_maximum_matchings_tree', N => $N,
                                  coordinate_type => 'HW',
                                  undirected => 1);
    foreach my $v (sort $graph->vertices) {
      my $x = $graph->get_vertex_attribute($v,'x');
      my $y = $graph->get_vertex_attribute($v,'y');
      print "  v=$v  $x  $y\n";
    }
  }
  exit 0;
}




my @want_vpars
  = (
     [],
     [0],        # n=1
     [0,1],
     [0,1,1],
     [0,1,1,1],
     [0,1,1,1,1],  # n=5 star
     # [0,1,2,2,1,5],    \\ n=6 other
     [0,1,1,1,1,1],
     [0,1,2,2,1,5,5],
     [0,1,2,2,2,1,6,6],
     [0,1,2,2,2,1,6,6,6],
     [0,1,2,3,3,1,6,7,7,1],
     [0,1,2,3,3,1,6,7,7,1,1],
     [0,1,2,3,3,3,1,7,8,8,1,1],
     [0,1,2,3,3,3,1,7,8,8,8,1,1],
     [0,1,2,3,3,1,6,7,7,1,10,11,11,1],
     [0,1,2,3,4,4,2,2,1,9,10,11,11,9,9],
     [0,1,2,3,4,4,4,2,2,1,10,11,12,12,10,10],
     [0,1,2,3,3,1,6,7,7,1,10,11,11,1,14,15,15],
     [0,1,2,3,4,4,2,7,8,8,2,1,12,13,14,14,12,12],
     [0,1,2,3,4,5,5,3,3,1,10,11,12,13,13,11,11,1,1],
     [0,1,2,3,4,5,5,5,3,3,1,11,12,13,14,14,12,12,1,1],
     [0,1,2,3,4,4,2,7,8,8,2,1,12,13,14,14,12,17,18,18,12],
     [0,1,2,3,4,5,5,3,3,1,10,11,12,13,13,11,11,1,18,19,19,1],
     [0,1,2,3,4,5,6,6,4,4,2,2,1,13,14,15,16,17,17,15,15,13,13],
     [0,1,2,3,4,4,2,7,8,8,2,11,12,12,1,15,16,17,17,15,20,21,21,15],
     [0,1,2,3,4,5,5,3,8,9,9,3,1,13,14,15,16,16,14,14,1,21,22,22,1],
     [0,1,2,3,4,5,5,3,3,1,10,11,12,13,13,11,11,1,18,19,20,21,21,19,19,1],
     [0,1,2,3,4,4,2,7,8,8,2,11,12,12,1,15,16,17,17,15,20,21,21,15,24,25,25],
     [0,1,2,3,4,5,5,3,8,9,9,3,1,13,14,15,16,16,14,19,20,20,14,1,24,25,25,1],
    );
sub want_Graph {
  my ($n) = @_;
  my $vpar = $want_vpars[$n];
  $vpar = [undef, @$vpar];
  return MyGraphs::Graph_from_vpar ($vpar, undirected => 1);
}
{
  foreach my $N (0 .. $#want_vpars) {
    my $N7 = $N % 7;
    my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                  N => $N,
                                  undirected=>1);
    my $want = want_Graph($N);
    print "N=$N $N7 isomorphic ",MyGraphs::Graph_is_isomorphic($graph,$want),"\n";
    my $num_vertices = $graph->vertices;
    if ($num_vertices != $N) {
      print "  num vertices $num_vertices\n";
    }
  }
}


{
  foreach my $N (@ARGV,
                 # 5 ..8,
                 # 3*7+6,
                 34,  34.5,
                 # 181,
                 # 11,
                 # 12,
                 # 13,
                 # 14 .. 16
                ) {
    # my $N = 7*$k + 3;
    print "N = $N\n";
    my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                  N => $N,
                                  coordinate_type => 'HW',
                                  undirected=>1);
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $name = $graph->get_graph_attribute('name');
    print "$num_vertices vertices, $num_edges edges  $name\n";

    MyGraphs::Graph_view($graph);
  }
  exit 0;
}
{
  # Synchronous Views
  foreach my $o (6, 1 .. 6, 0) {
    foreach my $k (0 ..
                   ($o == 4 || $o == 1 ? 5
                    : $o == 0 ? 6
                    : 18)) {
      my $N = 7*$k + $o;
      print "N = $N  = 7*$k + $o\n";
      my $graph = Graph::Maker->new('most_maximum_matchings_tree',
                                    N => $N,
                                    coordinate_type => 'HW',
                                    undirected=>1);
      my $num_vertices = $graph->vertices;
      my $num_edges = $graph->edges;
      my $name = $graph->get_graph_attribute('name');
      print "$num_vertices vertices, $num_edges edges  $name\n";

      MyGraphs::Graph_view($graph, synchronous => 1);
    }
  }
  exit 0;
}


{
  # matchnum in most ways

  # HOG got E?NO  n=6
  # HOG got E?Bw  n=6
  # HOG got F?AZO  n=7
  # HOG got H???C\q  n=9
  # HOG got I???BGY`_  n=10

  # n=6 matchnum 2 ways 5     6-star
  # n=6 matchnum 1 ways 5    *--*--*--*--*
  # .                                  \-*

  # n=7 matchnum 2 ways 8    *--*--*--*--*
  # .                        *-/       \-*
  # GP-Test  3*3 - 1 == 8
  # GP-Test  2*3 + 2 == 8

  # n=9 matchnum 2 ways 15   *-\       /-*
  # .                        *--*--*--*--*
  # .                        *-/       \-*
  # GP-Test  3*4 + 3 == 15

  # n=10 matchnum 3 ways 21  *--*--*--*--*--*--*
  # .                           |     |     |
  # .                           *     *     *
  # GP-Test  2*2*3 + 2*1*2 + 1*1*3 + 1*1*2 == 21

  my @strs = qw(
                 :Ccf
                 :DaGb
                 :EaXbN
                 :EaGaN
                 :FaXbK
                 :GaXeLv
                 :H`EKWTjV
                 :I`ESgTlYF
                 :J`ESgTlYCN
                 :K`EShOl]{G^
               :L`EShOl]|wO
             :M`ESgTlYE\Y`
             :N`ESxpbBE\Ypb
             :O`ESxrbEE\ZvfN
             :P_`aa_dee_hii_lmm
              );
  my @graphs = map {MyGraphs::Graph_from_graph6_str($_)} @strs;
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
