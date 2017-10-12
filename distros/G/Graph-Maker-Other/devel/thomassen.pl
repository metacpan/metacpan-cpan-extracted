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

use strict;
use Graph;

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;

{
  # Thomassen 24 non-planar cubic hypohamiltonian
  # Carsten Thomassen, "Planar Cubic Hypohamiltonian and Hypotraceable Graphs",
  # Journal of Combinatorial Theory, Series B, volume 30, 1981, pages 36-44.
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=21146
  #
  #       -----------------s1--------------------
  #      /                  |                    \
  #     /              /---s2------\              \
  #   a1---a2---a3---a4             b1---b2---b3---b4
  #    |    |    |    |              |    |    |    |
  #   a10-           -a5            b10-           -b5
  #    |    |    |    |              |    |    |    |
  #   a9---a8---a7---a6             b9---b8---b7---b6
  #     \              \-----      /              /
  #      \                     \                 /
  #       --------------t1------t2---------------

  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle('a1','a2','a3','a4','a5','a6','a7','a8','a9','a10');
  $graph->add_edge('a2','a8');
  $graph->add_edge('a3','a7');
  $graph->add_edge('a5','a10');

  $graph->add_cycle('b1','b2','b3','b4','b5','b6','b7','b8','b9','b10');
  $graph->add_edge('b2','b8');
  $graph->add_edge('b3','b7');
  $graph->add_edge('b5','b10');
  
  $graph->add_path('s1','s2');
  $graph->add_path('a1','s1','b4');
  $graph->add_path('a4','s2','b1');
  
  $graph->add_path('t1','t2');
  $graph->add_path('a9','t1','b9');
  $graph->add_path('a6','t2','b6');

  foreach my $v ($graph->vertices) {
    my $degree = $graph->vertex_degree($v);
    if ($degree != 3) {
      print "$v degree $degree\n";
    }
  }
  {
    my %seen;
    foreach my $edge ($graph->edges) {
      my ($u,$v) = sort @$edge;
      if ($seen{"$u,$v"}++) {
        print "duplicate $u -- $v\n";
      }
    }
  }

  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "$num_vertices vertices, $num_edges edges\n";
  #  Graph_view($graph);
  hog_searches_html($graph);

  # $graph = Graph->new (undirected => 1);
  # $graph->add_cycle('a','b','c');
  # $graph->add_path('a','d','c');
  # $graph->add_path('a','e','c');

  foreach my $v ($graph->vertices) {
    my $g = $graph->copy;
    $g->delete_vertex($v);
    my $h = Graph_is_Hamiltonian($g);
    print "  sans $v Hamiltonian $h\n";
  }
  my $h = Graph_is_Hamiltonian($graph);
  print "Hamiltonian $h\n";
  exit 0;
}

{
  # Thomassen 94 planar cubic hypohamiltonian
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1359
  # my(k=23,n=4*k+2); [k,n, 1/4*(n-90)^2+137, 1/2*n-44]
  # Carsten Thomassen, "Planar Cubic Hypohamiltonian and Hypotraceable Graphs",
  # Journal of Combinatorial Theory, Series B, volume 30, 1981, pages 36-44.

  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle('a1','a2','a3','a4');
  $graph->add_edge('a1','b1');
  $graph->add_edge('a2','b2');
  $graph->add_edge('a3','b3');
  $graph->add_edge('a4','b4');

  $graph->add_cycle('b1','c1','e1','c2',
                    'b2','d2','f2','d3',
                    'b3','c3','e2','c4',
                    'b4','d4','f1','d1');
  $graph->add_edge('c1','g1'); $graph->add_edge('d1','h1');
  $graph->add_edge('c2','g2'); $graph->add_edge('d2','h2');
  $graph->add_edge('c3','g3'); $graph->add_edge('d3','h3');
  $graph->add_edge('c4','g4'); $graph->add_edge('d4','h4');
  $graph->add_edge('e1','i1');
  $graph->add_edge('e2','i2');
  $graph->add_edge('f1','j1');
  $graph->add_edge('f2','j2');

  $graph->add_cycle('h1','g1','k1','i1','k2','g2',
                    'h2','m2','r2','s2','y2',
                    'j2','y3','s3','r3','m3',
                    'h3','g3','k3','i2','k4','g4',
                    'h4','m4','r4','s4','y4',
                    'j1','y1','s1','r1','m1');

  $graph->add_path('k1','l1','n1', 'o1', 'n2','l2','k2');
  $graph->add_path('k3','l3','n3', 'o2', 'n4','l4','k4');
  $graph->add_edge('m1','l1');
  $graph->add_edge('m2','l2');
  $graph->add_edge('m3','l3');
  $graph->add_edge('m4','l4');

  $graph->add_cycle('p1','t2','u2','v2','w1','v1','u1','t1');
  $graph->add_cycle('p2','t4','u4','v4','w2','v3','u3','t3');

  $graph->add_edge('q1','n1');  $graph->add_edge('q1','r1');
  $graph->add_edge('q2','n2');  $graph->add_edge('q2','r2');
  $graph->add_edge('q3','n3');  $graph->add_edge('q3','r3');
  $graph->add_edge('q4','n4');  $graph->add_edge('q4','r4');
  $graph->add_edge('q1','t1');
  $graph->add_edge('q2','t2');
  $graph->add_edge('q3','t3');
  $graph->add_edge('q4','t4');

  $graph->add_edge('o1','p1');  $graph->add_edge('w1','odot1');
  $graph->add_edge('o2','p2');  $graph->add_edge('w2','odot2');

  $graph->add_cycle('p1','t2','u2','v2','w1','v1','u1','t1');
  $graph->add_cycle('p2','t3','u3','v3','w2','v4','u4','t4');

  $graph->add_edge('u1','s1'); $graph->add_edge('v1','x1');
  $graph->add_edge('u2','s2'); $graph->add_edge('v2','x2');
  $graph->add_edge('u3','s3'); $graph->add_edge('v3','x3');
  $graph->add_edge('u4','s4'); $graph->add_edge('v4','x4');

  $graph->add_edge('odot1','w1'); $graph->add_edge('odot2','w2');
  $graph->add_edge('odot1','z1'); $graph->add_edge('odot2','z3');
  $graph->add_edge('odot1','z2'); $graph->add_edge('odot2','z4');

  $graph->add_edge('adot1','adot2');

  $graph->add_path('y1','x1','z1','adot1','z4','x4','y4');
  $graph->add_path('y2','x2','z2','adot2','z3','x3','y3');

  foreach my $v ($graph->vertices) {
    my $degree = $graph->vertex_degree($v);
    if ($degree != 3) {
      print "$v degree $degree\n";
    }
  }
  {
    my %seen;
    foreach my $edge ($graph->edges) {
      my ($u,$v) = sort @$edge;
      if ($seen{"$u,$v"}++) {
        print "duplicate $u -- $v\n";
      }
    }
  }

  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "$num_vertices vertices, $num_edges edges\n";
  #  Graph_view($graph);
  hog_searches_html($graph);

  foreach my $v ($graph->vertices) {
    my $g = $graph->copy;
    $g->delete_vertex($v);
    my $h = Graph_is_Hamiltonian($g);
    print "  sans $v Hamiltonian $h\n";
  }
  my $h = Graph_is_Hamiltonian($graph);
  print "Hamiltonian $h\n";
  exit 0;
}
