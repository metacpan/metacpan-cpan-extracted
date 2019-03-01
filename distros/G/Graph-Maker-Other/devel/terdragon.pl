#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
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
use Math::BaseCnv 'cnv';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::GosperIsland;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # alternate terdragon

  sub xy_rotate_plus120 {
    my ($x, $y) = @_;
    return (($x+3*$y)/-2,  # rotate +120
            ($x-$y)/2);
  }
  sub xy_rotate_minus120 {
    my ($x, $y) = @_;
    return ((3*$y-$x)/2,              # rotate -120
            ($x+$y)/-2);
  }
  sub alternate_terdragon_turn {
    my ($n) = @_;
    $n >= 1 or die;
    my $ret = 1;
    while ($n % 3 == 0) { $n /= 3; $ret = -$ret; }
    return ($n % 3 == 1 ? $ret : -$ret);
  }
  sub Graph_make_alternate_terdragon {
    my ($num_edges) = @_;
    require Graph;
    my $graph = Graph->new(undirected=>1);
    $graph->set_graph_attribute (vertex_name_type_xy => 1);
    my $x = 0;
    my $y = 0;
    $graph->add_vertex("$x,$y");
    if ($num_edges) {
      my $dx = 2;
      my $dy = 0;
      foreach my $n (1 .. $num_edges) {
        my $x2 = $x + $dx;
        my $y2 = $y + $dy;
        if (alternate_terdragon_turn($n) == 1) {
          ($dx,$dy) = xy_rotate_plus120($dx,$dy);
        } else {
          ($dx,$dy) = xy_rotate_minus120($dx,$dy);
        }
        $graph->add_edge("$x,$y", "$x2,$y2");
        ($x,$y) = ($x2,$y2);
      }
    }
    return $graph;
  }
  my @graphs;
  foreach my $n (4,5,6,
                 7,8,9,11, 3**3, 3**4, 3**6) {
    my $graph = Graph_make_alternate_terdragon($n);
    # MyGraphs::Graph_view($graph, xy=>1);
    print "----------\n";
    print "n=$n\n";
    MyGraphs::Graph_xy_print_triangular($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # HOG by planepath

  require Graph::Maker::PlanePath;
  my @graphs;
  for (my $k = 0; ; $k++) {
    if (@graphs > 3) {
      print "stop at ",scalar(@graphs)," graphs\n";
      last;
    }

    my $graph = Graph::Maker->new('planepath',
                                  undirected=>1,
                                  level=>$k,
                                  planepath => 'TerdragonCurve',
                                  # type => 'neighbours6',
                                 );
    $graph->set_graph_attribute (vertex_name_type_xy => 1);

    # next if $graph->vertices == 0;
    my $num_vertices = $graph->vertices;
    if ($num_vertices > 200) {
      print "stop for num_vertices = $num_vertices\n";
      last;
    }

    MyGraphs::Graph_view($graph, xy=>1);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
