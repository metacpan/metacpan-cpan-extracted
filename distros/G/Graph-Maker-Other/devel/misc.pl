#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde
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
use List::Util 'min';
use Math::BaseCnv 'cnv';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # Mobius Ladder Spanning Trees

  # read("../../geom/geom.gp")
  # sqrt3 = geom_sqrt_as_quad(3)
  # sqrt3^2 == 3
  # t(n) = n/2 * ( (2+sqrt3)^n + (2-sqrt3)^n + 2);
  # vector(15,n, t(n))
  # A020871
  exit 0;
}

{
  # Free Trees Corresponding to Hypertrees
  # leaves in same bipartite half
  my @graphs = (
                # star 7
                # https://hog.grinvin.org/ViewGraphInfo.action?id=622
                [0, 1, 1, 1, 1, 1, 1],

                # path 7
                # https://hog.grinvin.org/ViewGraphInfo.action?id=478
                [0, 1, 2, 3, 1, 5, 6],

                # centre and centroid disjoint
                # https://hog.grinvin.org/ViewGraphInfo.action?id=792
                [0, 1, 2, 2, 2, 1, 6],

                # integral tree
                # https://hog.grinvin.org/ViewGraphInfo.action?id=816
                [0, 1, 2, 1, 4, 1, 6],

                # most maximum matchings Heuberger and Wagner
                # https://hog.grinvin.org/ViewGraphInfo.action?id=498
                [0, 1, 2, 2, 1, 5, 5],
               );
  @graphs = map { MyGraphs::Graph_from_vpar([undef,@$_]) } @graphs;
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Knuth 4A 7.2.1.6 example (2)
  # https://hog.grinvin.org/ViewGraphInfo.action?id=34219

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (flow => 'south');
  $graph->add_path ('12','21');
  $graph->add_path ('3f','44','53');
  $graph->add_path ('3f','6a','78','85');
  $graph->add_path ('78','97','a6');
  $graph->add_path ('6a','b9');
  $graph->add_path ('3f','ce','db');
  $graph->add_path ('ce','ed','fc');

  MyGraphs::Graph_set_xy_points($graph,
                                '3f' => [0,0],
                                '44' => [-2,-1], '53' => [-2,-2],

                                '6a' => [0,-1],
                                '78' => [-.25, -2],
                                'b9' => [.75, -2],
                                '85' => [-.5, -3],
                                '97' => [.5, -3],
                                'a6' => [.5, -4],

                                'ce' => [2,-1],
                                'db' => [1.75, -2],
                                'ed' => [2.75, -2],
                                'fc' => [2.75, -3],

                                '12' => [-3.5,0],
                                '21' => [-3.5,-1],
                               );

  {
    # vpar_from_balanced_binary(fromdigits([1,1,0,0, 1,1,1,0,0,1,1,1,0,1,1,0,0,0,1,0,0,1,1,0,1,1,0,0,0,0],2))
    my $vpar = [undef, 0, 1, 0, 3, 4, 3, 6, 7, 7, 9, 6, 3, 12, 12, 14];
    my $vpar_graph = MyGraphs::Graph_from_vpar ($vpar);
    # MyGraphs::Graph_view($vpar_graph);
    MyGraphs::Graph_is_isomorphic($graph,$vpar_graph) or die "different";
    die if $graph eq $vpar_graph;
  }

  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);
  exit 0;
}
{
  require Graph;
  my $graph = Graph->new (undirected => 1, countedged=>1);
  $graph->add_cycle(1,2);
  my $num_edges = $graph->edges;
  print "num edges $num_edges\n";
  my @edges = $graph->edges;
  ### @edges
  exit 0;
}


{
  # Lawder Hilbert 3D
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1024
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(0,5,4);
  $graph->add_cycle(9,8,10, 2,1,7);
  $graph->add_path(0,1,6,3,8,5);
  $graph->add_path(0,2,11,3,9,4);
  $graph->add_path(5,10,11,6,7,4);

  MyGraphs::Graph_set_xy_points($graph,
                                3 => [0,-1],
                                6 => [-1,1],
                                11 => [ 1,1],

                                1 => [-1,2], 2 => [ 1,2],
                                10 => [2,0], 8 => [2,-1.5],
                                7 => [-2,0], 9 => [-2,-1.5],

                                0 => [0,5],
                                5 => [ 5,-4],
                                4 => [-5,-4],
                               );

  MyGraphs::hog_searches_html($graph);
  MyGraphs::Graph_view($graph);
  exit 0;
}

{
  # isomorphic halves connected at different
  # https://hog.grinvin.org/ViewGraphInfo.action?id=33776
  #
  # *---*---*---*---B --- A---*---*---*---*
  #         |   |   |         |   |
  #         *   A   *         B   *
  #                           |
  #                           *
  my $vpar = [undef, 0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 10, 11, 12, 11, 10, 15];
  my $graph = MyGraphs::Graph_from_vpar ($vpar, undirected => 1);
  MyGraphs::Graph_set_xy_points($graph,
                                6 => [0,-1],
                                5 => [1,-1],
                                4 => [2,-1], 7 => [2,-2],
                                3 => [3,-1], 8 => [3,-2],
                                2 => [4,-1], 9 => [5,-1],
                                16 => [5,1],
                                15 => [4,1],
                                10 => [3,1], 1 => [3,0],
                                11 => [2,1], 14 => [2,0],
                                12 => [1,1],
                                13 => [0,1],
                               );

  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);
  MyGraphs::Graph_view($graph);
  exit 0;
}


{
  require Graph;
  my @graphs;
  foreach my $N (2 .. 7) {
    print "N=$N\n";
    my $count_even = 0;
    my $count_odd = 0;
    my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
      (num_vertices_min => $N,
       num_vertices_max => $N,
       connected => 1,
      );
  G: while (my $edge_aref = $iterator_func->()) {
      my $graph = MyGraphs::Graph_from_edge_aref($edge_aref);
      foreach my $v ($graph->vertices) {
        if ($graph->degree($v) % 2) {
          $count_odd++;
          next G;
        }
      }
      $count_even++;
      if ($N <= 6) { push @graphs, $graph; }
      if (my @path = MyGraphs::Graph_Euler_cycle($graph)) {
        print "yes ",join(' ',@path),"\n";
      } else {
        print "no\n";
      }
    }
    print "even $count_even and odd $count_odd\n";
  }

  # A003049 num connected Eulerian
  # 1,1,4,8,37

  # A158007 num connected non-Eulerian
  # 1,5,17,104

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Eulerian
  require Graph;
  my @graphs;

  {
    #    1-----2
    #    |   / | \
    #    | /   |   \
    #    6     |     3
    #    | \   |   /
    #    |   \ | /
    #    5-----4
    my $graph = Graph->new (undirected => 1);
    $graph->add_cycle(1,2,3,4,5,6);
    $graph->add_cycle(2,4,6);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }
  {
    #    1-----2-----3
    #    |   /   \   |
    #    | /       \ |
    #    8           4
    #    | \       / |
    #    |   \   /   |
    #    7-----6-----5
    my $graph = Graph->new (undirected => 1);
    $graph->add_cycle(1,2,3,4,5,6,7,8);
    $graph->add_cycle(2,4,6,8);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }
  {
    #      2
    #     /  \     not Eulerian
    #    1----3
    #    | \/ |
    #    | / \|
    #    5----4
    my $graph = Graph->new (undirected => 1);
    $graph->add_cycle(1,2,3,4,5);
    $graph->add_edges([1,4],[3,5]);
    push @graphs, $graph;
    MyGraphs::Graph_view($graph);
  }
  MyGraphs::hog_searches_html(@graphs);

  foreach my $graph (@graphs) {
    my @path = MyGraphs::Graph_Euler_cycle($graph);
    if (@path) {
      print "yes ",join(' ',@path),"\n";
    } else {
      print "no\n";
    }

    # my $linegraph = MyGraphs::Graph_line_graph($graph);
    # print MyGraphs::Graph_is_Hamiltonian($linegraph,
    #                                      type=>'cycle',
    #                                      verbose=>1)
    #   ? "yes" : "no", "\n";
  }
  exit 0;
}



{
  # Gratzer, "General Lattice Theory", pages 16-17 exercise 15.

  require Graph;
  my @graphs;
  {
    # HOG not
    my $graph = Graph->new;
    $graph->set_graph_attribute (flow => 'south');

    $graph->set_vertex_attribute(1, x => 0);
    $graph->set_vertex_attribute(1, y => 0);
    $graph->set_vertex_attribute(3, x => 0);
    $graph->set_vertex_attribute(3, y => 1);
    $graph->set_vertex_attribute(7, x => 0);
    $graph->set_vertex_attribute(7, y => 2);
    $graph->set_vertex_attribute(10, x => 0);
    $graph->set_vertex_attribute(10, y => 3);
    $graph->set_vertex_attribute(12, x => 0);
    $graph->set_vertex_attribute(12, y => 4);

    $graph->set_vertex_attribute(5, x => -2);
    $graph->set_vertex_attribute(5, y => 2);
    $graph->set_vertex_attribute(8, x => 2);
    $graph->set_vertex_attribute(8, y => 2);

    $graph->set_vertex_attribute(6, x => -1);
    $graph->set_vertex_attribute(6, y => 2);

    $graph->set_vertex_attribute(9, x => -1);
    $graph->set_vertex_attribute(9, y => 3);
    $graph->set_vertex_attribute(11, x => 1);
    $graph->set_vertex_attribute(11, y => 3);

    $graph->add_path (1,2,5,9,12);
    $graph->add_path (1,3,7,10,12);
    $graph->add_path (1,4,8,11,12);
    $graph->add_path (4,7,9);
    $graph->add_path (2,7,11);
    $graph->add_path (3,6,10);
    push @graphs, $graph;

    my @deg3s = grep {$graph->in_degree($_)+$graph->out_degree($_)==3}
      $graph->vertices;
    print "deg3s  ",join(',',@deg3s),"\n";
    foreach my $u (@deg3s) {
      foreach my $v (@deg3s) {
        my $distance = $graph->path_length($u,$v) // next;
        if ($distance == 4) {
          print "distance=4  $u to $v\n";
        }
      }
    }
  }
  {
    # https://hog.grinvin.org/ViewGraphInfo.action?id=30360
    #         8
    #      /     \
    #    6         7
    #    |  \   /  |
    #    4    X    5
    #    |  /   \  |
    #    2         3
    #      \     /
    #         1
    my $graph = Graph->new;
    $graph->set_graph_attribute (flow => 'north');
    $graph->set_vertex_attribute(1, x => 0);
    $graph->set_vertex_attribute(1, y => 0);
    $graph->set_vertex_attribute(8, x => 0);
    $graph->set_vertex_attribute(8, y => 4);

    $graph->set_vertex_attribute(4, x => -1);
    $graph->set_vertex_attribute(4, y => 2);
    $graph->set_vertex_attribute(5, x => 1);
    $graph->set_vertex_attribute(5, y => 2);

    $graph->add_path (1,2,4,6,8);
    $graph->add_path (1,3,5,7,8);
    $graph->add_edge (2,7);
    $graph->add_edge (3,6);
    push @graphs, $graph;
  }
  foreach my $graph (@graphs) {
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "$num_vertices $num_edges\n";
    MyGraphs::Graph_view($graph);
    my $href = MyGraphs::Graph_lattice_minmax_hash($graph);
    print MyGraphs::Graph_lattice_minmax_reason($graph,$href),"\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}



{
  # Self-Loop Degree
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_edge('x','x');
  # $graph->add_edge('x','y');
  print "in  ",$graph->in_degree('x'),"\n";
  print "out ",$graph->out_degree('x'),"\n";
  print "net ",$graph->degree('x'),"\n";
  exit 0;
}

{
  # Seidel Cospectrals
  my @graphs = (
                #    5---4---3---2---1---8---9---10---11
                #        |   |       |
                #        6   7      12
                # https://hog.grinvin.org/ViewGraphInfo.action?id=33553
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 3, 4, 4, 3, 1, 8, 9, 10, 1],
                 undirected=>1),

                #    5---4---3---2---1---7---8---9---10
                #        |           |   |
                #        6          12  11
                # https://hog.grinvin.org/ViewGraphInfo.action?id=33555
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 3, 4, 4, 1, 7, 8, 9, 7, 1],
                 undirected=>1),
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Isomorphic Halves in HOG
  my @graphs
    = (
       [0],
       [0, 1],
       [0, 1, 2, 1],

       [0, 1, 2, 3, 2, 1, 6, 1],   # twindragon
       [0, 1, 2, 3, 4, 1, 6, 7],   # path-8

       [0, 1, 2, 3, 4, 3, 2, 7, 2, 1, 10, 11, 10, 1, 14, 1],   # binomial
       [0, 1, 2, 3, 4, 5, 4, 3, 8, 1, 10, 11, 12, 11, 10, 15], # twindragon
       [0, 1, 2, 3, 4, 5, 6, 7, 2, 1, 10, 11, 12, 13, 14, 1],  # twin alternate

       [0, 1, 2, 3, 4, 5, 4, 3, 8, 3, 2, 11, 12, 11, 2, 15, 2, 1, 18, 19, 20, 19, 18, 23, 18, 1, 26, 27, 26, 1, 30, 1],
       [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 8, 7, 12, 4, 14, 15, 14, 1, 18, 19, 20, 21, 22, 23, 24, 23, 22, 27, 19, 29, 30, 29],
       [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 7, 6, 2, 16, 1, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 22, 21, 1, 31],  # binomial

       [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 14, 13, 9, 23, 8, 25, 4, 3, 2, 29, 30, 31, 32, 1, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 45, 44, 40, 54, 39, 56, 35, 34, 1, 60, 61, 62, 63],
      );
  @graphs = map { MyGraphs::Graph_from_vpar([undef,@$_]) } @graphs;
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # All Real Roots
  my @graphs = (
                # indpoly and perfect_dompoly both all real, n=7
                # https://hog.grinvin.org/ViewGraphInfo.action?id=714
                #     Graphedron
                #  3---2---1---5---6
                #      |   |
                #      4   7
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 2, 1, 5, 1],
                 undirected=>1),
                # https://hog.grinvin.org/ViewGraphInfo.action?id=616
                #  3---2---1---4---5
                #         / \
                #        6   7
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 1, 4, 1, 1],
                 undirected=>1),

                # indpoly and perfect_dompoly both all real, n=8
                # https://hog.grinvin.org/ViewGraphInfo.action?id=32285
                #         7
                #         |
                # 3---2---1---5---6
                #     |   |
                #     4   8
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 2, 1, 5, 1, 1],
                 undirected=>1),
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Kreweras Lattice
  require Graph;
  my $graph = Graph->new (undirected => 0);
  $graph->set_graph_attribute
    (name => "Kreweras Lattice Siblings Subsets");
  my $N = 0;
  if (1) {
    # N=4 forests
    $N = 4;
    $graph->add_edges(
                      ['0123','0122'],
                      ['0123','0121'],
                      ['0123','0120'],
                      ['0123','0112'],
                      ['0123','0101'],
                      ['0123','0012'],
                      ['0122','0111'],
                      ['0122','0100'],
                      ['0122','0011'],
                      ['0121','0111'],
                      ['0121','0010'],
                      ['0120','0110'],
                      ['0120','0100'],
                      ['0120','0010'],
                      ['0112','0111'],
                      ['0112','0110'],
                      ['0112','0001'],
                      ['0111','0000'],
                      ['0110','0000'],
                      ['0101','0100'],
                      ['0101','0001'],
                      ['0100','0000'],
                      ['0012','0011'],
                      ['0012','0010'],
                      ['0012','0001'],
                      ['0011','0000'],
                      ['0010','0000'],
                      ['0001','0000'],
                      # num edges 28
                     );
  }
  MyGraphs::Graph_view($graph);

  if ($graph->is_directed) {
    $graph = $graph->undirected_copy;
  }
  my @vertices = sort $graph->vertices;
  my @degrees = map {$graph->degree($_)} @vertices;
  print join(',',@degrees),"\n";

  MyGraphs::hog_searches_html($graph);
  MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);

  exit 0;
}

