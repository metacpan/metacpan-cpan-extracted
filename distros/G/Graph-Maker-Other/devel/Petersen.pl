#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2021, 2022 Kevin Ryde
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
use Graph::Maker::Petersen;
use List::Util 'min','max','sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;
# GP-DEFINE read("OEIS-data.gp");
# GP-DEFINE read("OEIS-data-wip.gp");

# uncomment this to run the ### lines
# use Smart::Comments;

# GP-DEFINE  gf_terms(g,n) = {
# GP-DEFINE    if(g==0,return(vector(n)));
# GP-DEFINE    my(x = variable(g),
# GP-DEFINE       zeros = min(n,valuation(g,x)),
# GP-DEFINE       v = Vec(g + O(x^n)));
# GP-DEFINE    if(zeros>=0, concat(vector(zeros,i,0), v),
# GP-DEFINE                 v[-zeros+1 .. #v]);
# GP-DEFINE  }
# GP-DEFINE  gf_term(g,n) = gf_terms(g,n+1)[n+1];


{
  # indpoly rows
  
  # v= [ [1, 6, 6], \
  #      [1, 8, 18, 12], \
  #      [1, 10, 30, 30, 5], \
  #      [1, 12, 48, 74, 36], \
  #      [1, 14, 70, 154, 147, 49], \
  #      [1, 16, 96, 272, 378, 240, 52], \
  #      [1, 18, 126, 438, 801, 747, 303, 27], \
  #      [1, 20, 160, 660, 1510, 1912, 1240, 320, 5], \
  #      [1, 22, 198, 946, 2607, 4213, 3861, 1804, 319] ]
  # v = apply(vecsum,v)
  # not in OEIS: 13, 39, 76, 171, 435, 1055, 2461, 5828, 13971
  # vector(#v\2,i, v[2*i])      \\ even A182054
  # vector(#v\2,i, v[2*i-1])    \\ odd A182077

  # v=apply(r->Polrev(r,'y), v)
  # recurrence_guess(v)

  # A182054 Number of independent sets of nodes in the generalized Petersen graph G(2n,2) (n>=0).
  # A182077 Number of independent sets of nodes in the generalized Petersen graph G(2n+1,2) (n>=1).
  # GP-DEFINE  A182054(n) = {
  # GP-DEFINE    gf_term( ((6*x^2-11*x-8)*(2*x^3-5*x^2-4*x+1))
  # GP-DEFINE              / (4*x^5-13*x^4+3*x^3+15*x^2+3*x-1), n);
  # GP-DEFINE  }
  # GP-Test  OEIS_check_func("A182054",,['offset,0])
  # GP-DEFINE  A182077({
  # GP-DEFINE    n) = gf_term( (-4*x^4+23*x^3-12*x^2-37*x-13)
  # GP-DEFINE                / (4*x^5-13*x^4+3*x^3+15*x^2+3*x-1), n);
  # GP-DEFINE  }
  # GP-Test  OEIS_check_func("A182077",,['offset,0])
  # GP-DEFINE  both(n) = {
  # GP-DEFINE    n>=0 || error();
  # GP-DEFINE    if(n<=1,1, 
  # GP-DEFINE       n%2,  A182077(n\2-1), A182054(n\2));
  # GP-DEFINE  }
  # GP-DEFINE  want = [1, 1, 3, 13, 39, 76, 171, 435, 1055, 2461, 5828, 13971];
  # GP-Test  vector(#want,n,n--; both(n)) == want
  # GP-Test  both(0) == 1
  # GP-Test  both(1) == 1
  # GP-Test  both(2) == 3 
  # GP-Test  both(3) == 13
  # recurrence_guess(vector(500,n,n--; both(n)))

  # vector(#want,n, a(n)) == \
  # vector(#want,n, both(n))
  # vector(#want,n,n-=4; a(n))
  # a(n) = vecsum(Vec(lift(f*m^n)))
  # m=Mod(x, x^5 - x^4 - x^3 - 3*x^2 - 5*x - 2)
  # f=Polrev([15, 26, 12, 6, -4])/11
  # lindep([vector(20,n,both(n)), \
  #         vector(20,n,polcoeff(Pol(lift(m^n)),0)), \
  #         vector(20,n,polcoeff(Pol(lift(m^n)),1)), \
  #         vector(20,n,polcoeff(Pol(lift(m^n)),2)), \
  #         vector(20,n,polcoeff(Pol(lift(m^n)),3)), \
  #         vector(20,n,polcoeff(Pol(lift(m^n)),4))])
  # -lindep([vector(20,n,both(n)), \
  #         vector(20,n,vecsum(Vec(lift(m^(n+0))))), \
  #         vector(20,n,vecsum(Vec(lift(m^(n+1))))), \
  #         vector(20,n,vecsum(Vec(lift(m^(n+2))))), \
  #         vector(20,n,vecsum(Vec(lift(m^(n+3))))), \
  #         vector(20,n,vecsum(Vec(lift(m^(n+4)))))])


  # Bautista-Ramos et al paper:
  # P= - (52*x^4 - 165*x^3 + 16*x^2 + 207*x + 76) \
  #  / (4*x^5 - 13*x^4 + 3*x^3 + 15*x^2 + 3*x - 1)
  # gf_terms(P,10)

  # N,1 circular ladder
  # A051927 Number of independent vertex sets in the n-prism graph Y_n = K_2 X C_n (n > 2).

  my $K = 2;
  foreach my $N (0..16) {
    my $graph = Graph::Maker->new('Petersen', undirected => 1,
                                  N => $N, K => $K);
    my $num_vertices = $graph->vertices;
    $num_vertices == 2*$N or die "N=$N num vertices $num_vertices";
    my @indsizes = MyGraphs::Graph_indset_sizes($graph);
    # @indsizes = reverse @indsizes;
    # print "[",join(', ',@indsizes),"],\n";
    print sum(@indsizes),", ";
  }
  exit 0;
}

