#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde
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
use MyGraphs;
use Graph::Maker::KnightGrid;

# uncomment this to run the ### lines
# use Smart::Comments;



{
  # Torus
  # 3x3 Paley https://hog.grinvin.org/ViewGraphInfo.action?id=6607
  # 4x4 tesseract https://hog.grinvin.org/ViewGraphInfo.action?id=1340
  # 5x5,6x6 not
  # k=1 edges 1
  # @
  # k=2 edges 4
  # Cr
  # k=3 edges 18
  # H{dQXgj
  # k=4 edges 32
  # Os_????@zKIgIgLGHW?r?
  # k=5 edges 50
  #     Xs_??KE@?A__?H?O?O?@@?_O_OQ?I?OCSOGcWD??o@OD?Q?SAO?
  # 5x5 Xs_??KE@?A__?H?O?O?@@?_O_OQ?I?OCSOGcWD??o@OD?Q?SAO?

  my @graphs;
  my @values;
  foreach my $size (1 .. 8) {

    require Graph::Maker::Grid;
    my $graph = Graph::Maker->new('grid',
                                  dims => [$size,$size],
                                  undirected => 1,
                                  cyclic => 1,
                                 );
    push @graphs, $graph;

    my $num_edges = $graph->edges;

    print "k=$size edges $num_edges\n";
    push @values, $num_edges;

    require Graph::Writer::Graph6;
    my $writer = Graph::Writer::Graph6->new;
    my $g6_str;
    open my $fh, '>', \$g6_str or die;
    $writer->write_graph($graph, $fh);
    print graph6_str_to_canonical($g6_str);

    # my $easy = Graph::Easy->new (undirected => 1);
    # my $connect = sub {
    #   my ($x1,$y1, $x2,$y2) = @_;
    #   $x1 %= $size;
    #   $y1 %= $size;
    #   $x2 %= $size;
    #   $y2 %= $size;
    #   if ($x1 >= 0 && $x1 < $size
    #       && $y1 >= 0 && $y1 < $size
    #       && $x2 >= 0 && $x2 < $size
    #       && $y2 >= 0 && $y2 < $size) {
    #     my $from = "$x1,$y1";
    #     my $to   = "$x2,$y2";
    #     unless ($easy->has_edge($from,$to) || $easy->has_edge($to,$from)) {
    #       $easy->add_edge($from,$to);
    #     }
    #   }
    # };
    # foreach my $x (0 .. $size-1) {
    #   foreach my $y (0 .. $size-1) {
    #     $connect->($x,$y, $x+1, $y);
    #     $connect->($x,$y, $x-1, $y);
    #     $connect->($x,$y, $x, $y+1);
    #     $connect->($x,$y, $x, $y-1);
    #   }
    # }
    # $easy->set_attribute('x-dot-splines',"true");
    # # Graph_Easy_view($easy);
    # push @graphs, $easy;
    #
    # print "k=$size\n";
    # my $g6_str = $easy->as_graph6;
    # print graph6_str_to_canonical($g6_str);
  }
  hog_searches_html(@graphs);
  exit 0;
}

{
  # cyclic
  my $w = 1;
  my $h = 2;
  my $plain = Graph::Maker->new('knight_grid',
                                dims => [$w,$h],
                                undirected => 1,
                                cyclic => 0,
                               );
  my $cyclic = Graph::Maker->new('knight_grid',
                                 dims => [1,2],
                                 undirected => 1,
                                 cyclic => 1,
                                );
  my $plain_num_vertices = $plain->vertices;
  my $cyclic_num_vertices = $cyclic->vertices;
  my $plain_num_edges = $plain->edges;
  my $cyclic_num_edges = $cyclic->edges;
  print "$plain\n";
  print "$cyclic\n";
  exit 0;
}

{
  # KnightGrid sizes where plain different from cyclic torus
  foreach my $w (1 .. 5) {
    print "$w  ";
    foreach my $h (1 .. 5) {
      my $plain = Graph::Maker->new('knight_grid',
                                    dims => [$w,$h],
                                    undirected => 1,
                                    cyclic => 0,
                                   );
      my $cyclic = Graph::Maker->new('knight_grid',
                                     dims => [$w,$h],
                                     undirected => 1,
                                     cyclic => 1,
                                    );
      my $plain_num_vertices = $plain->vertices;
      my $cyclic_num_vertices = $cyclic->vertices;
      my $plain_num_edges = $plain->edges;
      my $cyclic_num_edges = $cyclic->edges;
      my $str = (Graph_is_isomorphic($plain,$cyclic)
                 ? "same" : "----");
      my $empty = scalar($plain->edges) ? "" : "E";
      $str .= " $plain_num_vertices,$cyclic_num_vertices $plain_num_edges,$cyclic_num_edges";
      printf "%15s", $str;
    }
    print "\n";
  }
  exit 0;
}