{
  # Downwards Flip Graph
  require Graph;
  my $graph = Graph->new (undirected => 0);
  $graph->set_graph_attribute
    (name => "Pre-Order Depths Vectors Difference 1");
  my $N = 0;
  if (1) {
    # N=3 forests, 4-cycle and hanging leaf
    $N = 3;
    $graph->add_edges(
                      ['0000', '0123'],
                      ['0001', '0120'],
                      ['0002', '0121'],
                      ['0003', '0122'],
                      ['0040', '0122'],
                      ['0010', '0102'],
                      ['0011', '0103'],
                      ['2001', '0020'],
                      ['3001', '2022'],
                      ['4010', '2022'],
                      ['0020', '0112'],
                      ['0102', '0010'],
                      ['0022', '0113'],
                      ['0302', '0111'],
                      ['0420', '0111'],
                      ['0300', '0113'],
                      ['0013', '0100'],
                      ['0023', '0111'],
                      ['0303', '0112'],
                      ['0340', '0111'],
                      ['0400', '0313'],
                      ['0041', '0100'],
                      ['0042', '0111'],
                      ['0403', '0111'],
                      ['0440', '0121'],
                      ['0100', '0013'],
                      ['0101', '0012'],
                      ['0012', '0101'],
                      ['0103', '0011'],
                      ['0140', '0011'],
                      ['0110', '0021'],
                      ['0111', '0023'],
                      ['2011', '0003'],
                      ['3101', '0002'],
                      ['4110', '0020'],
                      ['2010', '0002'],
                      ['0112', '0020'],
                      ['2012', '0001'],
                      ['2301', '0000'],
                      ['2410', '0000'],
                      ['3100', '0003'],
                      ['0113', '0022'],
                      ['3021', '0000'],
                      ['3103', '0001'],
                      ['3140', '0000'],
                      ['4100', '3303'],
                      ['0141', '0022'],
                      ['4012', '0000'],
                      ['4103', '0000'],
                      ['4140', '0010'],
                      ['2000', '0023'],
                      ['0021', '0110'],
                      ['2002', '0021'],
                      ['2003', '0022'],
                      ['2040', '0022'],
                      ['0120', '0001'],
                      ['0121', '0002'],
                      ['2021', '0010'],
                      ['3102', '0000'],
                      ['4120', '0000'],
                      ['2020', '0012'],
                      ['0122', '0003'],
                      ['2022', '0013'],
                      ['2302', '0001'],
                      ['2420', '0010'],
                      ['2300', '0003'],
                      ['0312', '0000'],
                      ['2023', '0011'],
                      ['2303', '0002'],
                      ['2340', '0000'],
                      ['2400', '3303'],
                      ['0421', '0000'],
                      ['2042', '0011'],
                      ['2403', '0000'],
                      ['2440', '0020'],
                      ['3000', '2023'],
                      ['0301', '0110'],
                      ['3002', '2020'],
                      ['3003', '2021'],
                      ['3040', '2022'],
                      ['0310', '0001'],
                      ['0311', '0003'],
                      ['2013', '0000'],
                      ['3301', '0100'],
                      ['4310', '0000'],
                      ['3020', '0002'],
                      ['0123', '0000'],
                      ['3022', '0003'],
                      ['3302', '0101'],
                      ['3420', '0000'],
                      ['3300', '0103'],
                      ['0313', '0002'],
                      ['3023', '0001'],
                      ['3303', '0102'],
                      ['3340', '0100'],
                      ['3400', '0303'],
                      ['0341', '0000'],
                      ['3042', '0000'],
                      ['3403', '0101'],
                      ['3440', '2020'],
                      ['4000', '3023'],
                      ['0401', '0010'],
                      ['4002', '0020'],
                      ['4003', '2022'],
                      ['4040', '2012'],
                      ['0410', '0101'],
                      ['0411', '0303'],
                      ['2041', '0000'],
                      ['3401', '0000'],
                      ['4410', '0100'],
                      ['4020', '2002'],
                      ['0142', '0000'],
                      ['4022', '3003'],
                      ['4302', '0000'],
                      ['4420', '0110'],
                      ['4300', '3003'],
                      ['0413', '0000'],
                      ['4023', '0000'],
                      ['4303', '2002'],
                      ['4340', '0110'],
                      ['4400', '3103'],
                      ['0441', '0020'],
                      ['4042', '0010'],
                      ['4403', '0100'],
                      ['4440', '0120'],
                     );
  }
  MyGraphs::Graph_view($graph);

  if ($graph->is_directed) {
    $graph = $graph->undirected_copy;
  }
  my @vertices = sort $graph->vertices;
  my @degrees = map {$graph->degree($_)} @vertices;
  print join(',',@degrees),"\n";

  MyGraphs::hog_searches_html($graph);
  MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);

  exit 0;
}


{
  # Balanced Binary First Flip

  my $N = 4;
  require Graph;
  my $graph = Graph->new (undirected => 0);
  require Math::NumSeq::BalancedBinary;
  my $seq = Math::NumSeq::BalancedBinary->new;
  for (;;) {
    my ($i, $value) = $seq->next;
    my $b = cnv($value,10,2);
    if (length($b) == 2*$N) {
      $graph->add_vertex($b);
    }
    if (length($b) > 2*$N) { last; }
  }
  foreach my $from ($graph->vertices) {
    my $to = $from;
    # if ($to =~ s/(0+)1/1$1/) {         # first
    #   $graph->add_edge($from,$to);
    # }

    if ($to =~ s/((.*1)?)(0+)1/${1}1$3/) {   # last
      $graph->add_edge($from,$to);
    }

    # my $to = reverse $from;
    # if ($to =~ s/10/01/) {
    #   $to = reverse $to;
    #   $graph->add_edge($from,$to);
    # }
  }
  my $num_edges = $graph->edges;
  MyGraphs::Graph_view($graph);
  exit 0;
}

{
  require Graph;
  my $graph = Graph->new (undirected => 0);
  $graph->set_graph_attribute
    (name => "Pre-Order Depths Vectors Difference 1");
  my $N = 0;
  if (0) {
    # N=3 forests, 4-cycle and hanging leaf
    $N = 3;
    $graph->add_edges(
                      ['000','001'],
                      ['000','010'],
                      ['001','011'],
                      ['010','011'],
                      ['011','012'],
                     );
  }
  if (0) {
    $N = 4;
    $graph->add_edges(
                      ['0000','0001'],
                      ['0000','0010'],
                      ['0000','0100'],
                      ['0001','0011'],
                      ['0001','0101'],
                      ['0010','0011'],
                      ['0010','0110'],
                      ['0011','0012'],
                      ['0011','0111'],
                      ['0012','0112'],
                      ['0100','0101'],
                      ['0100','0110'],
                      ['0101','0111'],
                      ['0110','0111'],
                      ['0110','0120'],
                      ['0111','0112'],
                      ['0111','0121'],
                      ['0112','0122'],
                      ['0120','0121'],
                      ['0121','0122'],
                      ['0122','0123'],
                      ,
                     );
  }
  if (1) {
    $N = 5;
    $graph->add_edges(
                      ['00000','00001'],
                      ['00000','00010'],
                      ['00000','00100'],
                      ['00000','01000'],
                      ['00001','00011'],
                      ['00001','00101'],
                      ['00001','01001'],
                      ['00010','00011'],
                      ['00010','00110'],
                      ['00010','01010'],
                      ['00011','00012'],
                      ['00011','00111'],
                      ['00011','01011'],
                      ['00012','00112'],
                      ['00012','01012'],
                      ['00100','00101'],
                      ['00100','00110'],
                      ['00100','01100'],
                      ['00101','00111'],
                      ['00101','01101'],
                      ['00110','00111'],
                      ['00110','00120'],
                      ['00110','01110'],
                      ['00111','00112'],
                      ['00111','00121'],
                      ['00111','01111'],
                      ['00112','00122'],
                      ['00112','01112'],
                      ['00120','00121'],
                      ['00120','01120'],
                      ['00121','00122'],
                      ['00121','01121'],
                      ['00122','00123'],
                      ['00122','01122'],
                      ['00123','01123'],
                      ['01000','01001'],
                      ['01000','01010'],
                      ['01000','01100'],
                      ['01001','01011'],
                      ['01001','01101'],
                      ['01010','01011'],
                      ['01010','01110'],
                      ['01011','01012'],
                      ['01011','01111'],
                      ['01012','01112'],
                      ['01100','01101'],
                      ['01100','01110'],
                      ['01100','01200'],
                      ['01101','01111'],
                      ['01101','01201'],
                      ['01110','01111'],
                      ['01110','01120'],
                      ['01110','01210'],
                      ['01111','01112'],
                      ['01111','01121'],
                      ['01111','01211'],
                      ['01112','01122'],
                      ['01112','01212'],
                      ['01120','01121'],
                      ['01120','01220'],
                      ['01121','01122'],
                      ['01121','01221'],
                      ['01122','01123'],
                      ['01122','01222'],
                      ['01123','01223'],
                      ['01200','01201'],
                      ['01200','01210'],
                      ['01201','01211'],
                      ['01210','01211'],
                      ['01210','01220'],
                      ['01211','01212'],
                      ['01211','01221'],
                      ['01212','01222'],
                      ['01220','01221'],
                      ['01220','01230'],
                      ['01221','01222'],
                      ['01221','01231'],
                      ['01222','01223'],
                      ['01222','01232'],
                      ['01223','01233'],
                      ['01230','01231'],
                      ['01231','01232'],
                      ['01232','01233'],
                      ['01233','01234'],
                     );
  }
  MyGraphs::Graph_view($graph);
  MyGraphs::Graph_print_tikz($graph);

  if ($graph->is_directed) {
    $graph = $graph->undirected_copy;
  }
  my @vertices = sort $graph->vertices;
  my @degrees = map {$graph->degree($_)} @vertices;
  print join(',',@degrees),"\n";

  foreach my $i (0 .. $#vertices) {
    if ($graph->degree($vertices[$i]) == 3) {
      my @neighbours = sort $graph->neighbours($vertices[$i]);
      my @degrees = map {$graph->degree($_)} @neighbours;
      my $degrees = join(',',@degrees);
      if ($degrees eq '333' && $vertices[$i] ne '0000') { die; }
      print "$vertices[$i]  neighbours $degrees\n";
    }
  }

  MyGraphs::hog_searches_html($graph);

  {
    my $b_graph = Graph->new (undirected => 0);
    require Math::NumSeq::BalancedBinary;
    my $seq = Math::NumSeq::BalancedBinary->new;
    for (;;) {
      my ($i, $value) = $seq->next;
      my $b = cnv($value,10,2);
      if (length($b) > 2*$N) { last; }
      if (length($b) == 2*$N) {
        $b_graph->add_vertex($b);
      }
    }
    foreach my $b ($b_graph->vertices) {
      foreach my $pos (0 .. length($b)-2) {
        if (substr($b,$pos,2) eq '01') {
          my $to = $b;
          substr($to,$pos,2,'10');
          $b_graph->has_vertex($to) || die;
          $b_graph->add_edge($to,$b);
        }
      }
    }
    my $num_edges = $graph->edges;
    # MyGraphs::Graph_view($b_graph);
    MyGraphs::Graph_is_isomorphic($graph,$b_graph) or die;
  }

  MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);


  foreach my $start ('01234') {
    print "Hamiltonian path start $start: ";
    $graph->degree($start) == 1 or die;
    my %ends;
    print MyGraphs::Graph_is_Hamiltonian($graph, type=>'path', start=>$start, verbose=>1, all=>1,
                                         found_coderef => sub { $ends{$_[-1]} = 1; })
      ? "yes" : "no", "\n";
    print scalar(keys %ends)," ends: ", join(" ",keys %ends),"\n";
  }

  exit 0;
}
{
  # Lexmin/Lexmax/Premax Unlabelled Trees N=4 Depths Differing One Place

  # https://hog.grinvin.org/ViewGraphInfo.action?id=32274
  my @lexmax_forests_4 = ([4, 3, 1, 0],    #   0 singleton
                          [4, 4, 0, 3],    #   1 singleton
                          [4, 4, 2, 0],
                          [4, 1, 0, 0],    # 3 clique
                          [4, 4, 4, 0],
                          [4, 4, 0, 0],    # 5 clique
                          [4, 3, 0, 0],    # 6 clique
                          [4, 0, 0, 0],    # 7 clique
                          [0, 0, 0, 0]);   #   8 singleton

  # https://hog.grinvin.org/ViewGraphInfo.action?id=32276
  my @lexmax_forests_5 = ([5, 4, 2, 1, 0],  # 0
                          [5, 5, 4, 0, 3],
                          [5, 5, 2, 0, 4],
                          [5, 5, 4, 2, 0],  # 3
                          [5, 4, 0, 1, 0],
                          [5, 5, 5, 0, 4],
                          [5, 5, 4, 0, 4],
                          [5, 5, 0, 0, 4],
                          [5, 5, 2, 1, 0],
                          [5, 5, 5, 3, 0],
                          [5, 5, 2, 0, 0],
                          [5, 4, 2, 0, 0],
                          [5, 1, 0, 0, 0],
                          [5, 5, 5, 5, 0],
                          [5, 5, 5, 0, 0],
                          [5, 5, 4, 0, 0],
                          [5, 5, 0, 0, 0],
                          [5, 4, 0, 0, 0],
                          [5, 0, 0, 0, 0],
                          [0, 0, 0, 0, 0]); # 19

  # https://hog.grinvin.org/ViewGraphInfo.action?id=32190
  # canonical: HAA?PKy
  my @lexmin_forests_4 = ([0, 1, 2, 3],
                          [0, 1, 2, 2],
                          [0, 1, 1, 2],
                          [0, 0, 1, 3],
                          [0, 1, 1, 1],
                          [0, 0, 1, 1],
                          [0, 0, 1, 2],
                          [0, 0, 0, 1],
                          [0, 0, 0, 0]);

  # canonical: S???@@???_@??g_C?AGO@@`??KoGcOaO_
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32188
  my @lexmin_forests_5 = ([0, 1, 2, 3, 4],
                          [0, 1, 2, 3, 3],
                          [0, 1, 2, 2, 3],
                          [0, 1, 1, 2, 4],
                          [0, 0, 1, 3, 4],
                          [0, 1, 2, 2, 2],
                          [0, 1, 1, 2, 2],
                          [0, 0, 1, 3, 3],
                          [0, 1, 1, 2, 3],
                          [0, 1, 1, 1, 2],
                          [0, 0, 1, 1, 3],
                          [0, 0, 1, 2, 3],
                          [0, 0, 0, 1, 4],
                          [0, 1, 1, 1, 1],
                          [0, 0, 1, 1, 1],
                          [0, 0, 1, 1, 2],
                          [0, 0, 0, 1, 1],
                          [0, 0, 0, 1, 2],
                          [0, 0, 0, 0, 1],
                          [0, 0, 0, 0, 0]);

  my @premax_forests_4 = ([0, 1, 2, 3],
                          [0, 1, 2, 2],
                          [0, 1, 2, 1],
                          [0, 1, 2, 0],
                          [0, 1, 1, 1],
                          [0, 1, 1, 0],
                          [0, 1, 0, 3],
                          [0, 1, 0, 0],
                          [0, 0, 0, 0]);

  # canonical: S?G???CE?aWA@_@GCK?DDAOW?\GESaCE{
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32192
  # Hamiltonian path
  # not starting 4
  my @premax_forests_5 = ([0, 1, 2, 3, 4],
                          [0, 1, 2, 3, 3],
                          [0, 1, 2, 3, 2],
                          [0, 1, 2, 3, 1],
                          [0, 1, 2, 3, 0],
                          [0, 1, 2, 2, 2],
                          [0, 1, 2, 2, 1],
                          [0, 1, 2, 2, 0],
                          [0, 1, 2, 1, 4],
                          [0, 1, 2, 1, 1],
                          [0, 1, 2, 1, 0],
                          [0, 1, 2, 0, 4],
                          [0, 1, 2, 0, 0],
                          [0, 1, 1, 1, 1],
                          [0, 1, 1, 1, 0],
                          [0, 1, 1, 0, 4],
                          [0, 1, 1, 0, 0],
                          [0, 1, 0, 3, 0],
                          [0, 1, 0, 0, 0],
                          [0, 0, 0, 0, 0]);

  my @lexmins;
  @lexmins = @lexmin_forests_5;
  @lexmins = @lexmin_forests_4;
  @lexmins = @premax_forests_5;
  @lexmins = @premax_forests_4;
  @lexmins = @lexmax_forests_4;
  @lexmins = @lexmax_forests_5;

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_vertices(0..$#lexmins);
  foreach my $i (0..$#lexmins) {
    foreach my $j ($i+1..$#lexmins) {
      if (arefs_num_diffs($lexmins[$i],$lexmins[$j]) == 1) {
        $graph->add_edge($i,$j);
      }
    }
  }
  my $canon_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print "canonical: ",$canon_g6;

  MyGraphs::Graph_print_dreadnaut($graph);
  MyGraphs::Graph_print_tikz($graph);
  MyGraphs::Graph_view($graph);
  print "degrees ", join(',',map{$graph->degree($_)} 0..$#lexmins), "\n";
  print "edges ", scalar($graph->edges), "\n";
  MyGraphs::hog_searches_html($graph);

  foreach my $start (19) {
    print "Hamiltonian path start $start: ";
    print MyGraphs::Graph_is_Hamiltonian($graph, type=>'path', start=>$start, verbose=>1)
      ? "yes" : "no", "\n";
  }
  foreach my $type ('path','cycle') {
    print "Hamiltonian $type: ";
    print MyGraphs::Graph_is_Hamiltonian($graph, type=>$type, verbose=>1)
      ? "yes" : "no", "\n";
  }
  exit 0;
}
{
  # E8 Automorphism Group
  my @graphs = (
                # n=7 forest 
                # >>graph6<<F??H_
                # 1 fixed point
                # https://hog.grinvin.org/ViewGraphInfo.action?id=28520
                # "test"
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 1, 0, 4, 0, 0],
                undirected=>1),

                # n=8 forest
                # 0 fixed points
                # https://hog.grinvin.org/ViewGraphInfo.action?id=32267
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 1, 0, 5, 0, 0],
                undirected=>1),

                # n=10 two trees, one
                # https://hog.grinvin.org/ViewGraphInfo.action?id=32269
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 3, 3, 1, 6, 6, 1, 1],
                 undirected=>1),

                # n=10 two trees, two
                # https://hog.grinvin.org/ViewGraphInfo.action?id=32271
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 2, 1, 5, 1, 7, 1, 1],
                undirected=>1),

                # n=13 tree one fixed point
                # HOG not
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 3, 1, 5, 6, 1, 8, 1, 10, 1, 1],
                undirected=>1),
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # minmum 3 generators for automorphism group
  # HOG not

  my @graphs = (# n=9 tree  S2wrS2 x S2
                # https://hog.grinvin.org/ViewGraphInfo.action?id=32264
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 2, 1, 5, 5, 1, 1],
                undirected=>1),

                # n=6 forest  S2wrS2 x S2
                # https://hog.grinvin.org/ViewGraphInfo.action?id=896
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 0, 3, 0, 0],
                undirected=>1),
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Pallo binary tree weight partial ordering

  require Graph;
  my $graph = Graph->new;
  $graph->add_edges([1111, 1112], [1111, 1121], [1111, 1211]);
  $graph->add_edges([1112, 1212], [1112, 1113]);
  $graph->add_edges([1212, 1214]);
  $graph->add_edges([1214, 1234]);

  $graph->add_edges([1121, 1131], [1121, 1123]);
  $graph->add_edges([1113, 1114], [1113, 1123]);
  $graph->add_edges([1114, 1124], [1114, 1214]);

  $graph->add_edges([1211, 1212], [1211, 1231]);
  $graph->add_edges([1123, 1124]);
  $graph->add_edges([1131, 1231], [1131, 1134]);

  $graph->add_edges([1231, 1234]);
  $graph->add_edges([1124, 1134]);
  $graph->add_edges([1134, 1234]);

  foreach my $from ($graph->vertices) {
    foreach my $to ($graph->vertices) {
      next if $from eq $to;
      my $want = 1;
      foreach my $i (0..3) {
        if (substr($from,$i,1) > substr($to,$i,1)) { $want = 0; }
      }
      my $got = $graph->has_edge($from,$to) ? 1 : 0;
      $got <= $want or die "$from -> $to want $want got $got";
    }
  }

  $graph->set_graph_attribute (flow => 'south');
  $graph->set_vertex_attribute (1111, 'xy', "0,0");

  $graph->set_vertex_attribute (1112, 'xy', "2,0");
  $graph->set_vertex_attribute (1121, 'xy', "1,-1");
  $graph->set_vertex_attribute (1211, 'xy', "0,-2");

  $graph->set_vertex_attribute (1212, 'xy', "3,0");
  $graph->set_vertex_attribute (1113, 'xy', "2,-1");
  $graph->set_vertex_attribute (1123, 'xy', "1.5,-2");
  $graph->set_vertex_attribute (1231, 'xy', "0,-3");

  $graph->set_vertex_attribute (1214, 'xy', "4,0");
  $graph->set_vertex_attribute (1114, 'xy', "3,-1");
  $graph->set_vertex_attribute (1131, 'xy', "2,-2");
  $graph->set_vertex_attribute (1124, 'xy', "1,-3");

  $graph->set_vertex_attribute (1131, 'xy', "3,-2");
  $graph->set_vertex_attribute (1134, 'xy', "3,-3");

  $graph->set_vertex_attribute (1234, 'xy', "4,-4");

  # MyGraphs::Graph_view($graph);
  # MyGraphs::Graph_print_tikz($graph);

  {
    my $gen = Graph->new;
    $gen->add_edges(
                    [1111,1112],
                    [1111,1121],
                    [1111,1211],
                    [1112,1113],
                    [1112,1212],
                    [1113,1114],
                    [1113,1123],
                    [1114,1124],
                    [1114,1214],
                    [1121,1123],
                    [1121,1131],
                    [1123,1124],
                    [1124,1134],
                    [1131,1134],
                    [1131,1231],
                    [1134,1234],
                    [1211,1212],
                    [1211,1231],
                    [1212,1214],
                    [1214,1234],
                    [1231,1234],
                   );
    # print "$gen\n";
    # MyGraphs::Graph_view($gen);

    MyGraphs::Graph_is_isomorphic($graph,$gen) or die;
  }

  # MyGraphs::Graph_is_Hamiltonian($graph, type=>'cycle',
  #                                verbose=>1, all=>1);
  MyGraphs::hog_searches_html($graph);

  {
    # degree=3 regular
    $graph = $graph->undirected_copy;
    my @degrees = map {$graph->degree($_)} sort $graph->vertices;
    print join(',',@degrees),"\n";
  }

  print "Hamiltonian:\n";
  MyGraphs::Graph_is_Hamiltonian($graph, type=>'cycle',
                                 # start => '01',
                                 verbose=>1, all=>1);

  exit 0;
}



