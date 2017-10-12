#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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
use List::Util 'min','max','sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::TwinAlternateAreaTree;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # HOG graphs

  # k=0  https://hog.grinvin.org/ViewGraphInfo.action?id=1310    single vertex
  # k=1  https://hog.grinvin.org/ViewGraphInfo.action?id=19655   path-2
  # k=2  https://hog.grinvin.org/ViewGraphInfo.action?id=594     path-4
  # k=3  https://hog.grinvin.org/ViewGraphInfo.action?id=260
  # k=4  https://hog.grinvin.org/ViewGraphInfo.action?id=27042
  # k=5  https://hog.grinvin.org/ViewGraphInfo.action?id=27044
  # k=6  https://hog.grinvin.org/ViewGraphInfo.action?id=27046
  require MyGraphs;
  my @graphs;
  foreach my $level (3) {
    my $graph = Graph::Maker->new ('twin_alternate_area_tree',
                                   level => $level,
                                   undirected => 1,
                                   vertex_name_type => 'xy',
                                  );
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    print "$num_vertices vertices $num_edges edges, diameter $diameter\n";
    MyGraphs::Graph_xy_print($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # sample picture for POD

  my $level = 6;
  my $scale_y = 2;
  my $scale_x = 4;

  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => 80, -height => 30);
  my $offset_x = 40;
  my $offset_y = 20;

  my $draw_text = sub {
    my ($x,$y, $str) = @_;
    $y = -$y;
    $x *= $scale_x;
    $y *= $scale_y;
    $x += $offset_x;
    $y += $offset_y;
    $x -= length($str)-1;
    foreach my $i (0 .. length($str)-1) {
      $image->xy($x+$i,$y, substr($str,$i,1));
    }
  };
  my $draw_line = sub {
    my ($x,$y, $x2,$y2) = @_;
    $y = -$y;
    $y2 = -$y2;
    my $dx = $x2-$x; if ($dx) { $dx /= abs($dx); }
    my $dy = $y2-$y; if ($dy) { $dy /= abs($dy); }
    my $char = $dx ? '-' : '|';
    $x *= $scale_x;
    $y *= $scale_y;
    $x += $offset_x;
    $y += $offset_y;
    $x2 *= $scale_x;
    $y2 *= $scale_y;
    $x2 += $offset_x;
    $y2 += $offset_y;
    ### line: "$x,$y to $x2,$y2  by $dx,$dy"
    while ($x != $x2 || $y != $y2) {
      ### at: "$x,$y"
      if ($image->xy($x,$y) eq ' ') {
        $image->xy($x,$y, $char);
      }
      $x += $dx;
      $y += $dy;
    }
  };

  my @vertex_xy_by_z;
  # want both N number and X,Y
  require Math::PlanePath::ZOrderCurve;
  my $path = Math::PlanePath::ZOrderCurve->new;
  my $graph = Graph::Maker->new ('twin_alternate_area_tree',
                                 level => $level,
                                 # vertex_name_type => 'xy',
                                );
  foreach my $n ($graph->vertices) {
    my ($x,$y) = $path->n_to_xy($n);
    $x = $y-$x;
    $draw_text->($x,$y, $n);
    push @vertex_xy_by_z, "$x,$y";
  }
  foreach my $edge ($graph->edges) {
    my ($v1,$v2) = @$edge;
    my ($x1,$y1) = $path->n_to_xy($v1);
    my ($x2,$y2) = $path->n_to_xy($v2);
    $x1 = $y1-$x1;
    $x2 = $y2-$x2;
    $draw_line->($x1,$y1, $x2,$y2);
  }

  $image->save('/dev/stdout');


  $graph = Graph::Maker->new ('twin_alternate_area_tree',
                              level => $level,
                              vertex_name_type => 'xy',
                             );
  my @vertex_xy_by_graph = $graph->vertices;
  (join(' ',sort @vertex_xy_by_z)
   eq
   join(' ',sort @vertex_xy_by_graph)) or die;
  exit 0;
}

{
  # view
  my $graph = Graph::Maker->new ('twin_alternate_area_tree',
                                 level=>6,
                                 # vertex_name_type => 'xy',
                                 undirected => 1);
  MyGraphs::Graph_view($graph);
  exit 0;
}




{
  # POD sample code

  use Math::PlanePath::ZOrderCurve;
  my $path = Math::PlanePath::ZOrderCurve->new;
  my $graph = Graph::Maker->new ('twin_alternate_area_tree', level=>5);
  foreach my $edge ($graph->edges) {
    my ($v1,$v2) = @$edge;
    my ($x1,$y1) = $path->n_to_xy($v1); $x1-=$y1;
    my ($x2,$y2) = $path->n_to_xy($v2); $x2-=$y2;
    print "draw an edge from ($x1,$y1) to ($x2,$y2) ...\n";

    abs($x1-$x2) <= 1 or die;
    abs($y1-$y2) <= 1 or die;
  }
  exit 0;
}

{
  # compared to TwinAlternateAreaTreeByPath

  require Graph::Maker::TwinAlternateAreaTreeByPath;
  foreach my $k (0 .. 10) {
    my $graph = Graph::Maker->new('twin_alternate_area_tree', level=>$k,
                                  undirected=>1);
    my $gpath = Graph::Maker->new('twin_alternate_area_tree_by_path', level=>$k,
                                  undirected=>1);

    # print "$gpath\n";
    # foreach my $edge (sort {max(@$a) <=> max(@$b)
    #                           || min(@$a) <=> min(@$b)
    #                         } $gpath->edges) {
    #   my ($v1, $v2) = @$edge;
    #   if ($v1 > $v2) { ($v1,$v2) = ($v2,$v1); }
    #   printf "  %*b %*b\n", $k, $v1, $k, $v2;
    # }
    # foreach my $edge (sort {max(@$a) <=> max(@$b)
    #                           || min(@$a) <=> min(@$b)
    #                         } $graph->edges) {
    #   my ($v1, $v2) = @$edge;
    #   if ($v1 > $v2) { ($v1,$v2) = ($v2,$v1); }
    #   printf "  %*b %*b\n", $k, $v1, $k, $v2;
    # }

    my $bool = Graph_is_isomorphic($graph, $gpath);
    print "k=$k  ",$bool ? "yes" : "no", "\n";
  }
  exit 0;
}