{
  # Petersen HOG
  
  # N=3 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=746
  #         triangles cross connected
  #         circular ladder 3 rungs
  # N=4 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=1022
  #         squares cross connected = cube
  # N=4 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=588
  #         squares with cross connected pairs
  # N=5 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=36274
  # N=5 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=660
  #         Petersen
  # N=6 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=32798
  # N=6 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=34383  Durer
  # N=6 K=3 hog not
  # N=7 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=36287
  # N=7 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=28482
  # N=7 K=3 hog not
  # N=8 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=36292
  # N=8 K=2 hog not
  # N=8 K=3 https://hog.grinvin.org/ViewGraphInfo.action?id=1229
  #         Moebius Kantor Graph
  # N=8 K=4 hog not
  # N=9 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=36298
  # N=9 K=2 hog not
  # N=9 K=3 https://hog.grinvin.org/ViewGraphInfo.action?id=6700
  # N=10 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=36310
  # N=10 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=1043
  #          Dodecahedral Graph
  # N=10 K=3 https://hog.grinvin.org/ViewGraphInfo.action?id=1036
  #          Desargues Graph
  # N=10 K=4
  # N=10 K=5
  # N=11 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=24052
  # N=12 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=27325
  # N=12 K=5 https://hog.grinvin.org/ViewGraphInfo.action?id=1234
  #          Nauru
  #    http://11011110.livejournal.com/124705.html (gone)
  #    http://web.archive.org/web/1id_/http://11011110.livejournal.com/124705.html
  
  # N=13 K=5 https://hog.grinvin.org/ViewGraphInfo.action?id=36346
  # N=15 K=4 https://hog.grinvin.org/ViewGraphInfo.action?id=36361

  my @graphs;
  my %seen;
  foreach my $N (13) {
    foreach my $K (1 .. $N-1) {
      my $graph = Graph::Maker->new('Petersen', undirected => 1,
                                    N => $N, K => $K);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;

      push @graphs, $graph;
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Petersen triangle replaced
  # = cubic vertex-transitive graph "Ct66"
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28537

  # require Graph::Maker::Cycle;
  # $graph = Graph::Maker->new('cycle', N=>4, undirected => 1);

  my $graph = Graph::Maker->new('Petersen', undirected => 1);
  my $line = MyGraphs::Graph_line_graph($graph);
  my $triangle = Graph_triangle_replacement($graph);
  print "line and triangle isomorphic ",MyGraphs::Graph_is_isomorphic($line,$triangle)||0,"\n";
  MyGraphs::Graph_view($triangle);
  MyGraphs::hog_searches_html($triangle);
  # MyGraphs::Graph_print_tikz($triangle);

  # slow but runs to completion
  print "try Hamiltonian\n";
  print MyGraphs::Graph_is_Hamiltonian($triangle, verbose => 1);
  exit 0;

  # $graph is an undirected Graph.pm.

  # Return a new Graph.pm which is the given $graph with each vertex
  # replaced by a triangle.  Existing edges go to different vertices of the
  # new triangle.  Must have all vertices of the original $graph degree <= 3.
  #
  sub Graph_triangle_replacement {
    my ($graph) = @_;
    my $new_graph = Graph->new (undirected => 1);
    foreach my $v ($graph->vertices) {
      $new_graph->add_cycle($v.'-1', $v.'-2', $v.'-3');
    }
    my %upto;
    foreach my $edge ($graph->edges) {
      $new_graph->add_edge(map {$_.'-'.++$upto{$_}} @$edge);
    }
    $new_graph;
  }
}



{
  # Petersen 7,2
  # 7,2 cf Goddard and Henning
  #     hog not
  # Ms?G?DCQ@DAID_IO?
  # Ms?G?DCQ@CaKHOE_?

  my $graph = Graph::Maker->new('Petersen', undirected => 1,
                                N => 7, K => 2);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  my $num_vertices = $graph->vertices;
  my $name = $graph->get_graph_attribute ('name');
  print "$name  n=$num_vertices\n";
  print "  girth ",MyGraphs::Graph_girth($graph),"\n";

  my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
  print $g6_str;
  print MyGraphs::graph6_str_to_canonical($g6_str);

  my $petersen = Graph->new(undirected=>1);
  $petersen->add_cycle(1,2,3,4,5);
  $petersen->add_cycle(6,8,10,7,9);
  $petersen->add_edges([1,6],[2,7],[3,8],[4,9],[5,10]);
  $num_vertices = $graph->vertices;
  print "n=$num_vertices\n";
  my $num_edges = $graph->edges;
  print "edges $num_edges\n";

  print "is_isomorphic ",MyGraphs::Graph_is_isomorphic($petersen,$graph)||0,"\n";

  exit 0;
}
{
  # Coxeter - hypohamiltonian, n=28
  # https://hog.grinvin.org/ViewGraphInfo.action?id=981

  # Coxeter triangle replaced
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1382

  # Coxeter edge excision, n=26
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1055

  require Graph::Reader::Graph6;
  my $graph = Graph::Reader::Graph6->new
    ->read_graph('/so/hog/graphs/graph_981.g6');
  my $triangle = Graph_triangle_replacement($graph);
  MyGraphs::Graph_view($triangle);
  MyGraphs::hog_searches_html($triangle);
  exit 0;
}


{
  # Petersen    https://hog.grinvin.org/ViewGraphInfo.action?id=660
  # line graph  hog not
  my $graph = Graph::Maker->new('Petersen', undirected => 1);
  my $line = Graph_line_graph($graph);
  Graph_print_tikz($line);
  # Graph_view($line);
  MyGraphs::hog_searches_html($graph, $line);
  print "is_subgraph ",Graph_is_subgraph($line,$graph),"\n";
  print "is_induced_subgraph ",Graph_is_induced_subgraph($line,$graph),"\n";
  exit 0;
}