{
  # trees no fixed points
  my @graphs = (
                # G@GQSG  n=8 id=260
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 3, 4, 1, 6, 7]),

                # G?GQSK  n=8 id=700
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 3, 2, 1, 6, 1]),
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # path-3
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32234
  require Graph;
  my $graph = Graph->new (undirected=>1);
  $graph->add_path(1,2,3);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # Asymmetric, can delete edge to symmetric, cannot add to symmetric, N=9
  #
  # first 0,6 delete
  #  to autos 0,6,7 1,5,8, 2,3,4
  #  https://hog.grinvin.org/ViewGraphInfo.action?id=32230
  #
  # second 3,8 delete
  #  to autos
  #  canon >>graph6<<HPVBG}z
  #  https://hog.grinvin.org/ViewGraphInfo.action?id=32228
  #
  # both delete to same
  #  https://hog.grinvin.org/ViewGraphInfo.action?id=32232

  my $graph_06 = MyGraphs::Graph_from_graph6_str('>>graph6<<HCrfRjU');  # 0,6
  my $graph_38 = MyGraphs::Graph_from_graph6_str('>>graph6<<HCZJerr');  # 3,8
  my @graphs;
  push @graphs, $graph_06, $graph_38;
  foreach my $graph ($graph_06, $graph_38) {
    print "num edges ",scalar($graph->edges)," diameter ",scalar($graph->diameter),"\n";
    print " degrees ", sort(map{$graph->degree($_)} $graph->vertices), "\n";
    MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);
    print "\n";
  }

  print "deletes same ",
    MyGraphs::Graph_is_isomorphic($graph_06->copy->delete_edge(0,6),
                                  $graph_38->copy->delete_edge(3,8)),"\n";

  {
    print "\n";
    print "delete edge 3,8\n";
    my $graph = $graph_38->copy;
    $graph->delete_edge(3,8);
    print " degrees ", sort(map{$graph->degree($_)} $graph->vertices), "\n";
    MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);
    # MyGraphs::Graph_print_tikz($graph);
  }
  {
    print "\n";
    print "delete edge 0,6\n";
    my $graph = $graph_06->copy->delete_edge(0,6);
    print MyGraphs::Graph_to_graph6_str($graph);
    push @graphs, $graph;
  }

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # McKay equitable partition not orbit partition
  # HOG not
  require Graph;
  my $graph = Graph->new (undirected=>1);
  $graph->add_cycle(1,2,3);
  $graph->add_cycle(4,5,6);
  $graph->add_path(1,7,8,4);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # Completely Semi-Stable Irregular
  MyGraphs::hog_searches_html
      (
       # n=4
       'CF',     # claw

       # n=5
       'D?{',    # star-5
       'DF{',    # 3 triangles common edge
       'DQ{',    # 2 triangles common vertex, bow-tie

       'E?Bw',
       'E?ow',
       'E?~o',
       'E?~w',
       'ECqg',
       'ECZo',
       'ECfw',
       'ECxw',
       'EErw',
       'EEiW',
       'EEzO',
       'EElw',
       'EF~w',
       'EQ~o',
       'EQ~w',
       'EUZw',
       'ETzg',
       'E]zg',
      );
  exit 0;
}

