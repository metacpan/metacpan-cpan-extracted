#!/usr/bin/perl -w

# Copyright 2020, 2021 Kevin Ryde
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

use 5.005;
use strict;
use Graph;
use List::Util 'min','max','sum';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use Graph::Maker::BinomialBoth;
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Wythoff game to 3,2 up to symmetry
  # https://hog.grinvin.org/ViewGraphInfo.action?id=44086
  #
  # decrease i by any
  # decrease j by any
  # decrease i and j both by same amount
  #
  # Eric Duchene, Aviezri S. Fraenkel, Richard J. Nowakowski, Michel Rigo,
  # "Extensions and Restrictions of Wythoff's Game Preserving Wythoff's
  # Sequence As Set of P Positions",
  # http://www.discmath.ulg.ac.be/
  # J. Combin. Theory Ser. A. volume 117, 2010, pages 545-567
  #
  # Slides:
  # http://hdl.handle.net/2268/100440
  # https://orbi.uliege.be/bitstream/2268/100440/2/Wythoff-adj2.pdf

  #
  # GP-Test  2+5+1+3+1 + 5+6+3 == 26    /* edges */

  my $ordered = 0;
  my $graph = Graph->new (undirected => 1);
  my $limit = 3;
  my $to_vertex_name = sub {
    my ($i,$j) = @_;
    unless ($ordered) { ($i,$j) = sort {$b<=>$a} $i,$j; }
    ($i >= 0 && $j >=0) or die;
    "$i,$j";
  };
  foreach my $i (0 .. $limit) {
    foreach my $j (0 .. $limit-1) {
      my $from = $to_vertex_name->($i,$j);
      foreach my $k (1 .. $i) {
        $graph->add_edge($from, $to_vertex_name->($i-$k, $j));
      }
      foreach my $k (1 .. $j) {
        $graph->add_edge($from, $to_vertex_name->($i, $j-$k));
      }
      foreach my $k (1 .. min($i,$j)) {
        $graph->add_edge($from, $to_vertex_name->($i-$k, $j-$k));
      }
    }
  }
  # $graph = $graph->complement;
  MyGraphs::Graph_set_xy_points($graph,
                                '3,2' => [ 0,    2   ],
                                '3,1' => [ 1,    1.72],
                                '3,0' => [ 1.75,  .9 ],
                                '2,0' => [ 1.75, 0   ],
                                '2,2' => [-1,    1.72],
                                '2,1' => [-1.75,  .9 ],
                                '1,1' => [-1.75, 0   ],
                                '1,0' => [0,     0   ],
                                '0,0' => [0,     -.9 ],
                               );

  MyGraphs::Graph_view($graph, scale=>4);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "  graph $num_vertices vertices $num_edges edges\n";
  MyGraphs::Graph_print_tikz($graph);
  foreach my $v (reverse sort $graph->vertices) {
    print "$v degree ",$graph->in_degree($v)+$graph->out_degree($v),"\n";
  }
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);
  exit 0;
}


# LocalWords: Wythoff