{
  # number of edges in NxNxN etc
  #
  # 2-D  0,0,0,16,48,96,160,240,336,448,576
  #      A035008 8*n*(n+1)
  #      vector(11,n,n--; 8*(n-2)*(n-1))
  #
  # 3-D  0,0,0,144,576,1440,2880,5040,8064,12096,17280,23760,31680
  #      A180413 8*24*(n-1)*n*(n+1)
  #      vector(13,n,n--; 8*2*3/2 * (n-2)*(n-1)*(2*n))
  #
  # 4-D  0,0,0,864,4608,14400,34560,70560,129024,217728
  #      not 4*A085277, not in OEIS apparently
  #      vector(10,n,n--; 8*3*4/2 * (n-2)*(n-1)*n^2)
  #
  # 5-D  0,0,0,4320,30720,120000,345600,823200
  #      vector(8,n,n--; 8*4*5/2 * (n-2)*(n-1)*n^3)
  #
  # 6-D  0,0,0,19440,184320
  #      vector(6,n,n--; 8*5*6/2 * (n-2)*(n-1)*n^4)
  #
  # factor 8,24,48,80,120 = A033996 8*triangular


  # coordinates c1,c2,...
  # when c==0 cannot -1 or -2 there

  require Graph::Maker::KnightGrid;
  my @values;
  my $D = 6;
  foreach my $d (0 .. 10) {
    my $graph = Graph::Maker->new('knight_grid',
                                  dims => [($d) x $D],
                                 );
    my $num_edges = $graph->edges;
    print $num_edges,"\n";
  }
  # print join(',',@values),"\n";
  exit 0;
}

{
  # Graph::Maker::Grid 1x1 cyclic

  require Graph::Maker::KnightGrid;
  require Graph::Maker::Grid;
  my $graph = Graph::Maker->new('knight_grid', dims => [1], cyclic=>1,
                                undirected => 0,
                               );
  print $graph,"\n";
  print $graph->has_edge(1,1)?"edge" : "no edge","\n";
  # Graph_view($graph);
  exit 0;
}

{
  # Graph::Maker::Grid long/short sides numbering

  {
    require Graph::Maker::Grid;
    my $graph = Graph::Maker->new('grid',
                                  dims => [3,4],
                                  undirected => 0,
                                  cyclic => 0,
                                 );
    Graph_view($graph);
  }
  {
    require Graph::Maker::KnightGrid;
    my $graph = Graph::Maker->new('knight_grid',
                                  dims => [3,4],
                                  undirected => 0,
                                  cyclic => 0,
                                 );
    Graph_view($graph);
  }

  my $dims = [3,4];
  foreach my $i (0 .. $dims->[0]-1) {
    foreach my $j (0 .. $dims->[1]-1) {
      print "  ",Graph::Maker::KnightGrid::_coordinates_to_vertex([$i,$j],$dims);
    }
    print "\n";
  }
  exit 0;
}

