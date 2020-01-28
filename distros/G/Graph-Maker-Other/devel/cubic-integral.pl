#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
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
use Graph::Maker::Petersen;
use List::Util 'min';
use Math::BaseCnv 'cnv';
use Math::Complex 'pi';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  my @graphs;
  {
    # G9 = Desargues
    # https://hog.grinvin.org/ViewGraphInfo.action?id=1036
    my $graph = Graph->new(undirected => 1);
    $graph->set_graph_attribute (name => "G9");
    $graph->add_vertices(0 .. 19);
    foreach my $i (0 .. 9) {
      $graph->add_edge ($i, ($i+1)%10);
      $graph->add_edge ($i, 10+$i);
      $graph->add_edge (10+$i, 10+(($i+3)%10));
      my $z = Math::Complex->emake(1, pi/2 - 2*pi/10*$i);
      MyGraphs::Graph_set_xy_points($graph,
                                    $i    => [2*$z->Re, 2*$z->Im],
                                    $i+10 => [$z->Re, $z->Im]);
    }
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;

    my $petersen = Graph::Maker->new('Petersen', N=>10, K=>3, undirected=>1);
    MyGraphs::Graph_is_isomorphic($graph,$petersen) or die "different";
  }
  {
    # G10
    # https://hog.grinvin.org/ViewGraphInfo.action?id=34214
    #           /  4
    #          1-- 5
    #       /
    #      0-- 2   6
    #       \      7
    #          3-  8
    #           \  9
    my $graph = Graph->new(undirected => 1);
    $graph->set_graph_attribute (name => "G10");
    $graph->add_edge (0,1);
    $graph->add_edge (0,2);
    $graph->add_edge (0,3);
    $graph->add_edge (1,4); $graph->add_edge (1,5);
    $graph->add_edge (2,6); $graph->add_edge (2,7);
    $graph->add_edge (3,8); $graph->add_edge (3,9);
    MyGraphs::Graph_set_xy_points($graph,
                                  0 => [0,0],
                                  1 => [1,2], 2 => [1,0], 3 => [1,-2],
                                  4 => [2,2.5], 5 => [2,1.5],
                                  6 => [2,.5], 7 => [2,-.5],
                                  8 => [2,-1.5], 9 => [2,-2.5]);
    foreach my $e ($graph->edges) {
      my ($from,$to) = @$e;
      $graph->add_edge (19-$from, 19-$to);
    }
    MyGraphs::Graph_set_xy_points($graph,
                                  19 => [5,0],
                                  16 => [5-1,2], 17 => [5-1,0], 18 => [5-1,-2],
                                  10 => [5-2,2.5], 11 => [5-2,1.5],
                                  12 => [5-2,.5], 13 => [5-2,-.5],
                                  14 => [5-2,-1.5], 15 => [5-2,-2.5]);
    $graph->add_edge (4,10); $graph->add_edge (4,12);
    $graph->add_edge (5,13); $graph->add_edge (5,14);
    $graph->add_edge (6,10); $graph->add_edge (6,14);
    $graph->add_edge (7,11); $graph->add_edge (7,15);
    $graph->add_edge (8,11); $graph->add_edge (8,12);
    $graph->add_edge (9,15); $graph->add_edge (9,13);
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;
    MyGraphs::hog_upload_html($graph);

    # not a Petersen
    my $N = scalar($graph->vertices)/2;
    foreach my $K (1 .. $N) {
      my $petersen = Graph::Maker->new('Petersen', N=>$N, K=>$K, undirected=>1);
      $petersen->vertices == $graph->vertices or die;
      if (MyGraphs::Graph_is_isomorphic($graph,$petersen)) {
        die "same";
      }
    }
  }
  {
    # G11
    #
    my $graph = Graph->new(undirected => 1);
    $graph->set_graph_attribute (name => "G11");
    $graph->add_cycle (0 .. 9);
    foreach my $i (0,1, 5,6) {
      $graph->add_edge ($i, $i+3);
      $graph->add_edge (2, 2+5);
    }
    foreach my $i (0 .. 9) {
      my $z = Math::Complex->emake(1, pi/2 - 2*pi/10*($i-2));
      MyGraphs::Graph_set_xy_points($graph, $i => [$z->Re, $z->Im]);
    }
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;

    # not a Petersen
    my $N = scalar($graph->vertices)/2;
    foreach my $K (1 .. $N) {
      my $petersen = Graph::Maker->new('Petersen', N=>$N, K=>$K, undirected=>1);
      $petersen->vertices == $graph->vertices or die;
      if (MyGraphs::Graph_is_isomorphic($graph,$petersen)) {
        die "same";
      }
    }
  }
  {
    # G12 = Petersen 6,1 cross-connected cycles
    # https://hog.grinvin.org/ViewGraphInfo.action?id=32798
    my $graph = Graph->new(undirected => 1);
    $graph->set_graph_attribute (name => "G12");
    $graph->add_vertices(0 .. 11);
    foreach my $i (0 .. 5) {
      $graph->add_edge ($i, ($i+1)%6);
      $graph->add_edge ($i, 6+$i);
      $graph->add_edge (6+$i, 6+(($i+1)%6));
      my $z = Math::Complex->emake(1, pi/2 - 2*pi/6*$i);
      MyGraphs::Graph_set_xy_points($graph,
                                    $i   => [2*$z->Re, 2*$z->Im],
                                    $i+6 => [$z->Re, $z->Im]);
    }
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;

    my $petersen = Graph::Maker->new('Petersen', N=>6, K=>1, undirected=>1);
    MyGraphs::Graph_is_isomorphic($graph,$petersen) or die "different";
  }
  {
    # G13 = Nauru
    # https://hog.grinvin.org/ViewGraphInfo.action?id=1234
    #
    my $graph = Graph->new(undirected => 1);
    $graph->set_graph_attribute (name => "G13");
    my $spread = 2*pi/3*.155;
    my @s = (1,-1,1, -1,1,-1);
    my $cycle = sub {
      my ($n, $middle, $rot) = @_;
      $graph->add_cycle ($n .. $n+5);
      foreach my $i (0 .. 5) {
        my $r = 1;
        if ($i == 4 || $i == 5) { $r = .8; }
        my $z = $middle
          + Math::Complex->emake($r,
                                 pi/2 - 2*pi/3*$i
                                 + $s[$i]*$spread
                                 + $rot);
        MyGraphs::Graph_set_xy_points($graph, $n+$i => [$z->Re, $z->Im]);
      }
    };
    $cycle->(0, Math::Complex->make(0,0), 0);
    $cycle->(6,  Math::Complex->emake(3, pi/2),            pi);
    $cycle->(12, Math::Complex->emake(3, pi/2 + 2*pi*2/3), pi+2*pi*2/3);
    $cycle->(18, Math::Complex->emake(3, pi/2 + 2*pi/3),   pi +2*pi/3);
    $graph->add_edges([18,5],[21,2], [9,0],[6,3], [4,15],[1,12]);
    $graph->add_edges([10,23], [22,17], [16,11]);
    $graph->add_edges([20,7], [8,13], [14,19]);
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;

    my $petersen = Graph::Maker->new('Petersen', N=>12, K=>5, undirected=>1);
    MyGraphs::Graph_is_isomorphic($graph,$petersen) or die "different";
  }
  MyGraphs::hog_searches_html(@graphs);

  foreach my $graph (@graphs) {
    foreach my $v ($graph->vertices) {
      $graph->degree($v) == 3 or die;
    }
  }

  open my $fh, '>', '/tmp/x.gp' or die;
  print $fh <<'HERE';
is_integral_poly(poly) =
{
  my(m=factor(poly));
  for(i=1,matsize(m)[1],
     if(poldegree(m[i,1])>1, return(0)));
  1;
}
try(name,m) =
{
  my(p=charpoly(m));
  print(name" degree "poldegree(p)" integral "is_integral_poly(p));
  \\ print("  ",factor(p));
  my(m=factor(p));
  for(i=1,matsize(m)[1],
    my(r=-polcoeff(m[i,1],0));
    print1("  "r);
    if(m[i,2]!=1, print1("^"m[i,2])));
}
HERE
  foreach my $graph (@graphs) {
    my $name = $graph->get_graph_attribute('name');
    print $fh "$name=";
    MyGraphs::Graph_print_adjacency_matrix($graph,$fh);
    print $fh ";\n";
    print $fh "try(\"",$name,"\",$name);\n";
  }
  print $fh <<'HERE';
print("cospectral ",charpoly(G9) == charpoly(G10));
HERE
  close $fh or die;
  system('gp --quiet </tmp/x.gp');
  exit 0;
}
