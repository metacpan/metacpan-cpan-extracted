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
use Graph::Maker::Dragon;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # House of Graphs
  #  k=3 https://hog.grinvin.org/ViewGraphInfo.action?id=700
  #  k=4 not
  #  k=5 not
  # blobs
  #  k=4 unit square
  #  k=5 https://hog.grinvin.org/ViewGraphInfo.action?id=25223

  my @graphs;
  foreach my $k (5,
                # 0 .. 6
                ) {
    my $graph = Graph::Maker->new('dragon', level=>$k,
                                  part => 'blob',
                                  undirected=>1);
    push @graphs, $graph;
  }
  hog_searches_html(@graphs);
  exit 0;
}

{
  # pictures
  my $graph = Graph::Maker->new('dragon',
                                level => 5,
                                arms => 1,
                                # part => 'blob',
                                undirected=>1);
  Graph_xy_print($graph);
  exit 0;
}

{
  # compared to DragonByPath

  my $print = 0;
  require Graph::Maker::DragonByPath;
  my @params = (arms => 1,
                part=>'blob',
               );
  foreach my $k (0 .. 12) {
    my $graph = Graph::Maker->new('dragon', level=>$k, @params,
                                  undirected=>1);
    my $gpath = Graph::Maker->new('dragon_by_planepath', level=>$k, @params,
                                  undirected=>1);
    if ($print) {
      print "graph: $graph\n";
      foreach my $edge (sort {join(' ',@$a) cmp join(' ',@$a) } $graph->edges) {
        my ($v1, $v2) = sort @$edge;
        printf "  %*s %*s\n", $k, $v1, $k, $v2;
      }
      print "path:  $gpath\n";
      foreach my $edge (sort {join(' ',@$a) cmp join(' ',@$a) } $gpath->edges) {
        my ($v1, $v2) = sort @$edge;
        printf "  %*s %*s\n", $k, $v1, $k, $v2;
      }
    }

    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    my $bool = Graph_is_isomorphic($graph, $gpath);
    print "k=$k  ",$bool ? "yes" : "no", "  got $num_vertices vertices $num_edges edges\n";
  }
  exit 0;
}

{
  # degrees
  foreach my $k (5) {
    my $graph = Graph::Maker->new('dragon', level=>$k,
                                  undirected=>1);

    require Graph::Writer::Sparse6;
    my $writer = Graph::Writer::Sparse6->new (header => 1);
    my $sparse6_str;
    open my $fh, '>', \$sparse6_str;
    $writer->write_graph($graph, $fh);
    print $sparse6_str;
    my $canon_str = graph6_str_to_canonical($sparse6_str);
    print $canon_str;

    foreach my $v (0 .. 2**$k-1) {
      my @neighbours = $graph->neighbours($v);
      @neighbours = grep {$_ < $v} @neighbours;
      print scalar(@neighbours)," ";
      # last if $v > 120;
    }
    print "\n";
  }
  exit 0;
}


{
  # sample picture for POD

  my $level = 6;
  my $scale_y = 2;
  my $scale_x = 4;

  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => 80, -height => 40);
  my $offset_x = 50;
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

  require Math::PlanePath::ComplexPlus;
  my $path = Math::PlanePath::ComplexPlus->new;
  my $graph = Graph::Maker->new ('dragon', level => $level);
  foreach my $n ($graph->vertices) {
    my ($x,$y) = $path->n_to_xy($n);
    $draw_text->($x,$y, $n);
  }
  foreach my $edge ($graph->edges) {
    my ($v1,$v2) = @$edge;
    my ($x1,$y1) = $path->n_to_xy($v1);
    my ($x2,$y2) = $path->n_to_xy($v2);
    $draw_line->($x1,$y1, $x2,$y2);
  }

  $image->save('/dev/stdout');
  exit 0;
}

{
  # POD sample code

  use Math::PlanePath::ComplexPlus;
  my $path = Math::PlanePath::ComplexPlus->new;
  my $graph = Graph::Maker->new ('dragon', level=>5);
  foreach my $edge ($graph->edges) {
    my ($v1,$v2) = @$edge;
    my ($x1,$y1) = $path->n_to_xy($v1);
    my ($x2,$y2) = $path->n_to_xy($v2);
    print "draw an edge from ($x1,$y1) to ($x2,$y2) ...\n";

    abs($x1-$x2) <= 1 or die;
    abs($y1-$y2) <= 1 or die;
  }
  exit 0;
}