{
  # Graph::Maker::KnightGrid max degree
  my @values;
  foreach my $num_dims (1 .. 6) {
    require Graph::Maker::KnightGrid;
    my $graph = Graph::Maker->new('knight_grid',
                                  dims => [(5)x$num_dims],
                                  undirected => 1,
                                  cyclic => 0,
                                 );
    my $max_degree = max(map {$graph->degree($_)} $graph->vertices);
    my $value = $max_degree / 8;
    print "dims=$num_dims  $max_degree  $value\n";
    push @values, $value;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}


{
  # 3x3 grid with wraparound
  #
  # 0 -- 1 -- 2
  # |    |    |
  # 3----4----5
  # |    |    |
  # 6 -- 7 -- 8
  #
  my $edge_aref = [ [0,1],[1,2],[2,0],
                    [3,4],[4,5],[5,3],
                    [6,7],[7,8],[8,6],

                    [0,3],[3,6],[6,0],
                    [1,4],[4,7],[7,1],
                    [2,5],[5,8],[8,2],
                  ];
  my $flat_g6_str;
  Graph::Graph6::write_graph(str_ref => \$flat_g6_str,
                             edge_aref => $edge_aref);
  my $flat_g6_canonical = graph6_str_to_canonical($flat_g6_str);
  print $flat_g6_canonical;

  {
    my $edge_aref = [ [0,4],[4,8],[8,0],
                      [1,5],[5,6],[6,1],
                      [2,3],[3,7],[7,2],

                      [0,5],[5,7],[7,0],
                      [1,3],[3,8],[8,1],
                      [2,4],[4,6],[6,2],
                    ];
    my $cross_g6_str;
    Graph::Graph6::write_graph(str_ref => \$cross_g6_str,
                               edge_aref => $edge_aref);
    my $cross_g6_canonical = graph6_str_to_canonical($cross_g6_str);
    print $cross_g6_canonical;
    $flat_g6_canonical eq $cross_g6_canonical or die;
  }
  {
    # knight
    my $edge_aref = [ [0,7],[7,5],[5,0],
                      [1,8],[8,3],[3,1],
                      [2,6],[6,4],[4,2],

                      [0,8],[8,4],[4,0],
                      [1,6],[6,5],[5,1],
                      [2,7],[7,3],[3,2],
                    ];
    my $cross_g6_str;
    Graph::Graph6::write_graph(str_ref => \$cross_g6_str,
                               edge_aref => $edge_aref);
    my $cross_g6_canonical = graph6_str_to_canonical($cross_g6_str);
    print $cross_g6_canonical;
    $flat_g6_canonical eq $cross_g6_canonical or die;
  }
  {
    # Paley 9
    my $edge_aref = [ [0,1],[1,2],[2,3],
                      [3,4],[4,5],[5,6],
                      [6,7],[7,8],[8,0],

                      [0,2],[0,4],
                      [1,5],[1,6],
                      [2,7],
                      [3,7],[3,5],
                      [4,8],
                      [6,8],
                    ];
    my $cross_g6_str;
    Graph::Graph6::write_graph(str_ref => \$cross_g6_str,
                               edge_aref => $edge_aref);
    my $cross_g6_canonical = graph6_str_to_canonical($cross_g6_str);
    print $cross_g6_canonical;
    $flat_g6_canonical eq $cross_g6_canonical or die;
  }


  {
    require Graph::Maker::Grid;
    my $graph = Graph::Maker->new('grid',
                                  dims => [3,3],
                                  undirected => 1,
                                  cyclic => 1,
                                 );
    my $writer = Graph::Writer::Graph6->new;
    my $g6_str;
    open my $fh, '>', \$g6_str or die;
    $writer->write_graph($graph, $fh);
    my $g6_canonical = graph6_str_to_canonical($g6_str);
    print $g6_canonical;
    $flat_g6_canonical eq $g6_canonical or die;
  }
  {
    require Graph::Maker::KnightGrid;
    my $graph = Graph::Maker->new('knight_grid',
                                  dims => [3,3],
                                  undirected => 1,
                                  cyclic => 1,
                                 );
    my $writer = Graph::Writer::Graph6->new;
    my $g6_str;
    open my $fh, '>', \$g6_str or die;
    $writer->write_graph($graph, $fh);
    my $g6_canonical = graph6_str_to_canonical($g6_str);
    print $g6_canonical;
    $flat_g6_canonical eq $g6_canonical or die;

    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    print "num vertices $num_vertices  num edges $num_edges\n";
  }
  exit 0;
}

{
  # 3x4 knight grid flattened
  #
  # 0 -- 3 -- 6 -- 9       12 nodes, 14 edges
  # |    |    |    |
  # 1    4    7    10
  # |    |    |    |
  # 2 -- 5 -- 8 -- 11
  #
  my $edge_aref = [ [0,1],[1,2],
                    [3,4],[4,5],
                    [6,7],[7,8],
                    [9,10],[10,11],
                    [0,3],[3,6],[6,9],
                    [2,5],[5,8],[8,11],
                  ];
  my $flat_g6_str;
  Graph::Graph6::write_graph(str_ref => \$flat_g6_str,
                             edge_aref => $edge_aref);
  my $flat_g6_canonical = graph6_str_to_canonical($flat_g6_str);
  print $flat_g6_canonical;

  {
    my $edge_aref = [ [0,5],[3,8],[6,11], # vert
                      [3,2],[6,5],[9,8],
                      [0,7],[3,10],[6,1],[9,4],  # horiz
                      [1,8],[4,11],[7,2],[10,5],
                    ];
    my $cross_g6_str;
    Graph::Graph6::write_graph(str_ref => \$cross_g6_str,
                               edge_aref => $edge_aref);
    my $cross_g6_canonical = graph6_str_to_canonical($cross_g6_str);
    print $cross_g6_canonical;
    $flat_g6_canonical eq $cross_g6_canonical or die;
  }

  {
    require Graph::Maker::KnightGrid;
    my $graph = Graph::Maker->new('knight_grid',
                                  dims => [3,4],
                                  undirected => 1,
                                 );
    my $writer = Graph::Writer::Graph6->new;
    my $g6_str;
    open my $fh, '>', \$g6_str or die;
    $writer->write_graph($graph, $fh);
    my $g6_canonical = graph6_str_to_canonical($g6_str);
    print $g6_canonical;
    $flat_g6_canonical eq $g6_canonical or die;

    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    print "num vertices $num_vertices  num edges $num_edges\n";

    hog_searches_html($graph);
  }
  exit 0;
}

{
  # Euler 3x4 knight tour

  my $a = [ [12, 9,  6, 3],
            [ 1, 4, 11, 8],
            [10, 7,  2, 5] ];
  my $reverse = sub {
    my ($a) = @_;
    my $ret = [];
    foreach my $i (0 .. $#$a) {
      foreach my $j (0 .. 3) {
        $ret->[$i]->[$j] = 13 - $a->[$i]->[$j];
      }
    }
    return $ret;
  };
  my $mirror_vertical = sub {
    my ($a) = @_;
    return [ reverse @$a ];
  };
  my $print = sub {
    my ($a) = @_;
    foreach my $i (0 .. $#$a) {
      foreach my $j (0 .. 3) {
        printf "%3d", $a->[$i]->[$j];
      }
      print "\n";
    }
  };
  $print->($a);
  print "transformed\n";
  $a = $reverse->($a);
  $a = $mirror_vertical->($a);
  $print->($a);
  exit 0;
}

{
  # KnightGrid
  my $size = 4;
  require Graph::Maker::KnightGrid;
  my $graph = Graph::Maker->new('knight_grid',
                                dims => [$size,$size],
                                undirected => 1,
                               );
  # Graph_view($graph);

  require Graph::Convert;
  my $easy = Graph::Convert->as_graph_easy($graph);
  $easy->set_attribute('x-dot-overlap',"false");
  $easy->set_attribute('x-dot-splines',"true");

  require Math::PlanePath::Base::Digits;
  foreach my $node ($easy->nodes) {
    my $name = $node->label;
    my ($x,$y) = Math::PlanePath::Base::Digits::digit_split_lowtohigh($name-1,$size);
    $x += 0;
    $y += 0;
    $node->set_attribute('x-dot-pos', "$x,$y!");
    $node->set_attribute(label => "$x,$y");
  }
  Graph_Easy_view($easy);
  exit 0;
}

{
  # Knight connections
  my $size = 4;
  my $easy = Graph::Easy->new (undirected => 1);
  my $connect = sub {
    my ($x1,$y1, $x2,$y2) = @_;
    if ($x1 >= 1 && $x1 <= $size
        && $y1 >= 1 && $y1 <= $size
        && $x2 >= 1 && $x2 <= $size
        && $y2 >= 1 && $y2 <= $size) {
      my $from = "$x1,$y1";
      my $to   = "$x2,$y2";
      unless ($easy->has_edge($from,$to) || $easy->has_edge($to,$from)) {
        $easy->add_edge($from,$to);
      }
    }
  };
  foreach my $x (1 .. $size) {
    foreach my $y (1 .. $size) {
      foreach my $xsign (1,-1) {
        foreach my $ysign (1,-1) {
          $connect->($x,$y, $x+1*$xsign, $y+2*$ysign);
          $connect->($x,$y, $x+2*$xsign, $y+1*$ysign);
        }
      }
    }
  }
  Graph_Easy_view($easy);
  exit 0;
}

{
  # KnightGrid grep
  # num edges 8*triangular = A033996
  # 3x3 is plain grid torus, Paley on 9 vertices
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=6607
  # 4x4 is tesseract https://hog.grinvin.org/ViewGraphInfo.action?id=1340
  # 5x5 canonical X~}CKMFPACgJONHCAaGW...
  #               X~}CKMFPACgJONHCAaGWbGaO`DH@EWcPOIGXCPHO`DE`GaeAGcj

  # 2x2 torus  *--*
  #            |  |
  #            *--*
  # torus:
  # k=1 edges 1
  # @
  # k=2 edges 4
  # Cr
  # k=3 edges 18
  # H{dQXgj
  # k=4 edges 32
  # Os_????@zKIgIgLGHW?r?
  # k=5 edges 100
  # X~}CKMFPACgJONHCAaGWbGaO`DH@EWcPOIGXCPHO`DE`GaeAGcj

  my @graphs;
  my @values;
  foreach my $size (0 .. 8) {
    require Graph::Maker::KnightGrid;
    my $graph = Graph::Maker->new('knight_grid',
                                  dims => [$size,$size],
                                  undirected => 1,
                                  cyclic => 1,
                                 );
    push @graphs, $graph;

    my $num_edges = $graph->edges;

    print "k=$size edges $num_edges\n";
    push @values, $num_edges;

    my $writer = Graph::Writer::Graph6->new;
    my $g6_str;
    open my $fh, '>', \$g6_str or die;
    $writer->write_graph($graph, $fh);
    print graph6_str_to_canonical($g6_str);
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  hog_searches_html(@graphs);
  exit 0;
}
