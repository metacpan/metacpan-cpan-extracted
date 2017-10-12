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
use Math::BaseCnv 'cnv';
use Graph::Maker::Hanoi;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # Hanoi spindles=3, any
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=21136
  #   discs=3  https://hog.grinvin.org/ViewGraphInfo.action?id=22740
  #   discs=4  hog not
  #
  # spindles=3, linear
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=414
  #            path-9
  #
  # spindles=4, any
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=22742
  #
  # spindles=4, cyclic
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=25141
  #
  # spindles=4, linear
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=25143
  #
  # spindles=4, star
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=21152
  #
  my @graphs;
  foreach my $N (2 .. 2) {
    my $graph = Graph::Maker->new('hanoi',
                                  discs => $N,
                                  spindles => 3,
                                  # adjacency => 'cyclic',
                                  # adjacency => 'star',
                                  adjacency => 'linear',
                                  undirected => 1,
                                 );
    # Graph_view($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # SierpinskiTriangle
  my $depth = 4;

  require Graph;
  require Math::PlanePath::SierpinskiTriangle;
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  my $n_lo = $path->n_start;
  my $n_hi = $path->tree_depth_to_n_end($depth);
  my $graph = Graph->new (vertices => [ $n_lo .. $n_hi ],
                          edges => [ map { my $n = $_;
                                           map { [ $n, $_ ] }
                                             $path->tree_n_children($n)
                                           }
                                     $n_lo .. $n_hi ]);
  print "$graph\n";
  ### cyclic: $graph->is_cyclic
  ### acyclic: $graph->is_acyclic
  ### all_successors: $graph->all_successors($n_lo)
  ### neighbours: $graph->neighbours($n_lo)
  ### interior_vertices: $graph->interior_vertices
  ### exterior_vertices: $graph->exterior_vertices

  print "in_degree: ",join(',',map{$graph->in_degree($_)}$n_lo..$n_hi),"\n";
  print "out_degree:   ",join(',',map{$graph->out_degree($_)}$n_lo..$n_hi),"\n";
  print "num_children: ",join(',',map{$path->tree_n_num_children($_)}$n_lo..$n_hi),"\n";
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
  # forward only, 2 discs is small 6 cycle + big 2 = 8
  # *A  B  *C  D

  foreach my $discs (1 .. 8) {
    my $linear = Graph::Maker->new('hanoi',
                                   discs => $discs,
                                   spindles => 4,
                                   adjacency => 'cyclic',
                                   undirected => 1);
    my $from = 0;                # 000...00 base 4
    my $to = (4**$discs-1)*2/3;  # 222...22 base 4
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
    foreach my $discs (1 .. 7) {
      my $linear = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'linear',
                                     undirected => 1);
      my $from = 0;
      my $to = $spindles**$discs-1;
      # my $length = $linear->path_length($from, $to);
      my $length = Graph_path_length_by_breath_first($linear, $from, $to);
      print "$length\n";
    }
  }
  exit 0;
}

