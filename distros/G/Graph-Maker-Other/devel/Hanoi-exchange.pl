#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2020, 2021 Kevin Ryde
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
use Math::BaseCnv 'cnv';
use Graph::Maker::HanoiExchange;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  my $discs = 5;
  my $graph = Graph::Maker->new('hanoi_exchange',
                                discs => $discs,
                                # vertex_names => 'digits',
                                undirected => 1);
  HanoiExchange3_layout($graph,$discs);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);
  exit 0;
}

{
  # R. S. Scorer, P. M. Grundy and C. A. B. Smith, "Some Binary Games",
  # The Mathematical Gazette, July 1944, volume 28, number 280, pages 96-103.
  # http://www.jstor.org/stable/3606393
  #
  # Section 4(iii), Plane Network Game
  #
  # discs=2 same as Hanoi but different relative edges.
  #
  # disc  2 1 0     
  #       0 0 2  -> 0 2 0  spindle
  #       12::0     02::1
  #
  # disc  2 1 0     
  #       2 0 0  -> 0 0 2
  #       01::2     12::0 
  #  small 2,-,0

  my $discs = 5;
  my $graph = Graph::Maker->new('hanoi_exchange',
                                discs => $discs,
                                # vertex_names => 'digits',
                                undirected => 1);
  {
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter;
    print "  $num_vertices vertices $num_edges edges  diameter $diameter\n";

  }
  $graph->delete_edges(map {@$_} $graph->edges);
  $graph->edges == 0 or die;
  foreach my $from (sort {$a<=>$b} $graph->vertices) {
    my $from3 = sprintf '%0*s', $discs, cnv($from,10,3);
    ### $from3
    foreach my $d (0 .. 2) {   # smallest disc any move
      my $to3 = substr($from3,0,-1) . $d;
      my $to = cnv($to3,3,10);
      next if $to == $from;
      next unless $graph->has_vertex($to);
      ### edge smallest: "$from $to  $from3 $to3"
      $graph->add_edge($from,$to);
    }
    my @small;
    foreach my $i (0 .. length($from3)-1) {
      $small[substr($from3,$i,1)] = $i;
    }
    ### @small
    foreach my $x (0 .. 2) {
      next unless defined $small[$x];
      foreach my $y ($x+1 .. 2) {
        next if $x==$y;
        next unless defined $small[$y];
        next unless abs($small[$x] - $small[$y]) == 1;
        my $to3 = $from3;
        substr($to3,$small[$x],1, $y);
        substr($to3,$small[$y],1, $x);
        my $to = cnv($to3,3,10);
        next unless $graph->has_vertex($to);
        ### edge exchange: "x=$x y=$y $from $to   $from3 $to3"
        $graph->add_edge($from,$to);
      }
    }
  }

  # MyGraphs::Graph_set_xy_points
  #     ($graph,
  #      0 => [0,0],
  #      1 => [-1, -1],
  #      2 => [1, -1],
  #      3 => [-2,-2],   6 => [2, -2],
  #      4 => [-3, -3],  7 => [1, -3],
  #      5 => [-1, -3],  8 => [3, -3],
  # 
  #      9 => [-4, -4],
  #      10 => [-5, -5],
  #      11 => [-3, -5],
  #      12 => [-6,-6],   15 => [-2, -6],
  #      13 => [-7, -7],  16 => [-3, -7],
  #      14 => [-5, -7],  17 => [-1, -7],
  # 
  #      18 => [4, -4],
  #      19 => [3, -5],
  #      20 => [5, -5],
  #      21 => [2, -6],  24 => [6, -6],
  #      22 => [1, -7],  25 => [5, -7],
  #      23 => [3, -7],  26 => [7, -7],
  #     );
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  my $diameter = $graph->diameter;
  print "  $num_vertices vertices $num_edges edges  diameter $diameter\n";

  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # discs=2 same as Hanoi but different relative edges.
  #
  # disc  2 1 0
  #       0 0 2  -> 0 2 0  spindle
  #       12::0     02::1
  #
  # disc  2 1 0
  #       2 0 0  -> 0 0 2
  #       01::2     12::0
  #  small 2,-,0

  my $discs = 4;
  my $graph = Graph::Maker->new('hanoi_exchange',
                                discs => $discs,
                                spindles => 3,
                                vertex_names => 'digits',
                                undirected => 1);
  my @vertices = $graph->vertices;
  my $num_vertices = scalar(@vertices);
  my $num_edges = $graph->edges;
  print "  $num_vertices vertices $num_edges edges\n";

  # if ($discs == 3) {
  #   MyGraphs::Graph_set_xy_points
  #       ($graph,
  #        0 => [0,0],
  #        1 => [-1, -1],
  #        2 => [1, -1],
  #        3 => [-2,-2],   6 => [2, -2],
  #        4 => [-3, -3],  7 => [1, -3],
  #        5 => [-1, -3],  8 => [3, -3],
  #
  #        9 => [-4, -4],
  #        10 => [-5, -5],
  #        11 => [-3, -5],
  #        12 => [-6,-6],   15 => [-2, -6],
  #        13 => [-7, -7],  16 => [-3, -7],
  #        14 => [-5, -7],  17 => [-1, -7],
  #
  #        18 => [4, -4],
  #        19 => [3, -5],
  #        20 => [5, -5],
  #        21 => [2, -6],  24 => [6, -6],
  #        22 => [1, -7],  25 => [5, -7],
  #        23 => [3, -7],  26 => [7, -7],
  #       );
  # }
  HanoiExchange3_layout($graph,$discs);
  if ($discs <= 4) {
    my $len = $graph->path_length(min(@vertices), max(@vertices)) // 'none';
    print "  solution length $len\n";
    my $diameter = $graph->diameter || -1;
    print "  $num_vertices vertices $num_edges edges  diameter $diameter\n";
  }

  MyGraphs::Graph_view($graph, scale => 24 / 2**$discs);
  # MyGraphs::Graph_print_tikz($graph);
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);
  exit 0;

  # for 3 spindles
  sub HanoiExchange3_layout {
    my ($graph,$N) = @_;
    $graph->set_graph_attribute('is_xy_triangular', 1);
    my $from_base = (min($graph->vertices) =~ /^00/ ? 3 : 10);
    foreach my $v (sort {$a<=>$b} $graph->vertices) {
      my $str = cnv($v,$from_base,3);
      $str = sprintf '%0*s', $N, $str;
      my $x = 0;
      my $y = 0;
      my @digits = reverse split //, $str;   # low to high
      foreach my $i (reverse 0 .. $#digits) {  # high to low
        my $d = $digits[$i];
        ### $d
        if ($d == 1) { $x -= 1<<$i; }
        if ($d == 2) { $x += 1<<$i; }
        if ($d) { $y -= 1<<$i; }
      }
      MyGraphs::Graph_set_xy_points($graph, $v => [$x,$y]);
    }
  }
}



{
  # R. S. Scorer, P. M. Grundy and C. A. B. Smith, "Some Binary Games",
  # The Mathematical Gazette, July 1944, volume 28, number 280, pages 96-103.
  # http://www.jstor.org/stable/3606393
  #
  # Section 4(i), Travelling Diplomats = complete 5, then ways to move

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_cycle('B','R','L');
  $graph->add_cycle('L','P','G');
  $graph->add_cycle('B','P','G');
  $graph->add_cycle('R','P','G');
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
