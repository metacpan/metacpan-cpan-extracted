#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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
use FindBin;
use List::Util 'min','max','sum';
use Math::BaseCnv 'cnv';

use lib "$FindBin::Bin/lib";
use Graph::Maker::TowerOfLondon;
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # Tower of London diameter etc
  # vertices
  # not in OEIS: 1,2,36,480
  # edges
  # not in OEIS: 0,1,54,1464
  # diameter
  # 0,1,8,9
  #
  require Graph::Maker::TowerOfLondon;
  my @values;
  foreach my $N (1 .. 4) {
    my $graph = Graph::Maker->new('tower_of_london',
                                  balls    => $N,
                                  spindles => $N,
                                  # adjacency => 'cyclic',
                                  # adjacency => 'star',
                                  # adjacency => 'linear',
                                  undirected => 1,
                                 );
    my $diameter = $graph->diameter || 0;
    print "N=$N  diameter $diameter\n";
    push @values, $diameter;

    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "N=$N  vertices $num_vertices  edges $num_edges\n";
    # push @values, $num_vertices;
    # push @values, $num_edges;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values,
                           verbose=>1);
  exit 0;
}

{
  # Tower of London spindles=3, any
  #   balls=2  
  #   balls=3  
  #   balls=4  
  #
  # spindles=4, any
  #   balls=2  
  #
  # spindles=4, cyclic
  #   balls=2  
  #
  # spindles=4, linear
  #   balls=2  
  #
  # spindles=4, star
  #   balls=2  
  #
  require Graph::Maker::TowerOfLondon;
  my @graphs;
  foreach my $N (0 .. 3) {
    my $graph = Graph::Maker->new('tower_of_london',
                                  balls => $N,
                                  spindles => 3,
                                  # adjacency => 'cyclic',
                                  # adjacency => 'star',
                                  # adjacency => 'linear',
                                  undirected => 1,
                                 );
    # Graph_view($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # cyclic 4-spindles
  # back or forward
  # distance 000 to 222:  2,4,10,16,22,32,50,68
  
  # lower bound 
  # l(n) = sum(i=1,n, 4*(i-1)+2);
  # vector(7,n, l(n))      \\ 2,8,18,32,50,72,98
  # vector(7,n, 2*n^2)

  # 2,8,18,36,66,120,210
  #
  # forward only, 2 balls is small 6 cycle + big 2 = 8
  # *A  B  *C  D

  foreach my $balls (1 .. 8) {
    my $linear = Graph::Maker->new('tower_of_london',
                                   balls => $balls,
                                   spindles => 4,
                                   adjacency => 'cyclic',
                                   undirected => 1);
    my $from = 0;                # 000...00 base 4
    my $to = (4**$balls-1)*2/3;  # 222...22 base 4
    my $to4 = cnv($to,10,4);
     my $length = $linear->path_length($from, $to);
    # my $length = Graph_path_length_by_breath_first($linear, $from, $to);
    print "to $to=[$to4]  $length\n";
  }
  exit 0;
}


{
  # linear path length 0 to S^N-1

  # spindles=3:   2  8 26 80 242 728 2186 6560       = 3^n - 1 
  # spindles=4:   3 10 19 34  57  88  123 176          A160002
  # spindles=5:   4 12 22 34  52  70   96
  # spindles=6:   5 14 25 38  53  72

  foreach my $spindles (6, 3 .. 6) {
    print "S=$spindles\n";
    foreach my $balls (1 .. 7) {
      my $linear = Graph::Maker->new('tower_of_london',
                                     balls => $balls, spindles => $spindles,
                                     adjacency => 'linear',
                                     undirected => 1);
      my $from = 0;
      my $to = $spindles**$balls-1;
      # my $length = $linear->path_length($from, $to);
      my $length = Graph_path_length_by_breath_first($linear, $from, $to);
      print "$length\n";
    }
  }
  exit 0;
}

{
  # tikz print

  my $graph = Graph::Maker->new('tower_of_london',
                                balls => 2,
                                spindles => 4,
                                adjacency => 'star',
                                undirected => 1,
                                vertex_names => 'digits',
                               );
  my @count;
  foreach my $v ($graph->vertices) {
    $count[$graph->degree($v)]++;
  }
  foreach my $degree (0 .. $#count) {
    if ($count[$degree]) {
      print "  % degree=$degree count $count[$degree]\n";
    }
  }
  foreach my $v (sort {$a<=>$b} $graph->vertices) {
    if ($graph->degree($v) == 3) {
      print "  % deg3  ",cnv($v,10,4),"\n";
    }
  }
  Graph_print_tikz($graph);
  exit 0;
}



{
  # London number of edges for spindles

  # spindles=4  0,6,36,168,720,2976,12096,48768
  #             2*A103897 = 2 * 3*2^(n-1)*(2^n-1) = 3*2^n*(2^n-1)
  # 4 x complete-4 sub-graphs = 4*6 = 24 edges
  # balls=2 for given small ball position big ball binomial(3,2)=3
  # from<->to so 4*6 + 4*3 = 36

  foreach my $spindles (2 .. 10) {
    my @values;
    foreach my $balls (0 .. 7) {
      my $graph = Graph::Maker->new('tower_of_london',
                                    balls => $balls,
                                    spindles => $spindles,
                                    undirected => 1);
      my $num_vertices = $graph->vertices;
      my $num_edges = $graph->edges;
      print "s=$spindles d=$balls vertices $num_vertices edges $num_edges\n";
      push @values, $num_edges;
      last if $num_edges >= 20000;
    }
    require Math::OEIS::Grep;
    Math::OEIS::Grep->search(array => \@values,
                             name => "spindles $spindles",
                             verbose=>1);
  }
  exit 0;
}