{
  # tikz print

  my $graph = Graph::Maker->new('hanoi',
                                discs => 2,
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
  # Dudeney spindles=4 path length N=8 is 33, N=10 is 49

  foreach my $N (10,
                 8,
                 # 21,
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new('hanoi',
                                  discs => $N,
                                  spindles => 4,
                                  undirected => 1);
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $from = 0;
    my $to = 4**$N-1;
    print "  $num_vertices vertices $num_edges edges, from $from to $to\n";
    # my $m = $graph->path_length(0, 4**$N-1);
    my $m = Graph_path_length_by_breath_first($graph, $from, $to);
    print "  m=$m\n";
  }
  exit 0;

  sub Graph_path_length_by_breath_first {
    my ($graph, $from, $to) = @_;
    my $verbose = 0;
    my %seen = ($from => undef);
    my @vertices = ($from);
    my $count = 0;
    while (@vertices) {
      my @new_vertices;
      $count++;
      if ($verbose) {
        print "  $count  ",scalar(@vertices),"   ";
        foreach my $i (0 .. min(5, $#vertices)) {
          print cnv($vertices[$i],10,4),",";
        }
        print "\n";
      }

      foreach my $v (@vertices) {
        foreach my $n ($graph->neighbours($v)) {
          next if exists $seen{$n};
          if ($n eq $to) {
            if ($verbose) { print "  $v to $n = $to\n"; }
            return $count;
          }
          $seen{$n} = undef;
          push @new_vertices, $n;
        }
      }
      @vertices = @new_vertices;
    }
  }
}


{
  # Hanoi number of edges for spindles

  # spindles=4  0,6,36,168,720,2976,12096,48768
  #             2*A103897 = 2 * 3*2^(n-1)*(2^n-1) = 3*2^n*(2^n-1)
  # 4 x complete-4 sub-graphs = 4*6 = 24 edges
  # discs=2 for given small disc position big disc binomial(3,2)=3
  # from<->to so 4*6 + 4*3 = 36

  foreach my $spindles (2 .. 10) {
    my @values;
    foreach my $discs (0 .. 7) {
      my $graph = Graph::Maker->new('hanoi',
                                    discs => $discs,
                                    spindles => $spindles,
                                    undirected => 1);
      my $num_vertices = $graph->vertices;
      my $num_edges = $graph->edges;
      print "s=$spindles d=$discs vertices $num_vertices edges $num_edges\n";
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

{
  # planar layout forcing GraphViz2

  #            0,0
  #        -1,-1  1,-1
  #   -2,-3           3,-2
  # -4,-3 -2,-3     2,-3 4,-3

  my $discs = 3;
  my $graph = Graph::Maker->new('hanoi', discs => $discs, undirected => 1);
  print $graph->get_graph_attribute('name'),"\n";

  my @vertex_to_xy = ([0,0]);
  foreach my $k (0 .. $discs-1) {
    my $pow = 3**$k;
    my $y_hi = 2**($k+1) - 1;
    my $y_offset = 2**$k - 1;
    my $x_offset = 2**$k;
    ### $y_hi
    ### $x_offset
    ### $y_offset

    # foreach my $v (0 .. $pow-1) {
    #   $vertex_to_xy[$v]->[1] -= $y_offset;
    # }

    foreach my $v (0 .. $pow-1) {
      my ($x,$y) = @{$vertex_to_xy[$v]};
      print " $x,$y";
    }
    print "\n";

    foreach my $v (0 .. $pow-1) {
      my ($x,$y) = @{$vertex_to_xy[$v]};
      if ($k%2) { ($x,$y) = xy_rotate_plus120($x,$y); }
      else { ($x,$y) = xy_rotate_minus120($x,$y); }
      $vertex_to_xy[$v+$pow]   = [$x - ($k%2?-1:1)*$x_offset, $y - $y_hi];

      if ($k%2) { ($x,$y) = xy_rotate_plus120($x,$y); }
      else { ($x,$y) = xy_rotate_minus120($x,$y); }
      $vertex_to_xy[$v+2*$pow] = [$x + ($k%2?-1:1)*$x_offset, $y - $y_hi];
    }
  }

  require GraphViz2;
  my $graphviz2 = GraphViz2->new (directed => $graph->is_directed);
  foreach my $v ($graph->vertices) {
    my ($x,$y) = @{$vertex_to_xy[$v]};
    # $y = -$y;
    $graphviz2->add_node(name => $v,
                         pin => 1,
                         pos => "$x,$y",
                        );
  }
  foreach my $edge ($graph->edges) {
    my ($from, $to) = @$edge;
    $graphviz2->add_edge(from => $from, to => $to);
  }

  $graphviz2->run(format => 'xlib',
                  driver => 'neato',
                 );
  # print $graphviz2->dot_input;
  exit 0;
}

{
  # ascii print rows downwards from 0

  my $discs = 3;
  my $graph = Graph::Maker->new('hanoi', discs => $discs, undirected => 1);
  print $graph->get_graph_attribute('name'),"\n";
  print "$graph\n";

  # Graph_view($graph);
  my @v = ($graph->has_vertex(0) ? 0 : '0'x$discs);
  my @seen;
  while (@v) {
    print join('  ',@v),"\n";
    foreach my $v (@v) { $seen[$v] = 1; }
    
    @v = map {$graph->neighbours($_)} @v;
    # @v = map {sort {$a cmp $b} $graph->neighbours($_)} @v;
    ### @v
    @v = grep {! $seen[$_]} @v;
  }
  my $count = sum(map {$_//0} @seen);
  print "$count vertices\n";
  exit 0;
}


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