{
  # Holton, tree stable but not completely semi-stable
  #
  # D. A. Holton, "Completely Semi-Stable Trees", Bulletin of the Australian
  # Mathematical Society, volume 9, 1973, pages 355-362.
  # https://www.cambridge.org/core/journals/bulletin-of-the-australian-mathematical-society/article/completely-semistable-trees/BEECAEA768EAFBF5A4490CAF57B93FC8

  my @graphs;
  {
    # https://hog.grinvin.org/ViewGraphInfo.action?id=714
    # F?_ZG
    #
    #     1         6---7
    #      \       /
    #       2 --- 4
    #      /       \
    #     3         5

    require Graph;
    my $graph = Graph->new (undirected=>1);
    $graph->add_path(1,2,3,2,4,5,4,6,7);
    $graph->is_connected or die;

    # MyGraphs::Graph_view($graph);
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    print "canonical: ",$canon_g6;
    MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Sharma auts equal but different stable

  # Aruna Sharma, "A Note on Stability of Graphs", Discrete Mathematics,
  # volume 49, 1984, pages 201-203.

  require Graph;
  my @graphs;
  {
    # Stability index 5 only
    # HOG not
    my $graph = Graph->new (undirected=>1);
    $graph->add_path(8,7,9,7, 6,1,2,3,4,5,1,4,3,1);
    # MyGraphs::Graph_view($graph);
    MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);
    $graph->is_connected or die;
    $graph->complement->is_connected or die;
    push @graphs, $graph;
  }
  print "\n";
  {
    # Stability index 5 only
    # HOG not
    my $graph = Graph->new(undirected=>1);
    $graph->add_path(7,6,1,2,3,9,8,4,5,1);
    $graph->add_edges([3,8], [4,9]);
    # MyGraphs::Graph_view($graph);
    MyGraphs::Graph_run_dreadnaut($graph, verbose=>1);
    $graph->is_connected or die;
    $graph->complement->is_connected or die;
    push @graphs, $graph;
  }
  print "isomorphic: ",
    MyGraphs::Graph_is_isomorphic($graphs[0],$graphs[1]) || 0, "\n";

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Cubic Planar non-Hamiltonian
  my @graphs;
  {
    # 1-connected cubic planar non-Hamiltonian
    # in HOG
    require Graph;
    my $graph = Graph->new(undirected => 1);
    $graph->add_cycle(1,2,3,4);
    $graph->add_path(2,4);
    $graph->add_path(1,5,3);

    $graph->add_cycle(11,12,13,14);
    $graph->add_path(12,14);
    $graph->add_path(11,15,13);

    $graph->add_path(5,15);
    MyGraphs::Graph_view($graph);
    push @graphs, $graph;
  }
  {
    # 2-connected cubic planar non-Hamiltonian
    # HOG not
    require Graph;
    my $graph = Graph->new(undirected => 1);
    $graph->add_cycle(1,2,3,4);
    $graph->add_path(2,4);

    $graph->add_cycle(11,12,13,14);
    $graph->add_path(12,14);

    $graph->add_cycle(21,22,23,24);
    $graph->add_path(22,24);

    $graph->add_path(1,5,11);
    $graph->add_path(5,21);

    $graph->add_path(3,6,13);
    $graph->add_path(6,23);

    MyGraphs::Graph_view($graph);
    push @graphs, $graph;
  }
  {
    # cyclically 4-connected cubic planar non-Hamiltonian
    # in HOG
    #
    #  1-----------------------------------------2
    #  | \                                     / |
    #  |  3---4-------5-----------6-------7---8  |
    #  |  |   |       |           |       |   |  |
    #  |  |   |       9----10----11       |   |  |
    #  |  |   |     /       |      \      |   |  |
    #  |  |  12---13        |        14--15   |  |
    #  |  |   |     \       |       /     |   |  |
    #  |  |   |      16----17----18       |   |  |
    #  |  |   |       |           |       |   |  |
    #  |  |   |       |           |       |   |  |
    #  | 19--20      21----------22      23--24  |
    #  |  |   |       |           |       |   |  |
    #  |  |   |       |           |       |   |  |
    #  |  |   |      25----26----27       |   |  |
    #  |  |   |     /       |      \      |   |  |
    #  |  |  28---29        |       30---31   |  |
    #  |  |   |     \       |      /      |   |  |
    #  |  |   |      32----33----34       |   |  |
    #  |  |   |       |           |       |   |  |
    #  |  35--36-----37----------38------39--40  |
    #  | /                                     \ |
    # 41----------------------------------------42

    require Graph;
    my $graph = Graph->new(undirected => 1);
    $graph->add_cycle(1,2,42,41);
    $graph->add_path(1,3,19,35,41);
    $graph->add_path(35 .. 40);
    $graph->add_path(42,40,24,8,2);
    $graph->add_path(3 .. 8);

    $graph->add_path(4,12,20,28,36);  $graph->add_path(19,20);
    $graph->add_path(7,15,23,31,39);  $graph->add_path(23,24);

    $graph->add_cycle(9,10,11,14,18,17,16,13);
    $graph->add_cycle(25,26,27,30,34,33,32,29);
    $graph->add_edges([5,9], [6,11], [10,17], [12,13],[14,15]);
    $graph->add_edges([37,32], [38,34], [33,26], [28,29],[30,31]);
    $graph->add_path(16,21,25);
    $graph->add_path(18,22,27);
    $graph->add_path(21,22);

    foreach my $v ($graph->vertices) { $graph->degree($v)==3 or die $v };

    MyGraphs::Graph_view($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # vpar_to_GraphViz2
  my $graphviz2 = MyGraphs::vpar_to_GraphViz2([undef, 12,1,1,1,9, 3,6,7,4,4,4,0,0,0]);
  $graphviz2->run(format => 'x11',
                  driver => 'dot',
                 );
  print $graphviz2->dot_input;
  exit 0;
}
{
  # Interlaced Squares - Euler Circuit

  #  *-----------*           5
  #  |           |
  #  |   *-------*---*       4
  #  |   |       |   |
  #  |   |   *---*---*---*   3
  #  |   |   |   |   |   |
  #  *---*---*---*   |   |   2
  #      |   |       |   |
  #      *---*-------*   |   1
  #          |           |
  #          *-----------*   0
  #  0   1   2   3   4   5
  #
  # HOG not

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  $graph->add_cycle('2,0', '5,0', '5,3', '4,3', '3,3', '2,3', '2,2', '2,1'); 
  $graph->add_cycle('1,1', '2,1', '4,1', '4,3', '4,4', '3,4', '1,4', '1,2'); 
  $graph->add_cycle('0,2', '1,2', '2,2', '3,2', '3,3', '3,4', '3,5', '0,5'); 
  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # Preorder Trees N=5 Depths Differing One Place
  # n=14 e=28
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32179

  # (2 3)(5 6)(7 8)(10 11)(12 13)
  # level 1:  9 orbits; 7 fixed; index 2
  # 9 orbits; grpsize=2; 1 gen; 3 nodes; maxlev=2

  # M@QH?dOWGS`L`a`P_
  my @depths_forests_4 = ([0, 1, 2, 3, 4],   # N=5 trees, N=4 forests
                          [0, 1, 2, 3, 3],
                          [0, 1, 2, 3, 2],   # 2  deg=5
                          [0, 1, 2, 3, 1],   # 3  deg=5
                          [0, 1, 2, 2, 3],
                          [0, 1, 2, 2, 2],   # 6  deg=5
                          [0, 1, 2, 2, 1],   # 5  deg=5
                          [0, 1, 2, 1, 2],
                          [0, 1, 2, 1, 1],
                          [0, 1, 1, 2, 3],
                          [0, 1, 1, 2, 2],
                          [0, 1, 1, 2, 1],
                          [0, 1, 1, 1, 2],
                          [0, 1, 1, 1, 1],
                         );

  # same
  # M@QH?dOWGS`L`a`P_
  my @depths_forests_4_postorder = ([3, 2, 1, 0],
                                    [2, 2, 1, 0],
                                    [2, 1, 1, 0],
                                    [2, 1, 0, 0],
                                    [1, 2, 1, 0],
                                    [1, 1, 1, 0],
                                    [1, 1, 0, 0],
                                    [1, 0, 1, 0],
                                    [1, 0, 0, 0],
                                    [0, 2, 1, 0],
                                    [0, 1, 1, 0],
                                    [0, 1, 0, 0],
                                    [0, 0, 1, 0],
                                    [0, 0, 0, 0]);

  # @depths = ([0, 1, 2, 3],       # N=4 trees, N=3 forests
  #            [0, 1, 2, 2],
  #            [0, 1, 2, 1],
  #            [0, 1, 1, 2],
  #            [0, 1, 1, 1]);

  # i?CAKG_GC@@?C@C?@?HO?K?CC??AOG?_G?`G?GKG?cO?Aa@?@????_?_?c?O?E?B?K?o@A?D?C?P?_C?Q@?CC?CA?@?@?OG???hO???DB@???P_I???QOD_G?OAI_A?C@DPO_??`G`A??@CPG
  my @depths_forests_5 = ([0, 1, 2, 3, 4],   # N=6 trees, N=5 forests
                          [0, 1, 2, 3, 3],
                          [0, 1, 2, 3, 2],
                          [0, 1, 2, 3, 1],
                          [0, 1, 2, 3, 0],
                          [0, 1, 2, 2, 3],
                          [0, 1, 2, 2, 2],
                          [0, 1, 2, 2, 1],
                          [0, 1, 2, 2, 0],
                          [0, 1, 2, 1, 2],
                          [0, 1, 2, 1, 1],
                          [0, 1, 2, 1, 0],
                          [0, 1, 2, 0, 1],
                          [0, 1, 2, 0, 0],
                          [0, 1, 1, 2, 3],
                          [0, 1, 1, 2, 2],
                          [0, 1, 1, 2, 1],
                          [0, 1, 1, 2, 0],
                          [0, 1, 1, 1, 2],
                          [0, 1, 1, 1, 1],
                          [0, 1, 1, 1, 0],
                          [0, 1, 1, 0, 1],
                          [0, 1, 1, 0, 0],
                          [0, 1, 0, 1, 2],
                          [0, 1, 0, 1, 1],
                          [0, 1, 0, 1, 0],
                          [0, 1, 0, 0, 1],
                          [0, 1, 0, 0, 0],
                          [0, 0, 1, 2, 3],
                          [0, 0, 1, 2, 2],
                          [0, 0, 1, 2, 1],
                          [0, 0, 1, 2, 0],
                          [0, 0, 1, 1, 2],
                          [0, 0, 1, 1, 1],
                          [0, 0, 1, 1, 0],
                          [0, 0, 1, 0, 1],
                          [0, 0, 1, 0, 0],
                          [0, 0, 0, 1, 2],
                          [0, 0, 0, 1, 1],
                          [0, 0, 0, 1, 0],
                          [0, 0, 0, 0, 1],
                          [0, 0, 0, 0, 0]);

  my @depths;
  @depths = @depths_forests_4_postorder;
  @depths = @depths_forests_5;
  @depths = @depths_forests_4;

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_vertices(0..$#depths);
  foreach my $i (0..$#depths) {
    foreach my $j ($i+1..$#depths) {
      if (arefs_num_diffs($depths[$i],$depths[$j]) == 1) {
        $graph->add_edge($i,$j);
      }
    }
  }
  my $canon_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print "canonical: ",$canon_g6;

  MyGraphs::Graph_print_dreadnaut($graph);
  MyGraphs::Graph_print_tikz($graph);
  MyGraphs::Graph_view($graph);
  print "degrees ", join(',',map{$graph->degree($_)} 0..$#depths), "\n";
  print "edges ", scalar($graph->edges), "\n";
  MyGraphs::hog_searches_html($graph);

  print "Hamiltonian: ";
  print MyGraphs::Graph_is_Hamiltonian($graph) ? "yes" : "no", "\n";
  exit 0;
}
{
  # Vpar Forests N=4 differing 1 place
  # HOG not
  # n=125 e=528
  # degrees up to 12
  # 4 singletons each change to 1..3 (not self)  4*3=12

  # dreadnaut
  # 9 orbits; grpsize=24; 3 gens; 5 nodes; maxlev=2
  # gens order 2,2,3
  #
  my @vpars;
  @vpars = ([0, 0, 0, 0],
            [0, 0, 0, 1],
            [0, 0, 0, 2],
            [0, 0, 0, 3],
            [0, 0, 4, 0],
            [0, 0, 1, 0],
            [0, 0, 1, 1],
            [2, 0, 0, 1],
            [3, 0, 0, 1],
            [4, 0, 1, 0],
            [0, 0, 2, 0],
            [0, 1, 0, 2],
            [0, 0, 2, 2],
            [0, 3, 0, 2],
            [0, 4, 2, 0],
            [0, 3, 0, 0],
            [0, 0, 1, 3],
            [0, 0, 2, 3],
            [0, 3, 0, 3],
            [0, 3, 4, 0],
            [0, 4, 0, 0],
            [0, 0, 4, 1],
            [0, 0, 4, 2],
            [0, 4, 0, 3],
            [0, 4, 4, 0],
            [0, 1, 0, 0],
            [0, 1, 0, 1],
            [0, 0, 1, 2],
            [0, 1, 0, 3],
            [0, 1, 4, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 1],
            [2, 0, 1, 1],
            [3, 1, 0, 1],
            [4, 1, 1, 0],
            [2, 0, 1, 0],
            [0, 1, 1, 2],
            [2, 0, 1, 2],
            [2, 3, 0, 1],
            [2, 4, 1, 0],
            [3, 1, 0, 0],
            [0, 1, 1, 3],
            [3, 0, 2, 1],
            [3, 1, 0, 3],
            [3, 1, 4, 0],
            [4, 1, 0, 0],
            [0, 1, 4, 1],
            [4, 0, 1, 2],
            [4, 1, 0, 3],
            [4, 1, 4, 0],
            [2, 0, 0, 0],
            [0, 0, 2, 1],
            [2, 0, 0, 2],
            [2, 0, 0, 3],
            [2, 0, 4, 0],
            [0, 1, 2, 0],
            [0, 1, 2, 1],
            [2, 0, 2, 1],
            [3, 1, 0, 2],
            [4, 1, 2, 0],
            [2, 0, 2, 0],
            [0, 1, 2, 2],
            [2, 0, 2, 2],
            [2, 3, 0, 2],
            [2, 4, 2, 0],
            [2, 3, 0, 0],
            [0, 3, 1, 2],
            [2, 0, 2, 3],
            [2, 3, 0, 3],
            [2, 3, 4, 0],
            [2, 4, 0, 0],
            [0, 4, 2, 1],
            [2, 0, 4, 2],
            [2, 4, 0, 3],
            [2, 4, 4, 0],
            [3, 0, 0, 0],
            [0, 3, 0, 1],
            [3, 0, 0, 2],
            [3, 0, 0, 3],
            [3, 0, 4, 0],
            [0, 3, 1, 0],
            [0, 3, 1, 1],
            [2, 0, 1, 3],
            [3, 3, 0, 1],
            [4, 3, 1, 0],
            [3, 0, 2, 0],
            [0, 1, 2, 3],
            [3, 0, 2, 2],
            [3, 3, 0, 2],
            [3, 4, 2, 0],
            [3, 3, 0, 0],
            [0, 3, 1, 3],
            [3, 0, 2, 3],
            [3, 3, 0, 3],
            [3, 3, 4, 0],
            [3, 4, 0, 0],
            [0, 3, 4, 1],
            [3, 0, 4, 2],
            [3, 4, 0, 3],
            [3, 4, 4, 0],
            [4, 0, 0, 0],
            [0, 4, 0, 1],
            [4, 0, 0, 2],
            [4, 0, 0, 3],
            [4, 0, 4, 0],
            [0, 4, 1, 0],
            [0, 4, 1, 1],
            [2, 0, 4, 1],
            [3, 4, 0, 1],
            [4, 4, 1, 0],
            [4, 0, 2, 0],
            [0, 1, 4, 2],
            [4, 0, 2, 2],
            [4, 3, 0, 2],
            [4, 4, 2, 0],
            [4, 3, 0, 0],
            [0, 4, 1, 3],
            [4, 0, 2, 3],
            [4, 3, 0, 3],
            [4, 3, 4, 0],
            [4, 4, 0, 0],
            [0, 4, 4, 1],
            [4, 0, 4, 2],
            [4, 4, 0, 3],
            [4, 4, 4, 0],
           );

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_vertices(0..$#vpars);
  foreach my $i (0..$#vpars) {
    foreach my $j ($i+1..$#vpars) {
      if (arefs_num_diffs($vpars[$i],$vpars[$j]) == 1) {
        $graph->add_edge($i,$j);
      }
    }
  }
  MyGraphs::Graph_print_dreadnaut($graph);
  # MyGraphs::Graph_print_tikz($graph);
  # MyGraphs::Graph_view($graph);
  print "degrees ", join(',',map{$graph->degree($_)} 0..$#vpars), "\n";
  print "edges ", scalar($graph->edges), "\n";
  MyGraphs::hog_searches_html($graph);

  exit 0;
}
{
  # Vpar Forests N=3 differing 1 place
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32175
  #
  # N=4 root=1 same
  # N=4 all trees 4 copies
  #
  # (1 4)(2 3)(6 7)(8 12)(9 13)(10 15)(11 14)
  # (1 2)(3 12)(4 8)(5 10)(6 9)(7 11)(13 14)
  # level 1:  4 orbits; 6 fixed; index 6
  # 4 orbits; grpsize=6; 2 gens; 4 nodes; maxlev=2
  #
  # 6 automorphisms
  # mirror image across 3 lines
  #
  my @vpars;
  @vpars = ([0, 0, 0],     # degree=6          forests
            [0, 0, 1],     # 5,5,5,5
            [0, 0, 2],     #       v=2
            [0, 3, 0],
            [0, 1, 0],     #       v=4
            [0, 1, 1],     # 4     v=5
            [2, 0, 1],     # 3     v=6
            [3, 1, 0],     # 3     v=7
            [2, 0, 0],     # 5
            [0, 1, 2],     # 3     v=9
            [2, 0, 2],     # 4
            [2, 3, 0],     # 3
            [3, 0, 0],     # 5     v=12
            [0, 3, 1],     # 3
            [3, 0, 2],     # 3     v=14
            [3, 3, 0]);    # 4
  @vpars == 16 or die;

  if (0) {
    # trees
    # 3 of path-3
    # HOG not
    #
    # (3 6)
    # level 3:  8 orbits; 3 fixed; index 2
    # (0 8)(2 3)(5 6)
    # level 2:  5 orbits; 2 fixed; index 4
    # (1 2)(4 8)(5 7)
    # level 1:  2 orbits; 1 fixed; index 6
    # 2 orbits; grpsize=48; 3 gens; 10 nodes; maxlev=4
    #
    @vpars = ([0, 1, 1],
              [2, 0, 1],
              [3, 1, 0],
              [0, 1, 2],
              [2, 0, 2],
              [2, 3, 0],
              [0, 3, 1],
              [3, 0, 2],
              [3, 3, 0]);
    @vpars == 9 or die;
  }

  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_vertices(0..$#vpars);
  foreach my $i (0..$#vpars) {
    foreach my $j ($i+1..$#vpars) {
      if (arefs_num_diffs($vpars[$i],$vpars[$j]) == 1) {
        $graph->add_edge($i,$j);
      }
    }
  }
  MyGraphs::Graph_print_dreadnaut($graph);
  MyGraphs::Graph_print_tikz($graph);
  # MyGraphs::Graph_view($graph);
  print " degrees ", join(',',map{$graph->degree($_)} 0..$#vpars), "\n";
  MyGraphs::hog_searches_html($graph);

  foreach my $i (0..$#vpars) {
    my $vpar = $vpars[$i];
    my $num_zeros = grep {$_==0} @$vpar;
    print "vpar=",join(',',@$vpar),"  degree=",$graph->degree($i)," $num_zeros\n";
  }
  exit 0;

  sub arefs_num_diffs {
    my ($x,$y) = @_;
    $#$x==$#$y or die;
    my $ret = 0;
    foreach my $i (0 .. $#$x) {
      $ret += ($x->[$i] != $y->[$i]);
    }
    return $ret;
  }
}

{
  # Erdos and Renyi
  # Asymmetric, can delete edge to symmetric, cannot add edge to symmetric.
  # cf nautyextra devel/asymmetric-A.c

  my @graphs;
  {
    # whole, in drawing labels
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31137
    my $graph = MyGraphs::Graph_from_graph6_str('>>graph6<<Ir[gGOzCW');
    push @graphs, $graph;
  }

  # with 8,9 delete
  # https://hog.grinvin.org/ViewGraphInfo.action?id=31139
  push @graphs, '>>graph6<<Ir[gGOzCO';

  {
    # with 4,5 del
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31141
    #         0 1 2 3 4 5 6 7 8 9
    # degrees 2 3 5 5 5 2 2 3 6 3
    #               ^ ^     ^   ^
    my $graph = MyGraphs::Graph_from_graph6_str('>>graph6<<Ir[_GOzCW');
    push @graphs, $graph;
    # MyGraphs::Graph_print_tikz($graph);
    print "with 4,5 del:\n";
    print " degrees ", join(' ',map{$graph->degree($_)} 0..9), "\n";

    $graph->degree(2) == 5 || die;
    $graph->degree(3) == 5 || die;
    $graph->degree(4) == 5 || die;
    foreach my $v ($graph->neighbours(2)) {
      $graph->degree($v) != 3 || die;
    }
  }

  {
    # with 3,5 add
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31143
    my $graph = MyGraphs::Graph_from_graph6_str('>>graph6<<Ir[wGOzCW');
    push @graphs, $graph;
    MyGraphs::Graph_print_tikz($graph);
  }

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Most Minimum Dominating Sets

  my @graphs =
    (
     # n=5 has 9 minimum dominating sets
     # https://hog.grinvin.org/ViewGraphInfo.action?id=438
     '>>graph6<<D]w',

     # n=6 has 15 minimum dominating sets (domnum=3)
     # https://hog.grinvin.org/ViewGraphInfo.action?id=226
     '>>graph6<<E]~o',

     # n=7 domnum 3 in 22 ways
     # https://hog.grinvin.org/ViewGraphInfo.action?id=868
     '>>graph6<<FCZbg',

     # n=8 domnum 3 in 36 ways
     # https://hog.grinvin.org/ViewGraphInfo.action?id=30664
     '>>graph6<<GCxvBo',
    );
  foreach my $graph6 (@graphs) {
    MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($graph6));
    print "---------\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Free Tree Most Generators in a Minimum Set
  # WRONG
  my @graphs = (
                ':J`EKWTjACN'
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Minimal Asymmetric Graphs
  #
  # Pascal Schweitzer and Patrick Schweitzer, "Minimal Asymmetric Graphs",
  # Journal of Combinatorial Theory, Series B, volume 127, November 2017,
  # pages 215-227
  # https://arxiv.org/abs/1605.01320
  # https://www.sciencedirect.com/science/article/pii/S0095895617300539
  #
  # X9 tree, smallest asymmetric tree n=7
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=934
  # X14 complement of X9 tree
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=31120
  #
  my @graphs;
  {
    # tree star arms 1,2,3
    my $graph = MyGraphs::Graph_from_graph6_str(':FaIjL');
    push @graphs, $graph;
    push @graphs, $graph->complement;
  }
  {
    # smallest asymmetric, 6 vertices
    # triangle and arms 0,1,2
    my $graph = Graph->new(undirected => 1);
    $graph->add_cycle(1,2,3);
    $graph->add_path(1,4);
    $graph->add_path(2,5,6);
    push @graphs, $graph;
    push @graphs, $graph->complement;
  }
  # MyGraphs::Graph_print_tikz($graphs[1]);
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Automorphisms C3
  my @graphs = (
                # HOG got
                '>>graph6<<HCOedLj',

                '>>graph6<<HCpdmji',
                '>>graph6<<HCrVNZr',
                '>>graph6<<HCZJerb',

                # N=10, 15 edges
                # canon >>graph6<<I?_aCwuU_
                '>>graph6<<I?`@Eqq\?',

                # N=10, 15 edges
                # canon >>graph6<<I?cqcGbQW
                '>>graph6<<I?`afASUO',
               );
  MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($graphs[5]));
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # n=20 five different
  # domnum, indomnum, perfect_domnum, totdomnum, semitotdomnum
  # >>sparse6<<:S_`abccaff`ijk`_nop_
  # https://hog.grinvin.org/ViewGraphInfo.action?id=31101

  my @graphs = (
                '>>sparse6<<:S_`abccaff`ijk`_nop_',

                '>>sparse6<<:W_`abc`efg`ijk`mmm_qrstq',
                '>>sparse6<<:W_`abcdefcbbakk_nopqrsp_',
               );
  MyGraphs::hog_searches_html(@graphs);
  # MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($graphs[2]));

  exit 0;
}

{
  # Jaroslav Nesetril, "A Congruence Theorem For Asymmetric Trees", Pacific
  # Journal of Mathematics, volume 37, number 3, March 1971, pages 771-778.
  # https://projecteuclid.org/euclid.pjm/1102970478

  require Graph;
  my @graphs;
  {
    # n=9 star path with leaves at positions 3,4
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31095
    my $graph = Graph->new(undirected => 1);
    $graph->add_path(1,2,3,4,5,6,7);
    $graph->add_path(3,8);
    $graph->add_path(4,9);
    push @graphs, $graph;
  }
  {
    # n=9 star arms 1,3,4
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31097
    my $graph = Graph->new(undirected => 1);
    $graph->add_path(1,2);
    $graph->add_path(1,3,4,5);
    $graph->add_path(1,6,7,8,9);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }
  {
    # n=8 star arms 1,2,4 second smallest free asymmetric
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31099
    my $graph = Graph->new(undirected => 1);
    $graph->add_path(1,2);
    $graph->add_path(1,3,4);
    $graph->add_path(1,6,7,8,9);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Smallest Asymmetrics

  my @graphs = (
                # n=6, e=6 edges
                # HOG not
                '>>graph6<<ECZG',

                # n=6, e=9 edges, complement of e=6
                # GP-Test  6*5/2 - 9 == 6
                # HOG not
                '>>graph6<<EEno',
               );
  MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($graphs[0]));
  MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($graphs[1]));
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # disjoint domnum most ways n=12
  # https://hog.grinvin.org/ViewGraphInfo.action?id=31088

  my @graphs = (# n=12
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 2, 3, 3, 2, 6, 1, 8, 9, 8, 11]),

                # n=19 subdivided bistar
                MyGraphs::Graph_from_vpar
                ([undef, 0,1,2,3,2,5,2,7,2,9,1,11,12,11,14,11,16,11,18]),
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Mowshowitz cospectral trees family
  my @graphs = (MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 1, 1, 1, 5, 5, 5]),
                MyGraphs::Graph_from_vpar
                ([undef, 8, 1, 8, 3, 3, 3, 3, 0]),
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  require File::Slurp;
  foreach my $filename (glob("/so/hog/graphs/*.html")) {
    my $str = File::Slurp::read_file($filename);
    $str =~ /Acyclic.*?(Yes|No)/s or die $filename;
    lc($1) eq 'yes' or next;

    $str =~ /Chromatic Index.*?(\d+|Computation time out)/s or die $filename;
    my $chromatic_index = $1;

    $str =~ /Maximum Degree.*?(\d+)/s or die $filename;
    my $maximum_degree = $1;
    print "$filename $chromatic_index $maximum_degree\n";

    if ($chromatic_index ne 'Computation time out'
        && $chromatic_index ne $maximum_degree) {
      die $filename;
    }
  }
  print "ok\n";
  exit 0;
}

{
  # n=8 cospectral free trees
  #
  #  [0, 1, 2, 2, 2, 2, 1, 7]
  #     *---*---*---*
  #   /| |\
  #  * * * *
  #
  #  [0, 1, 2, 2, 2, 1, 1, 1]   bi-star 4,4

  MyGraphs::hog_searches_html(':GaXeWz',
                              ':GaXeGb');
  exit 0;
}


{
  # eccentricities palindromic
  # n=7 https://hog.grinvin.org/ViewGraphInfo.action?id=934
  #
  # 1--2--3--4--5--6        arms 1,2,3
  #       |
  #       7

  my @graphs;
  my $graph = MyGraphs::Graph_from_vpar
    ([undef, 0, 1, 2, 3, 4, 5, 4]);  # n=7
  push @graphs, $graph;

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Dog's Bone k=1 STF equivalents n=10 vertices, smallest pair of
  # non-isomorphics.
  # T1 https://hog.grinvin.org/ViewGraphInfo.action?id=31072
  # T2 https://hog.grinvin.org/ViewGraphInfo.action?id=31074
  #
  # Denes Bartha, Peter Burcsi, "Reconstructibility of Trees From Subtree
  # Size Frequencies", Studia Universitatis Babe-Bolyai Mathematica, volume
  # 59, number 4, 2014, pages 435-442
  # http://www.cs.ubbcluj.ro/~studia-m/2014-4/Cuprins2014_4.htm
  # http://www.cs.ubbcluj.ro/~studia-m/2014-4/03-bartha-burcsi-final.pdf
  #
  my @graphs = (MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 1, 1, 4, 5, 2, 2, 8, 9], undirected=>1),
                MyGraphs::Graph_from_vpar
                ([undef, 0, 1, 1, 1, 2, 5, 2, 7, 8, 9], undirected=>1));
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # KE example for Independence Decomposition Theorem
  # C. E. Larson, "The Independence Number Project: Introduction"
  # HOG not

  # exists set X
  # indnum(G) = indnum(X) + indnum(Xcomp)
  # G(X) is KE
  # G(Xcomp) indep sets all have NumNeighbours(I) > Size(I)
  # G maximum critical independent sets J all X = Jcomp union Neighbours(Jcomp)
  #
  # a,b degree=2s are a maximum critical independent set
  # X = a,b,c,d
  # Xcomp = e,f,g
  # G(X)=KE

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  $graph->add_cycle('0,0', '1,-1', '2,.5', '1,2', '0,1');
  $graph->add_cycle('0,0', '2,.5', '0,1', '1,-1', '1,2');
  $graph->add_cycle('0,0', '-1,1', '0,1', '-1,0');

  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}





{
  # Lowenstein, no disjoint minimum dominating sets though no one vertex
  # common to all

  # Christian Lowenstein, "In the Complement of a Dominating Set",
  # dissertation, April 2010.
  # https://www.db-thueringen.de/servlets/MCRFileNodeServlet/dbt_derivate_00021011/ilm1-2010000233.pdf

  my @graphs;
  my $graph = MyGraphs::Graph_from_vpar
    ([undef, 0,3,4,1,4,5,6,9,10,1,10,11,12,15,16,1,16,17,18]);
  push @graphs, $graph;

  $graph = MyGraphs::Graph_from_vpar
    ([undef, 2,3,4,5,0,5,6,7,8,6,10,5,12,13,4,15]);
  push @graphs, $graph;

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Lowenstein, minimum dominating set complement no independent dominating set
  #
  #   2         7
  #  / \       / \
  # 1   3--5--6   8
  #  \ /       \ /
  #   4         9
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30679
  #
  # Christian Lowenstein, "In the Complement of a Dominating Set",
  # dissertation, April 2010.
  # https://www.db-thueringen.de/servlets/MCRFileNodeServlet/dbt_derivate_00021011/ilm1-2010000233.pdf

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(1,2,3,4);
  $graph->add_cycle(6,7,8,9);
  $graph->add_path(3,5,6);

  require Algorithm::ChooseSubsets;
  my $count = 0;
  my @vertices = sort $graph->vertices;
  my $it = Algorithm::ChooseSubsets->new(\@vertices);
  while (my $aref = $it->next) {
    if (MyGraphs::Graph_is_domset($graph,$aref) && scalar(@$aref)==3) {
      print join(',',@$aref),"\n";
    }
  }

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # disjoint domination number attained in the most ways
  MyGraphs::hog_searches_html
      ('>>sparse6<<:@',
       '>>sparse6<<:An',
       '>>sparse6<<:Bc',
       '>>sparse6<<:Cdf',
       '>>sparse6<<:DaXb',
       '>>sparse6<<:EaWmN',
       '>>sparse6<<:FaYbL',
       '>>sparse6<<:GaYeLb',
       '>>sparse6<<:GaWmLb',
       '>>sparse6<<:H`ESYOl^',
       '>>sparse6<<:I`ESYP`]F',
       '>>sparse6<<:I`ESWTlUF',
       '>>sparse6<<:I`ECwT`]F',
       '>>sparse6<<:J`ESYOl]u^',
       '>>sparse6<<:K`ESgt`^D|^',
       '>>sparse6<<:L`ESYPlBE[Z',
       '>>sparse6<<:M`ESgtb]E\Xx',
       '>>sparse6<<:M`ESgt`^D|Vx',
       '>>sparse6<<:N`ESYPlBE[Zpv',
       '>>sparse6<<:O`ESyRlFCLZxBv',
       '>>sparse6<<:P_`a`c`e`g_ijilin',
       '>>sparse6<<:Q_`abcbe`g_ijkjm_o',
       '>>sparse6<<:R_`a`c`e`g_ijilinip',
       '>>sparse6<<:S_`abcbe`g_ijklknip_',
       '>>sparse6<<:T_`a`c`e`g`i_klknkpkr',
       '>>sparse6<<:U_`abcbe`g`i_klmlo_q_s',
       '>>sparse6<<:V_`a`c`e`g`i_klknkpkrkt',
       '>>sparse6<<:W_`abcbebg`i`k_mnonq_s_u',
       '>>sparse6<<:X_`abcbe`g_ijklknip_rstsv',
       '>>sparse6<<:YiHgfedcba`_uTRQPsONMtLKwSJI',
      );
  exit 0;
}

{
  # square and diamond stack
  #
  # 1 cycle
  #
  # 2 graphedron
  # https://hog.grinvin.org/ViewGraphInfo.action?id=160

  require Graph;
  my $graph = Graph->new (undirected => 1);
  my $width = 4;
  my @graphs;
  foreach my $i (0 .. 3) {
    $graph->add_cycle($i*$width .. ($i+1)*$width-1);
    if ($i) {
      foreach my $j (0 .. $width-1) {
        $graph->add_edge(($i-1)*$width+$j, $i*$width+$j);
        $graph->add_edge(($i-1)*$width+$j, $i*$width+(($j+1)%$width));
      }
    }
    push @graphs, $graph->copy;
  }
  MyGraphs::Graph_view($graphs[2]);
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Asymmetric Trees Subgraph Relations
  #
  # n<=10
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30651
  #
  # n<=11
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30653

  my @strs = qw(
                 FhQ?G
                 GhQ?GC
                 HhCc?C@
                 HhDC?C@
                 HhQ?GE?
                 IhCaC?@?G
                 IhCc?C@?G
                 IhCc?C@_?
                 IhD?K?@?G
                 IhDC?C@?G
                 IhQ?GE??G
                 JhCGc?@?G?_
                 JhCHC?@?G?_
                 JhCIC?@?G?_
                 JhCa?E??G?_
                 JhCaC?@?G?_
                 JhCaC?@?GA?
                 JhCaC?@?K??
                 JhCc?C@?GC?
                 JhCc?C@?K??
                 JhCc?C@_??_
                 JhD?IA??G?_
                 JhD?K?@?G?_
                 JhD?K?@?K??
                 JhDC?C@?K??
                 JhQ?GE??K??
              );
  my $limit = 11;
  my @graphs = map {MyGraphs::Graph_from_graph6_str($_)} @strs;
  require Graph;
  my $graph = Graph->new (undirected => 0);
  foreach my $i (0 .. $#graphs) {
    next if $graphs[$i]->vertices > $limit;
    foreach my $j (0 .. $#graphs) {
      next if $i == $j;
      next if $graphs[$j]->vertices > $limit;
      next if abs(scalar($graphs[$i]->vertices) - scalar($graphs[$j]->vertices)) != 1;
      if (MyGraphs::Graph_is_subgraph($graphs[$i],$graphs[$j])) {
        $graph->add_edge($i,$j);
      }
    }
  }
  MyGraphs::Graph_print_tikz($graph);
  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # n=7 asymmetric tree
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_path(0,1);
  $graph->add_path(0,2,3);
  $graph->add_path(0,4,5,6);
  my $canon_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print $canon_g6;
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # distance palindromic tree
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30646

  # distance distribution d[1],...,d[diam] with d[i] = number of pairs of
  # vertices at distance i apart

  # Caporossi, Dobrynin, Gutman, Hansen, "Trees with Palindromic Hosoya
  # Polynomials", Graph Theory Notes of New York, volume 37, 1999, pages
  # 10-16.

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_path(1,2,3,4,5,6,7);
  $graph->add_path(8,1);
  $graph->add_path(9,1);
  $graph->add_path(10,11,2);
  $graph->add_path(12,3);
  $graph->add_path(13,14,15,5);
  $graph->add_path(16,14);
  $graph->add_path(17,7);
  $graph->add_path(18,7);
  $graph->add_path(19,7);
  $graph->add_path(20,7);
  $graph->add_path(21,7);
  print MyGraphs::Graph_Wiener_index($graph),"\n";
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # Ramsey 3,5 and 4,4 Bondy and Murty

  # 3,5
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=21065
  #   Vertex-transitive 4-vertex-critical P7-free graph.
  #   13-Cyclotomic Graph.
  # 4,4
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=30395
  #
  require Graph;
  my @graphs;
  {
    my $n = 13;
    my $graph = Graph->new (undirected => 1);
    $graph->add_cycle(0 .. $n-1);
    foreach my $i (0 .. $n-1) {
      foreach my $delta (1,5,8,12) {   # cubic residues mod 13
        $graph->add_edge($i, ($i+$delta)%$n);
      }
    }
    my ($indnum, $count) = MyGraphs::Graph_indnum_and_count($graph);
    print "N=$n indnum $indnum count $count\n";
    push @graphs, $graph;
  }
  {
    my $n = 17;
    my $graph = Graph->new (undirected => 1);
    $graph->add_cycle(0 .. $n-1);
    foreach my $i (0 .. $n-1) {
      foreach my $delta (1,2,4,8,9,13,15,16) {   # quadratic residues mod 17
        $graph->add_edge($i, ($i+$delta)%$n);
      }
    }
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}


{
  # Mobius Ladder 8 with 2 non-consecutive rungs deleted
  require Graph::Maker::Ladder;
  my $graph = Graph::Maker->new('ladder', undirected => 1, rungs=>4);
  $graph->add_edge(1,8);   # ends 1,5 and 4,8, cross wired
  $graph->add_edge(5,4);
  $graph->delete_edge(1,5);
  $graph->delete_edge(3,7);

  my ($indnum, $count) = MyGraphs::Graph_indnum_and_count($graph);
  print "indnum $indnum count $count\n";

  MyGraphs::hog_searches_html($graph);
  # MyGraphs::Graph_print_tikz($graph);
  exit 0;
}

{
  # Mobius Ladder 8 with 2 consecutive rungs deleted
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30360
  require Graph::Maker::Ladder;
  my $graph = Graph::Maker->new('ladder', undirected => 1, rungs=>4);
  $graph->add_edge(1,8);   # ends 1,5 and 4,8, cross wired
  $graph->add_edge(5,4);
  $graph->delete_edge(1,5);
  $graph->delete_edge(2,6);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}


{
  # Ramsey 4,3
  # GQyurg = G}hPW{
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=160
  #   graphedron
  #   complement GsOiho 3,4 three Mobius, Bondy+Murty
  # GQyurw = GrotY{
  #   complement G@hZCc two Jan
  # GQyuzw = G`zTzw
  #   complement G`_gqK Petersen 4,2
  #
  my @strings = ('GQyurg',
                 'GQyurw',
                 'GQyuzw');
  my @graphs;
  foreach my $g6_str (@strings) {
    my $canon_g6 = MyGraphs::graph6_str_to_canonical($g6_str);
    my $hog = MyGraphs::hog_grep($canon_g6)?"HOG":"not";
    print "4,3        $hog  $canon_g6";
    # MyGraphs::graph6_view($g6_str);

    my $graph = MyGraphs::Graph_from_graph6_str($g6_str);
    push @graphs, $graph;
    # MyGraphs::Graph_print_tikz($graph);
    $graph = $graph->complement;

    $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    $hog = MyGraphs::hog_grep($canon_g6)?"HOG":"not";
    print "complement $hog  $canon_g6";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Ramsey 3,4
  # https://hog.grinvin.org/ViewGraphInfo.action?id=588
  #   graphedron, Petersen 4,2
  # https://hog.grinvin.org/ViewGraphInfo.action?id=26996
  #   Jan Goedgebeur, Obstruction for t-perfectness.
  # https://hog.grinvin.org/ViewGraphInfo.action?id=640
  #   Mobius Ladder 8
  my @graphs = ('GCQb`o',     # G`_gqK
                'GCR`r_',     # G@hZCc
                'GCrb`o');    # GsOiho
  foreach my $g6_str (@graphs) {
    my $canon_g6 = MyGraphs::graph6_str_to_canonical($g6_str);
    my $hog = MyGraphs::hog_grep($canon_g6)?"HOG":"not";
    print "$hog  $canon_g6";
    # MyGraphs::graph6_view($g6_str);
    # my $graph = MyGraphs::Graph_from_graph6_str($g6_str);
    # MyGraphs::Graph_print_tikz($graph);
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Ramsey 3,4 - Bondy and Murty
  # GsOiho
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(0,1,2,3,4,5,6,7);
  $graph->add_edge(0,4);
  $graph->add_edge(1,5);
  $graph->add_edge(2,6);
  $graph->add_edge(3,7);
  my $canon_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  my $hog = MyGraphs::hog_grep($canon_g6)?"HOG":"not";
  print "$hog  $canon_g6";
  exit 0;
}


{
  # genrang tree distribution
  require IPC::Run;
  my $h = IPC::Run::start
    (['sh','-c','nauty-genrang 5 1000000 | nauty-labelg'], #
     '>pipe',\*OUT);
  my %hash;
  while (defined (my $str = <OUT>)) {
    $hash{$str}++;
  }
  foreach my $str (sort {$hash{$a} <=> $hash{$b}} keys %hash) {
    my $count = $hash{$str};
    my $graph = MyGraphs::Graph_from_graph6_str($str);
    my $diameter = $graph->diameter || 0;
    print "$count diam=$diameter  $str";
  }
  # ### %hash
  print "distinct ",scalar(keys %hash),"\n";
  exit 0;
}

{
  # dodecahedron, HOG
  # 5-cycle and leaves, HOG
  # 6 pentagons, not
  #
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(1,2,3,4,5);
  $graph->add_edge(1,6);
  $graph->add_edge(2,7);
  $graph->add_edge(3,8);
  $graph->add_edge(4,9);
  $graph->add_edge(5,10);
  $graph->add_cycle(6,11,7,12,8,13,9,14,10,15);
  $graph->add_edge(11,16);
  $graph->add_edge(12,17);
  $graph->add_edge(13,18);
  $graph->add_edge(14,19);
  $graph->add_edge(15,20);
  $graph->add_cycle(16,17,18,19,20);
  my @names = (undef,
               '0,1', '1,0', '1,-1', '-1,-1', '-1,0',
               '0,2', '2,0', '1,-2', '-1,-2', '-2,0',
               '2,2', '2,-2', '0,-3', '-2,-2', '-2,2',
               '3,3', '3,-3', '0,-4', '-3,-3', '-3,3',
              );
  foreach my $i (1 .. $#names) {
    MyGraphs::Graph_rename_vertex($graph,$i,$names[$i]);
  }
  $graph->set_graph_attribute (vertex_name_type_xy => 1);

  my $canon_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  my $hog = MyGraphs::hog_grep($canon_g6)?"HOG":"not";
  print "$hog  $canon_g6\n";
  MyGraphs::Graph_view($graph);
  exit 0;
}

{
  # n=8 line graphs with pseudosimilar vertices
  # subgraphs
  #
  #   9-->
  #       12 --> 17
  #  10-->
  #
  #  9 https://hog.grinvin.org/ViewGraphInfo.action?id=30306
  # 10 https://hog.grinvin.org/ViewGraphInfo.action?id=30339
  # 12 https://hog.grinvin.org/ViewGraphInfo.action?id=30337
  # 17 https://hog.grinvin.org/ViewGraphInfo.action?id=30335

  my @graphs = map { MyGraphs::Graph_from_graph6_str($_) }
    'GCQREO',  # edges= 9
    'GCQbUG',  #       10
    'GCpddW',  #       12
    'GEhtr{',  #       17
    ;
  foreach my $graph (@graphs) {
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;

    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6)?"HOG":"not";

    print "$num_vertices vertices, $num_edges edges  $hog\n";
    foreach my $g2 (@graphs) {
      next if $graph eq $g2;
      my $map = MyGraphs::Graph_is_subgraph($graph, $g2);
      if ($map) {
        my $num_edges2 = $g2->edges;
        print "  subgraph $num_edges2 -- $map\n";
      }
    }
    # MyGraphs::Graph_view($graph);
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # n=8 line graphs with pseudosimilar vertices
  # GCQbUG
  #   linegraph 1
  # GCQREO
  #   linegraph 1
  # GCpddW
  #   linegraph 1
  # GEhtr{
  #   linegraph 1

  foreach my $g6_str ('GCQbUG',
                      'GCQREO',
                      'GCpddW',
                      'GEhtr{') {
    MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($g6_str));
  }
  exit 0;
}
{
  # n=8 graphs with pseudosimilar vertices, num edges
  my @graphs = ('G?`ebS',
                'G?q`to',
                'G?qcyw',
                'G?otRK',
                'GCOedK',
                'GCQeVK',
                'GCQbUG',
                'GCQeNO',
                'GCQevK',
                'GCQREO',
                'GCRcro',
                'GCRcz{',
                'GCRVFK',
                'GCpddW',
                'GCpbdg',
                'GCpdmg',
                'GCpdnS',
                'GCrbUk',
                'GCrfVk',
                'GCrVNW',
                'GCrJ`s',
                'GCZffo',
                'GCZetw',
                'GCZej{',
                'GCZbmw',
                'GCZVFo',
                'GCZVVG',
                'GCZJeo',
                'GCZJfG',
                'GCZLno',
                'GCXmeo',
                'GCdebW',
                'GCze~w',
                'GCxvfo',
                'GCvfR{',
                'GEjev[',
                'GEjbvg',
                'GEjdno',
                'GEhvC{',
                'GEhtr{',
                'GEhrvW',
                'GEh}t{',
                'GEzfvw',
                'GEnffw',
               );
  @graphs = map { MyGraphs::Graph_from_graph6_str($_) } @graphs;
  @graphs = sort {scalar($a->edges) <=> scalar($b->edges)} @graphs;
  foreach my $graph (@graphs) {
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;

    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6)?"HOG":"not";

    print "$num_vertices vertices, $num_edges edges  $hog\n";
  }
  exit 0;
}



{
  # regular not maximum median
  # GCZJd_
  # GCXmd_

  foreach my $g6_str ('GCZJd_',  # n=8
                      'GCXmd_',
                      'HCOethk',   # n=9 irregular but median full
                     ) {
    # MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($g6_str));
    my $can = MyGraphs::graph6_str_to_canonical($g6_str);
    print MyGraphs::hog_grep($can)?"HOG":"not", "\n";
  }
  exit 0;
}
{
  # n=8 graphs with pseudosimilar vertices, structure of subtree relations
  my @graphs = ('G?`ebS',
                'G?q`to',
                'G?qcyw',
                'G?otRK',
                'GCOedK',
                'GCQeVK',
                'GCQbUG',
                'GCQeNO',
                'GCQevK',
                'GCQREO',
                'GCRcro',
                'GCRcz{',
                'GCRVFK',
                'GCpddW',
                'GCpbdg',
                'GCpdmg',
                'GCpdnS',
                'GCrbUk',
                'GCrfVk',
                'GCrVNW',
                'GCrJ`s',
                'GCZffo',
                'GCZetw',
                'GCZej{',
                'GCZbmw',
                'GCZVFo',
                'GCZVVG',
                'GCZJeo',
                'GCZJfG',
                'GCZLno',
                'GCXmeo',
                'GCdebW',
                'GCze~w',
                'GCxvfo',
                'GCvfR{',
                'GEjev[',
                'GEjbvg',
                'GEjdno',
                'GEhvC{',
                'GEhtr{',
                'GEhrvW',
                'GEh}t{',
                'GEzfvw',
                'GEnffw',
               );
  @graphs = map { MyGraphs::Graph_from_graph6_str($_) } @graphs;
  @graphs = sort {scalar($a->edges) <=> scalar($b->edges)} @graphs;
  my $graph = Graph->new;
  $graph->set_graph_attribute (flow => 'south');

  my $a = ord('a');
  my @copy;
  my @names = map {
    my $num_edges = $_->edges;
    my $c = $a + $copy[$num_edges]++;
    # $num_edges . chr($c)
    $c *= 3;
    "$c,$num_edges"
  } @graphs;
  $graph->set_graph_attribute (vertex_name_type_xy => 1);

  foreach my $d (1 .. 15) {
    my $count = 0;
    print "d=$d\n";
    foreach my $i (0 .. $#graphs) {
      my $i_num_edges = $graphs[$i]->edges;
      # print "i=$i  $i_num_edges\n";
      foreach my $j ($i+1 .. $#graphs) {
        my $j_num_edges = $graphs[$j]->edges;
        my $got_d = $j_num_edges - $i_num_edges;
        ### $got_d
        next if $got_d != $d;

        if ($d >= 2) {
          my $path_length = $graph->path_length($names[$i],$names[$j]);
          ### $path_length
          next if defined $path_length;
        }
        next unless MyGraphs::Graph_is_subgraph($graphs[$j], $graphs[$i]);
        $graph->add_edge($names[$j],$names[$i]);
        $count++;
      }
    }
    print "  count $count\n";
  }
  MyGraphs::Graph_view($graph);
  MyGraphs::Graph_print_tikz($graph);
  exit 0;
}

{
  require Graph;
  my @graphs;
  for (my $n=4; $n <= 20; $n+=2) {
    my $graph = Graph->new (undirected=>1);
    foreach my $v (2 .. $n-1) {
      $graph->add_edge(1,$v);
    }
    $graph->add_edge(2,$n);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # identity graphs, asymmetric
  MyGraphs::hog_searches_html
      (# 5-cycle and leaf, 7 edges
       'ECro',

       # diamond and 2 leaves, 7 edges
       'ECrg',

       # triangle, leaf, path-2, 6 edges
       'ECZG',

       # diamond, triangle, leaf, 8 edges
       'ECzW',

       # square, triangle, leaf, 7 edges
       # https://hog.grinvin.org/ViewGraphInfo.action?id=25152
       'EEhW',

       # diamond and square, 8 edges
       'EEjo',

       # 3 triangles and leaf, 8 edges
       'EEjW',

       # 3 triangles and square, 9 edges
       'EEno',
      );
  exit 0;
}

{
  my $want = "GEhtr{\n";
  $want = MyGraphs::graph6_str_to_canonical($want);
  print MyGraphs::hog_grep($want)?"HOG":"not", "\n";
  my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
    (num_vertices_min => 1,
     num_vertices_max => 9,
     connected => 1,
    );
  while (my $edge_aref = $iterator_func->()) {
    my $graph = MyGraphs::Graph_from_edge_aref($edge_aref);
    my $linegraph = MyGraphs::Graph_line_graph($graph);
    my $got = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($linegraph));
    if ($got eq $want) {
      my $graph_g6 = MyGraphs::graph6_str_to_canonical
        (MyGraphs::Graph_to_graph6_str($graph));
      print MyGraphs::hog_grep($graph_g6)?"HOG":"not", "\n";
      # MyGraphs::Graph_print_tikz($graph);
      # MyGraphs::Graph_view($graph);
      exit;
    }
  }
  exit 0;
}

{
  # Harary and Palmer two triangles
  #
  #    2       3
  #   / \     / \
  #  1---5---6---7---4---0
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30306
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30308  removal

  my $graph = Graph->new (undirected=>1);
  print "is linegraph ",MyGraphs::Graph_is_line_graph_by_Beineke($graph),"\n";

  $graph->add_cycle(1,2,5);
  $graph->add_path(5,6,7,4,0);
  $graph->add_path(6,3,7);
  my $u = 5;
  my $v = 7;
  my $gu = $graph->copy;
  my $gv = $graph->copy;
  $gu->delete_vertex($u);
  $gv->delete_vertex($v);
  print "isomorphic ",MyGraphs::Graph_is_isomorphic($gu,$gv),"\n";
  MyGraphs::Graph_view($gu);
  MyGraphs::Graph_view($gv);

  MyGraphs::hog_searches_html($graph, $gu);
  exit 0;
}
{
  # hog_grep()
  my $graph = Graph->new (undirected=>1);
  $graph->add_path(0,1);
  my $g6_str = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";
  exit 0;
}

{
  # totdomnum max
  my @graphs = (
                # triangle with arms
                # https://hog.grinvin.org/ViewGraphInfo.action?id=28537
                '>>graph6<<G?`aeG',

                # tree
                '>>graph6<<G?`@f?',

                # tree
                '>>graph6<<G?B@dO',
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Harary and Palmer K4-e * 3 pseudosimilar

  # .  0   3---4   7
  # .  |   | / | / |
  # .  1---2---5---6
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30310

  my $graph = Graph->new (undirected=>1);
  $graph->add_path(0,1,2,3,4,5,6,7,5);
  $graph->add_path(4,2,5);
  my $u = 2;
  my $v = 5;
  MyGraphs::Graph_view($graph);

  my $gu = $graph->copy;
  my $gv = $graph->copy;
  $gu->delete_vertex($u);
  $gv->delete_vertex($v);
  print "isomorphic ",MyGraphs::Graph_is_isomorphic($gu,$gv),"\n";
  MyGraphs::Graph_view($gv);

  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # n=11 no duplicated leaf
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28553
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28555

  my $n = 11;
  my $formula = int((2*$n-1)/3);
  print "n=$n\n";
  print "formula $formula\n";

  my $iterator_func = MyGraphs::make_tree_iterator_edge_aref
    (num_vertices_min => $n,
     num_vertices_max => $n,
     connected => 1);
  my $count = 0;
  my @graphs;
  while (my $edge_aref = $iterator_func->()) {
    my $graph = MyGraphs::Graph_from_edge_aref($edge_aref, num_vertices => $n);
    next if Graph_has_duplicated_leaf($graph);
    my $indnum = MyGraphs::Graph_tree_indnum($graph);
    if ($indnum == $formula) {
      my $g6_str = MyGraphs::graph6_str_to_canonical
        (MyGraphs::Graph_to_graph6_str($graph));
      print "n=$n  ",MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";
      # MyGraphs::Graph_view($graph);
      # sleep 5;
      $count++;
      push @graphs, $graph;
    }
  }
  print "count $count\n";
  MyGraphs::hog_searches_html(@graphs);
  exit 0;

  sub Graph_has_duplicated_leaf {
    my ($graph) = @_;
    my %seen;
    foreach my $v ($graph->vertices) {
      if ($graph->vertex_degree($v) == 1) {
        my ($attachment) = $graph->neighbours($v);
        if ($seen{$attachment}++) {
          return 1;
        }
      }
    }
    return 0;
  }
}

{
  # Jou and Lin, "Independence Numbers in Trees", Open Journal of Discrete
  # Mathematics, volume 5, 2015, pages 27-31,
  # http://dx.doi.org/10.4236/ojdm.2015.53003

  # no duplicated leaf

  # GP-Test  my(k=4,n=3*k);   2*k-1 == 7 && n==12
  # GP-Test  my(k=4,n=3*k+1); 2*k   == 8 && n==13
  # GP-Test  my(k=4,n=3*k+2); 2*k+1 == 9 && n==14

  # n=15 indnum 9

  foreach my $n (# 12 .. 14,
                 11,
                ) {
    my $graph = make_extremal_nodupicated_leaf_indnum($n);
    MyGraphs::Graph_view($graph);
    my $indnum = MyGraphs::Graph_tree_indnum($graph);
    my $formula = int((2*$n-1)/3);
    print "n=$n  indnum $indnum formula $formula\n";
    $graph->vertices == $n or die;
  }
  exit 0;

  sub make_extremal_nodupicated_leaf_indnum {
    my ($n) = @_;
    my $graph = Graph->new (undirected=>1);
    $graph->set_graph_attribute (name => "n=$n");
    my $upto = 1;   # next prospective vertex number
    $graph->add_vertex($upto++);
    while ($upto <= $n) {
      ### $upto
      my $more = min(3, $n-$upto+1);
      $graph->add_path(1, $upto .. $upto+$more-1);
      $upto += $more;
    }
    return $graph;
  }
}



{
  # most indomsets

  # n=6   https://hog.grinvin.org/ViewGraphInfo.action?id=132
  # n=7   https://hog.grinvin.org/ViewGraphInfo.action?id=698
  # n=8   https://hog.grinvin.org/ViewGraphInfo.action?id=118
  # n=9   https://hog.grinvin.org/ViewGraphInfo.action?id=28526
  # n=10  https://hog.grinvin.org/ViewGraphInfo.action?id=658
  my @graphs;
  foreach my $n (6 .. 20) {
    my $graph = MyGraphs::Graph_make_most_indomsets($n);
    my $g6_str = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    print "n=$n  ",MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # most maximum independent sets
  # https://hog.grinvin.org/ViewGraphInfo.action?id=496

  MyGraphs::hog_searches_html('>>graph6<<DQw',  # n=5
                              '>>graph6<<DUW',  # n=5 cycle
                              '>>graph6<<EQjO',  # n=6
                              '>>graph6<<FQhVO',  # n=7
                              '>>graph6<<GQhTUg',  # n=8
                              '>>graph6<<HCOcaRc',  # n=9
                             );
  exit 0;
}
{
  print MyGraphs::hog_grep("E?CW\n");
  exit 0;
}


{
  # path-4 plus middle leaf
  # https://hog.grinvin.org/ViewGraphInfo.action?id=496

  require Graph::Maker::Linear;
  my $graph = Graph::Maker->new('linear', N=>5, undirected=>1);
  $graph->add_edge(3,6);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # 5-cycle
  # https://hog.grinvin.org/ViewGraphInfo.action?id=340

  require Graph::Maker::Cycle;
  my $graph = Graph::Maker->new('cycle', N=>5, undirected=>1);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # bicentral and bicentroidal  disjoint

  # https://hog.grinvin.org/ViewGraphInfo.action?id=28234
  # 3  2
  #   \|
  # 4--1--7--8--9--10--11--12
  #   /|
  # 5  6

  require Graph::Maker::Star;
  my $graph = Graph::Maker->new('star', N=>7, undirected=>1);
  $graph->add_path(7,8,9,10,11,12);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # centre and centroid disjoint

  my @graphs;
  {
    # https://hog.grinvin.org/ViewGraphInfo.action?id=792
    # file:///so/hog/graphs/792.html
    #             *
    #             |
    # *---*---C---G---*
    #             |
    #             *
    my $graph = Graph->new (undirected=>1);
    $graph->add_path(1,2,3,4,5);
    $graph->add_path(6,4,7);
    push @graphs, $graph;
  }
  {
    # https://hog.grinvin.org/ViewGraphInfo.action?id=28225
    #           *   *
    #            \ /
    # *---*---C---G---*
    #             |
    #             *
    my $graph = Graph->new (undirected=>1);
    $graph->add_path(1,2,3,4,5);
    $graph->add_path(6,4,7);
    $graph->add_path(4,8);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # n=8 cyclic domnum=4
  #
  # triangle with 3x1 and 1x2 hanging
  # hog not
  #    *---*---*---*
  #        | \
  #    *---*---*---*
  #
  # square with extra vertex each
  # https://hog.grinvin.org/ViewGraphInfo.action?id=48
  # file:///so/hog/graphs/48.html
  #    *---*---*---*
  #        |   |
  #    *---*---*---*
  #
  # square with cross edge and extra vertex each
  # hog not
  #    *---*---*---*
  #        | / |
  #    *---*---*---*
  #
  # tetrahedral (complete-4) with extra vertex each
  # https://hog.grinvin.org/ViewGraphInfo.action?id=228
  # file:///so/hog/graphs/228.html
  #    *---*---*---*
  #        | X |
  #    *---*---*---*

  my @graphs;
  foreach my $g6 ('>>graph6<<G?`DEc',
                  '>>graph6<<G?`FE_',
                  '>>graph6<<G?`FEc',
                  '>>graph6<<G?bDKk',
                 ) {
    push @graphs, $g6;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # maximum induced claws

  # star-7
  # https://hog.grinvin.org/ViewGraphInfo.action?id=622
  #
  # bipartite 5,2
  # https://hog.grinvin.org/ViewGraphInfo.action?id=866

  # bipartite 5,2 with edge between 2
  # https://hog.grinvin.org/ViewGraphInfo.action?id=580

  my @graphs;
  foreach my $g6 ('>>graph6<<F??Fw',  # star-7
                  '>>graph6<<F?B~o',  # bipartite 5,2
                  '>>graph6<<F?B~w',  # bipartite 5,2 with edge between 2
                 ) {
    push @graphs, $g6;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # bipartite claw count

  # star-n < complete bipartite n-2,2 for n>=8

  # complete n,3
  # star_claws(n) = binomial(n-1,3);  \\ (n-1)(n-2)(n-3)/6
  # complete_bipartite_claws(n,m) = n*binomial(m,3) + m*binomial(n,3);
  # complete_bipartite_claws(0,3)
  # vector(10,n, star_claws(n))
  # vector(10,n, (n-1)*(n-2)*(n-3)/6)
  # vector(10,n, complete_bipartite_claws(n-1,1))
  # vector(10,n, complete_bipartite_claws(n-2,2))
  # vector(10,n, (n-2)*(n-3)*(n-4)/3)
  # vector(10,n, complete_bipartite_claws(floor(n/2),ceil(n/2)))

  # vector(10,n, (n-2)*(n-3)*(n-4)/3) - vector(10,n, (n-1)*(n-2)*(n-3)/6)
  # vector(10,n, (n-2)*(n-3)*(n-7)/6)
  # my(n=7); (n-2)*(n-3)*(n-7)/6
  # my(n=8); (n-2)*(n-3)*(n-7)/6

  # read("vpar.gp");
  # matrix(5,5,n,m,n++;m++; vpar_claw_count(vpar_make_bistar(n,m)))

  require Graph::Maker::CompleteBipartite;
  foreach my $n (2 .. 8) {
    foreach my $m (2 .. 8) {
      my $graph = Graph::Maker->new('complete_bipartite', N1 => $n, N2 => $m,
                                    undirected => 1);
      # if ($n == $m && $n == 4) {
      #   MyGraphs::Graph_view($graph);
      # }
      printf "%4d", MyGraphs::Graph_claw_count($graph);
    }
    print "\n";
  }

  foreach my $n (2 .. 6) {
    foreach my $m (2 .. 6) {
      my $graph = Graph::Maker->new('complete_bipartite', N1 => $n, N2 => $m,
                                    undirected => 1);
      my $count = $n*binomial($m,3) + $m*binomial($n,3);
      printf "%4d", $count;
    }
    print "\n";
  }
  print "\n";

  foreach my $n (2 .. 6) {
    foreach my $m (2 .. 6) {
      my $count = binomial($n+$m,3);
      printf "%4d", $count;
    }
    print "\n";
  }
  exit 0;

  # seq1 => [($m)x$n],
  # seq2 => [($n)x$m],

  sub binomial {
    my ($n, $m) = @_;
    my $ret = 1;
    foreach my $i ($n-$m+1 .. $n) {
      $ret *= $i;
    }
    foreach my $i (1 .. $m) {
      $ret /= $i;
    }
    return $ret;
  }
}

{
  # claw-free graphs
  require Graph;
  require Graph::Writer::Sparse6;
  foreach my $num_vertices (5) {

    my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
      (num_vertices_min => $num_vertices,
       num_vertices_max => $num_vertices,
       connected => 1,
      );
    my @graphs;
    while (my $edge_aref = $iterator_func->()) {
      my $graph = MyGraphs::Graph_from_edge_aref($edge_aref,
                                                 num_vertices => $num_vertices);
      my $has_claw = MyGraphs::Graph_has_claw($graph);
      if ($has_claw) {
        Graph::Writer::Sparse6->new->write_graph($graph,\*STDOUT);
        MyGraphs::Graph_view($graph);
      } else {
        push @graphs, $graph;
      }
    }
    my $num_graphs = scalar(@graphs);
    print "N=$num_vertices [$num_graphs] ";
  }
  exit 0;
}
{
  # cycle maximal independent sets

  require Graph::Maker::Cycle;
  require MyGraphs;
  my @values;
  foreach my $n (3 .. 10) {
    my $graph = Graph::Maker->new('cycle', N => $n, undirected => 1);
    MyGraphs::Graph_view($graph);
    # my $count = MyGraphs::Graph_tree_maximal_indsets_count($graph);
    # push @values, $count;
  }
  # require Math::OEIS::Grep;
  # Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}

{
  #     *---*
  #     |   |
  # *---*---*---*
  #     |   |
  #     *   *
  # hog not

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle (1,2,3,4);
  $graph->add_edge('1a',1);
  $graph->add_edge('1b',1);
  $graph->add_edge('2a',2);
  $graph->add_edge('2b',2);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # T1
  # hog not
  require Graph;
  my $graph = Graph->new (undirected => 1);
  foreach my $side ('L','R') {
    foreach my $i (1 .. 6) {
      $graph->add_path ("${side}t$i","${side}s$i",$side);
    }
  }
  $graph->add_path ('L','T','R');
  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # subgraph relations among all graphs to N vertices -- graph drawing
  #
  # N=4
  #   all graphs          = mucho edges  [hog not]
  #     complement = some disconnecteds
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=26965
  #   all graphs, delta 1 = diam 6
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=26963
  #   connected graphs    = complete-6 less 3 edges (in a path)
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=748
  #   connected, delta 1  = square plus 2  "A Graph"
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=945
  #     http://mathworld.wolfram.com/AGraph.html
  # N=3
  #   all graphs          = complete-4
  #   all graphs, delta 1 = path-4
  #   connected graphs    = path-2

  my $num_vertices = 4;
  my $connected = 0;
  my $delta1 = 0;
  my $complement = 1;

  require Graph;
  my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
    (num_vertices_min => $num_vertices,
     num_vertices_max => $num_vertices,
     connected => $connected,
    );
  my @graphs;
  while (my $edge_aref = $iterator_func->()) {
    ### graph: edge_aref_string($edge_aref)
    push @graphs, Graph_from_edge_aref($edge_aref,
                                       num_vertices => $num_vertices);
  }
  print "total ",scalar(@graphs)," graphs\n";
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute
    (name => "Subgraph Relations N=$num_vertices, "
     . ($connected ? ' Connected' : 'All'));
  foreach my $i (0 .. $#graphs) {
    my $n = $graphs[$i]->vertices;
    my $c = $graphs[$i]->is_connected ? 'C' : 'nc';
    my $s = "$graphs[$i]";
    print "$i [v=$n $s] subgraphs: ";
    foreach my $j (0 .. $#graphs) {
      next if $i==$j;
      if ($delta1
          && abs(scalar($graphs[$i]->edges)
                 - scalar($graphs[$j]->edges)) > 1) {
        next;
      }
      if (Graph_is_subgraph($graphs[$i], $graphs[$j])) {
        print "$j, ";
        $graph->add_edge($i, $j);
      }
    }
    print "\n";
  }

  my @named;
  require Graph::Maker::Star;
  push @named, [$num_vertices==4 ? 'claw' : 'star',
                Graph::Maker->new('star', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Linear;
  push @named, ['path',
                Graph::Maker->new('linear', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Complete;
  push @named, ['complete',
                Graph::Maker->new('complete', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Disconnected;
  push @named, ['disconnected',
                Graph::Maker->new('disconnected',
                                  N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Cycle;
  push @named, ['cycle',
                Graph::Maker->new('cycle', N=>$num_vertices, undirected=>1)];
  {
    my $g = Graph::Maker->new('cycle', N=>$num_vertices, undirected=>1);
    $g->add_edge(1,int(($num_vertices+2)/2));
    push @named, ['cycle across',$g];
  }
  if ($num_vertices >= 4) {
    my $n = $num_vertices-1;
    my $g = Graph::Maker->new('cycle', N=>$n, undirected=>1);
    $g->add_edge(1,$num_vertices);
    push @named, ["cycle$n hanging",$g];
  }
  if ($num_vertices >= 4) {
    my $n = $num_vertices-1;
    my $g = Graph::Maker->new('cycle', N=>$n, undirected=>1);
    $g->add_vertex($num_vertices);
    push @named, ["cycle$n disc",$g];
  }
  foreach my $i (1 .. $num_vertices-1) {
    my $g = Graph::Maker->new('linear', N=>$i, undirected=>1);
    $g->add_vertices(1 .. $num_vertices);
    push @named, ["p-$i",$g];
  }
  if ($num_vertices >= 4) {
    my $g = Graph->new(undirected=>1);
    $g->add_vertices(1 .. $num_vertices);
    $g->add_edge(1,2);
    $g->add_edge(3,4);
    push @named, ["2-sep",$g];
  }
  foreach my $i (0 .. $#graphs) {
    foreach my $elem (@named) {
      if (Graph_is_isomorphic($graphs[$i],$elem->[1])) {
        print "$i = $elem->[0]\n";
        Graph_rename_vertex($graph, $i, $elem->[0]);
        last;
      }
    }
  }

  print "graph ",scalar($graph->edges)," edges ",
    scalar($graph->vertices), " vertices\n";

  if ($complement) {
    print "complement\n";
    $graph = complement($graph);
    print "graph ",scalar($graph->edges)," edges ",
      scalar($graph->vertices), " vertices\n";
    $graph->set_graph_attribute
      (name => $graph->get_graph_attribute('name') . ', Complement');
  }

  Graph_view($graph);
  Graph_print_tikz($graph);
  hog_searches_html($graph);
  exit 0;

  sub complement {
    my ($graph) = @_;
    my @vertices = $graph->vertices;
    $graph = $graph->complement;
    $graph->add_vertices(@vertices);
    return $graph;
  }
}

{
  # subgraph relations among graphs to N vertices -- counts
  #
  # all graphs:
  #   count
  #     0,1,6,46,409,6945
  #   count delta1
  #     0,1,3,14,74,571
  #     A245246 Number of ways to delete an edge (up to the outcome) in the simple unlabeled graphs on n nodes.
  #     A245246 ,0,1,3,14,74,571,6558,125066,4147388,
  #   non count
  #     0,0,0,9,152
  #   non count, both ways
  #     0,1,6,64,713
  #   total count, n*(n-1)/2 of A000088 num graphs 1,1,2,4,11,34,156,
  #     0,1,6,55,561
  #     apply(n->n*(n-1)/2, [1,1,2,4,11,34,156])==[0,0,1,6,55,561,12090]
  #
  # connected graphs:
  #   count         0,0,1,12,143,3244
  #   count_delta1  0,0,1,6,42,401
  #   non_count     0,0,0,3,67,2972
  #   total_count   0,0,1,15,210,6216
  #     total count, n*(n-1)/2 of A001349 num conn graphs 1,1,1,2,6,21,112,853,
  #   apply(n->n*(n-1)/2,[1,1,1,2,6,21,112,853])==[0,0,0,1,15,210,6216,363378]

  require Graph;
  my @num_graphs;
  my @count;
  my @count_delta1;
  my @non_count;
  my @total_count;
  foreach my $num_vertices (1 .. 6) {

    my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
      (num_vertices_min => $num_vertices,
       num_vertices_max => $num_vertices,
       connected => 1,
      );
    my @graphs;
    while (my $edge_aref = $iterator_func->()) {
      ### graph: edge_aref_string($edge_aref)
      push @graphs, Graph_from_edge_aref($edge_aref,
                                         num_vertices => $num_vertices);
    }
    my $num_graphs = scalar(@graphs);
    push @num_graphs, $num_graphs;
    print "N=$num_vertices [$num_graphs] ";

    my $count = 0;
    my $count_delta1 = 0;
    my $non_count = 0;
    foreach my $i (0 .. $#graphs) {
      foreach my $j ($i+1 .. $#graphs) {

        if (Graph_is_subgraph($graphs[$i], $graphs[$j])
            || Graph_is_subgraph($graphs[$j], $graphs[$i])) {
          $count++;
          if (abs(scalar($graphs[$i]->edges) - scalar($graphs[$j]->edges)) <= 1) {
            $count_delta1++;
          }
        } else {
          $non_count++;
        }
      }
    }
    print " $count  $count_delta1\n";
    push @count, $count;
    push @count_delta1, $count_delta1;
    push @non_count, $non_count;
    push @total_count, $count + $non_count;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@num_graphs, verbose=>1, name=>'num_graphs');
  Math::OEIS::Grep->search(array => \@count, verbose=>1, name=>'count');
  Math::OEIS::Grep->search(array => \@count_delta1, verbose=>1, name=>'count_delta1');
  Math::OEIS::Grep->search(array => \@non_count, verbose=>1, name=>'non_count');
  Math::OEIS::Grep->search(array => \@total_count, verbose=>1, name=>'total_count');
  exit 0;
}
{
  # longest induced path by search

  # dragon blobs
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 3 cf v=4  [8 of] -2,1 -- -2,2 -- -3,2
  # longest 7 cf v=9  [4 of] -2,-1 -- -2,-2 -- -3,-2 -- -4,-2 -- -4,-1 -- -4,0 -- -5,0
  # longest 10 cf v=17  [4 of] -2,-6 -- -1,-6 -- -1,-5 -- -1,-4 -- -2,-4 -- -3,-4 -- -3,-5 -- -4,-5 -- -4,-4 -- -5,-4
  # longest 17 cf v=34  [32 of] ...
  # longest 31 cf v=68  [112 of] ...

  require Graph;
  my $graph = Graph->new (undirected=>1);
  $graph->add_cycle (0,1,2,3);
  $graph->add_path (2,4,5);

  # search_induced_paths($graph,
  #                      sub {
  #                        my ($path) = @_;
  #                        ### $path
  #                        # print "path: ", join(', ',@$aref), "\n";
  #                      });
  # show_longest_induced_path($graph);

  require Graph::Maker::Dragon;
  foreach my $k (0 .. 10) {
    print "------------------------------------------------\n";
    my $graph = Graph::Maker->new('dragon',
                                  level => $k,
                                  arms => 1,
                                  part => 'blob',
                                  undirected=>1);
    # Graph_view($graph);
    show_longest_induced_path($graph);
  }
  exit 0;

  sub show_longest_induced_path {
    my ($graph) = @_;
    my @longest_path;
    my $count = 0;
    search_induced_paths($graph,
                         sub {
                           my @path = @_;
                           if (@_ > @longest_path) {
                             @longest_path = @_;
                             $count = 1;
                           } elsif (@_ == @longest_path) {
                             $count++;
                           }
                         });
    my $num_vertices = scalar($graph->vertices);
    my $length = scalar(@longest_path);
    my $longest_path = ($length > 10 ? '...' : join(' -- ',@longest_path));
    print "longest $length cf v=$num_vertices  [$count of] $longest_path\n";

    my $subgraph = $graph->subgraph(\@longest_path);
    Graph_xy_print($graph);
    Graph_xy_print($subgraph);
  }

  sub search_induced_paths {
    my ($graph, $callback) = @_;
    my @names = sort $graph->vertices;
    ### @names
    my $last_v = $#names;
    ### $last_v
    my %name_to_v = map { $names[$_] => $_ } 0 .. $#names;
    ### %name_to_v
    my @neighbours = map {[ sort {$a<=>$b}
                            map {$name_to_v{$_}}
                            $graph->neighbours($names[$_])
                          ]} 0 .. $#names;
    ### @neighbours
    my @path;
    my @path_try = ([0 .. $#names]);
    my @path_try_upto = (0);
    my @exclude;

    for (;;) {
      my $pos = scalar(@path);
      ### at: "path=".join(',',@path)." pos=$pos, try v=".($path_try[$pos]->[$path_try_upto[$pos]]//'undef')
      my $v = $path_try[$pos]->[$path_try_upto[$pos]++];
      if (! defined $v) {
        ### backtrack ...
        $v = pop @path;
        if (! defined $v) {
          return;
        }
        $exclude[$v]--;
        if (@path) {
          my $n = $neighbours[$path[-1]];
          ### unexclude prev neighbours: join(',',@$n)
          foreach my $neighbour (@$n) {
            $exclude[$neighbour]--;
          }
        }
        next;
      }

      if ($exclude[$v]) {
        ### skip excluded ...
        next;
      }

      push @path, $v;
      $callback->(map {$names[$_]} @path);

      if ($#path >= $last_v) {
        ### found path through all vertices ...
        pop @path;
        next;
      }

      ### add: "$v trying ".join(',',@{$neighbours[$v]})
      $exclude[$v]++;
      if ($pos >= 1) {
        my $n = $neighbours[$path[-2]];
        ### exclude prev neighbours: join(',',@$n)
        foreach my $neighbour (@$n) {
          $exclude[$neighbour]++;
        }
      }
      $pos++;
      $path_try[$pos] = $neighbours[$v];
      $path_try_upto[$pos] = 0;
    }
  }
}


{
  # Vertices as permutations, edges for some elements swap
  # 3 cycle of 6
  # 4 row   4-cycles cross connected
  #         truncated octahedral
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1391
  # 4 cycle rolling cube
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1292
  # 4 all   Reye graph = transposition graph order 4
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1277
  # 4 star  Nauru graph
  #         generalized Petersen, perumtation star graph 4
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1234
  require Graph;
  my $graph = Graph->new (undirected=>1);
  my $num_elements;
  my @swaps;

  $num_elements = 3;
  @swaps = ([0,1], [1,2]);         # 3-row = cycle of 6

  $num_elements = 4;
  @swaps = ([0,1], [0,2], [0,3], [1,2], [1,3], [2,3]);  # 4-all
  @swaps = ([0,1], [0,2], [0,3]);  # 4-star claw
  @swaps = ([0,1], [1,2], [2,3]);         # 4-row
  @swaps = ([0,1], [1,2], [2,3], [3,0]);  # 4-cycle

  my @pending = ([0 .. $num_elements-1]);
  my %seen;
  while (@pending) {
    my $from = pop @pending;
    my $from_str = join('',@$from);
    next if $seen{$from_str}++;

    foreach my $swap (@swaps) {
      my ($s1,$s2) = @$swap;
      my $to = [ @$from ];
      ($to->[$s1], $to->[$s2]) = ($to->[$s2], $to->[$s1]);
      my $to_str = join('',@$to);
      $graph->add_edge($from_str,$to_str);
      push @pending, $to;
    }
  }
#  Graph_view($graph);
#  Graph_print_tikz($graph);
  my $diameter = $graph->diameter;

  my @from = (0 .. $num_elements-1);
  my $from_str = join('',@from);
  my @rev = (reverse 0 .. $num_elements-1);
  my $rev_str = join('',@rev);
  print "diameter $diameter  from $from_str\n";
  print "reversal $rev_str distance=",
    $graph->path_length($from_str,$rev_str),"\n";
  foreach my $v (sort $graph->vertices) {
    my $len = $graph->path_length($from_str,$v) || 0;
    print " to $v distance $len",
      $len == $diameter ? "****" : "",
      "\n";
  }
  my @cycles;
  Graph_find_all_4cycles($graph, callback=>sub {
                           my @cycle = @_;
                           push @cycles, join(' -- ',@cycle);
                         });
  @cycles = sort @cycles;
  my $count = @cycles;
  foreach my $cycle (@cycles) {
    print "cycle $cycle\n";
  }
  print "count $count cycles\n";

  hog_searches_html($graph);
  exit 0;
}


{
  # neighbours
  require Graph;
  my $graph = Graph->new (undirected=>1);
  my $num_elements = 4;
  my @swaps = ([0,1], [1,2], [2,3]);

  my @pending = ([0 .. $num_elements-1]);
  my %seen;
  while (@pending) {
    my $from = pop @pending;
    my $from_str = join('-',@$from);
    next if $seen{$from_str}++;

    foreach my $swap (@swaps) {
      my ($s1,$s2) = @$swap;
      my $to = [ @$from ];
      ($to->[$s1], $to->[$s2]) = ($to->[$s2], $to->[$s1]);
      my $to_str = join('-',@$to);
      $graph->add_edge($from_str,$to_str);
      push @pending, $to;
    }
  }

  foreach my $x (sort $graph->vertices) {
    my @neighbours = $graph->neighbours($x);
    foreach my $y (@neighbours) {
      foreach (1 .. 5) {
        my $has_edge = $graph->has_edge($x, $y);
        print $has_edge;
        $has_edge = $graph->has_edge($y, $x);
        print $has_edge;
      }
    }
  }
  print "\n";

  Graph_find_all_4cycles($graph);
  exit 0;
}

{
  # count graphs with uniquely attained diameter
  # unique     1,1,1,2, 5, 25,185, 2459
  # not unique 0,0,1,4,16, 87,668, 8658
  # total      1,1,2,6,21,112,853,11117              A001349

  # count trees with uniquely attained diameter
  # unique     1,1,1,1,1,2, 3, 6,11, 24, 51,118, 271, 651,1572
  # not unique 0,0,0,1,2,4, 8,17,36, 82,184,433,1030,2508,6169
  # total      1,1,1,2,3,6,11,23,47,106,235,551,1301,3159,7741    A000055
  # increment    0,0,0,0,0, 0, 0, 0,  1,  4, 12,  36, 100, 271
  # diff = unique[n] - total[n-2]

  require Graph;
  my @count_unique;
  my @count_not;
  my @count_total;
  my @diff;
  foreach my $num_vertices (1 .. 8) {
    my $count_unique = 0;
    my $count_not = 0;
    my $count_total = 0;

    # my $iterator_func = make_tree_iterator_edge_aref
    #   (num_vertices => $num_vertices);
    my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
      (num_vertices => $num_vertices);
  GRAPH: while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      my $apsp = $graph->all_pairs_shortest_paths;
      my $diameter = $apsp->diameter;
      my $attained = 0;
      $count_total++;
      my @vertices = $graph->vertices;
      foreach my $i (0 .. $#vertices) {
        my $u = $vertices[$i];
        foreach my $j ($i+1 .. $#vertices) {
          my $v = $vertices[$j];
          if ($apsp->path_length($u,$v) == $diameter) {
            $attained++;
            if ($attained > 1) {
              $count_not++;
              next GRAPH;
            }
          }
        }
      }
      $count_unique++;
    }
    my $diff = (@count_total>=2 ? $count_unique - $count_total[-2] : 0);
    print "n=$num_vertices total $count_total unique $count_unique not $count_not  diff $diff\n";
    push @count_unique, $count_unique;
    push @count_not, $count_not;
    push @count_total, $count_total;
    if (@count_total >= 2) {
      push @diff, $diff;
    }
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@count_unique, verbose=>1, name=>'unique');
  Math::OEIS::Grep->search(array => \@count_not, verbose=>1, name=>'not');
  Math::OEIS::Grep->search(array => \@count_total, verbose=>1, name=>'total');
  Math::OEIS::Grep->search(array => \@diff, verbose=>1, name=>'diff');

  exit 0;
}
