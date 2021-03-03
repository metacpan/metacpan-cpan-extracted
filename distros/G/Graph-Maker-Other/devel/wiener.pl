#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2021 Kevin Ryde
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
use 5.010;
use File::Slurp;
use List::Util 'min','max';
use POSIX 'ceil';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;

# GP-DEFINE  nearly_equal(x,y,delta=1-e10) = abs(x-y) < delta;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # average_path_length() / diameter of various graph types
  #
  #
  #--------------------
  # linear
  # *--*--*--*
  # n=4; sum(i=1,n-1, i) == n*(n-1)/2
  # 2*sum(n=2,N, n*(n-1)/2) = (N-1)*(N)*(N+1)/3  \\ 2*tetrahedral
  # (N-1)*(N)*(N+1)/3 / (N-1) / N^2 -> 1/3
  #
  # GP-DEFINE  linear_diameter(k) = k-1;
  # GP-DEFINE  linear_W_by_sum(k) = sum(i=1,k, sum(j=i+1,k, j-i));
  # vector(20,k,k--; linear_W_by_sum(k))
  # GP-DEFINE  linear_W(k) = 1/6*k*(k^2-1);
  # \\ A000292 tetrahedral  n*(n+1)*(n+2)/6 = (n+1)*((n+1)^2-1)/6
  # GP-Test  vector(100,k,k--; linear_W(k)) == vector(100,k,k--; linear_W_by_sum(k))
  # GP-DEFINE linear_binomial(k) = k*(k-1)/2;
  # vector(100,k,k--; linear_binomial(k)) == vector(100,k,k--; binomial(k,2))
  # GP-DEFINE linear_mean_by_formula(k) = linear_W(k) / (linear_diameter(k) * binomial(k,2));
  # linear_mean(k) = 1/6*k*(k^2-1) /  (k*(k-1)/2) / (k-1);
  # linear_mean(k) = 1/3*(k+1)/(k-1);
  # linear_mean(k) = my(n=k-1); (n+2)/(3*n);
  # linear_mean(k) = my(n=k+1); n/(3*(n-2));
  # GP-DEFINE linear_mean(k) = 1/3 + 2/3/(k-1);
  # GP-Test  vector(100,k,k++; linear_mean(k)) == vector(100,k,k++; linear_mean_by_formula(k))
  # GP-Test my(k=1000000); nearly_equal(linear_mean(k), 1/3, 1e-3)   \\ -> 1/3
  # GP-DEFINE  A060789(n) = n/gcd(n,2)/gcd(n,3);  \\ numerator
  # GP-Test  vector(100,k,k++; numerator(linear_mean(k))) == vector(100,k,k++; A060789(k+1))
  # vector(30,k,k++; denominator(linear_mean(k))) \\ *1.0
  #   can divide out possible 2 if n even, possible 3 too,
  #   otherwise n,n-1 no common factor
  # denominator not
  #
  #--------------------
  # star of k vertices
  #    *
  #    |
  # *--*--*
  # GP-DEFINE  star_W_by_terms(k) = if(k==0,0, 2*binomial(k-1,2) + k-1);
  # star_W(0) == 0
  # star_W(4) == 1+2+2 + 1+1 + 2
  # GP-DEFINE  star_W(k) = if(k==0,0, (k-1)^2);
  # GP-Test  vector(100,k,k--; star_W(k)) == vector(100,k,k--; star_W_by_terms(k))
  # GP-DEFINE  star_diameter(k) = if(k<=1,0, k==2,1, 2);
  # GP-DEFINE  star_mean_by_formula(k) = star_W(k) / star_diameter(k) / binomial(k,2);
  # GP-DEFINE  star_mean(k) = if(k==2,1, 1 - 1/k);  \\ -> 1
  # GP-Test  vector(100,k,k++; star_mean(k)) == vector(100,k,k++; star_mean_by_formula(k))
  # vector(20,k,k++; star_mean(k))
  #
  #----------
  # Graph::Maker::BalancedTree, rows 0 to n inclusive
  # A158681 Wiener of complete binary tree = 4*(n-2)*4^n + 2*(n+4)*2^n
  #   = 4, 48, 368, 2304 starting n=1
  #    *    (1+2 + 2 + 1+2)/2 = 4
  #   / \   has 2^(n+1)-1 vertices
  #  *   *
  #  diameter 2*n
  # GP-DEFINE  complete_binary_W(n) = 4*(n-2)*4^n + 2*(n+4)*2^n;
  # GP-Test  complete_binary_W(1) == 4
  # GP-Test  complete_binary_W(2) == 48
  # GP-DEFINE  complete_binary_N(n) = 2^(n+1)-1;
  # GP-Test  complete_binary_N(1) == 3
  # GP-DEFINE  complete_binary_diameter(n) = 2*n;
  # GP-Test  complete_binary_diameter(1) == 2
  # GP-DEFINE  complete_binary_mean(n) = 2*complete_binary_W(n) \
  # GP-DEFINE   / complete_binary_N(n)^2 \
  # GP-DEFINE   / complete_binary_diameter(n);
  # GP-DEFINE  complete_binary_mean_formula(n) = \
  # GP-DEFINE    1 - 2/n + 3*1/(2*2^n - 1) + 2*(1 + 1/n)*1/(2*2^n - 1)^2;
  # GP-Test  vector(100,n, complete_binary_mean_formula(n)) == vector(100,n, complete_binary_mean(n))
  # complete_binary_mean -> 1 slightly slowly
  #
  #----------
  # BinomialTree
  # A192021 Wiener of binomial tree = 2*n*4^n + 2^n
  # W Binomial tree = (k-1)*2^(2k-1) + 2^(k-1)
  # (in POD)
  #
  #----------
  # Cycle
  # GP-DEFINE cycle_W_by_sum(k) = sum(i=1,k, sum(j=i+1,k, min(j-i, (i-j)%k)));
  # cycle_W_by_sum(0) == 0
  # cycle_W_by_sum(1) == 0
  # cycle_W_by_sum(2) == 1
  # cycle_W_by_sum(3) == 3
  # cycle_W_by_sum(4) == 1+1+2 + 1+2 + 1
  # vector(20,k,k--; cycle_W_by_sum(k))
  # GP-DEFINE  cycle_W(k) = 1/2 * k * floor((k/2)^2);
  # GP-DEFINE  cycle_W(k) = 1/2*k*((k/2)^2 - if(k%2==1,1/4));
  # GP-Test  vector(100,k,k--; cycle_W(k)) == vector(100,k,k--; cycle_W_by_sum(k))
  # GP-DEFINE  cycle_diameter(k) = floor(k/2);
  # GP-DEFINE  cycle_mean_by_formula(k) = cycle_W(k) / cycle_diameter(k) / binomial(k,2);
  # GP-DEFINE  cycle_mean(k) = 1/2 + (k^2/4 - 1/2*(k-1)*(k/2-if(k%2==1,1/2)) - if(k%2==1,1/4)) / (k-1) / floor(k/2);
  # GP-DEFINE  cycle_mean(k) = 1/2 + (k^2/4 - (k-1)*(k/4-if(k%2==1,1/4)) - if(k%2==1,1/4)) / (k-1) / floor(k/2);
  # GP-DEFINE  cycle_mean(k) = 1/2 + 1/4*(k*if(k%2==0,1,2) - if(k%2==0,0,1) - if(k%2==0,0,1)) / (k-1) / floor(k/2);
  # GP-DEFINE  cycle_mean(k) = 1/2 + 1/4*(if(k%2==0,k,2*k-2)) / (k-1) / if(k%2==0,k/2,(k-1)/2);
  # GP-DEFINE  cycle_mean(k) = 1/2 + 1/2*if(k%2==0,k / (k-1) / if(k%2==0,k,k-1),(2*k-2) / (k-1) / if(k%2==0,k,k-1));
  # GP-DEFINE  cycle_mean(k) = 1/2 + 1/2*if(k%2==0, 1/k + 1/(k*(k-1)), 2/(k-1));
  # GP-Test  vector(100,k,k++; cycle_mean(k)) == vector(100,k,k++; cycle_mean_by_formula(k))
  # GP-Test my(k=1000000); nearly_equal(cycle_mean(k), 1/2, 1e-3)   \\ -> 1/2
  # vector(30,k,k++; numerator(cycle_mean(k)))
  # vector(30,k,k++; denominator(cycle_mean(k)))
  #
  #----------
  # Hypercube
  # GP-DEFINE hypercube_W_by_sum(k) = sum(i=0,2^k-1, sum(j=i+1,2^k-1, hammingweight(bitxor(i,j))));
  # hypercube_W_by_sum(0) == 0
  # hypercube_W_by_sum(1) == 1
  # hypercube_W_by_sum(2) == 8
  # vector(8,k,k--; hypercube_W_by_sum(k))
  #
  # GP-DEFINE  hypercube_W(k) = k*4^(k-1);
  # GP-Test  vector(10,k,k--; hypercube_W(k)) == \
  # GP-Test  vector(10,k,k--; hypercube_W_by_sum(k))
  #
  # GP-DEFINE  hypercube_diameter(k) = k;
  # GP-DEFINE  hypercube_mean_by_formula(k) = \
  # GP-DEFINE    hypercube_W(k) / hypercube_diameter(k) / binomial(2^k-1,2);
  # GP-DEFINE  hypercube_mean(k) = 1/2 * 4^k / (2^k-1)/(2^k-2);
  # GP-Test  vector(20,k,k++; hypercube_mean_by_formula(k)) == \
  # GP-Test  vector(20,k,k++; hypercube_mean(k))
  # GP-Test  vector(20,k,k++; hypercube_mean_by_formula(k)) == \
  # GP-Test  vector(20,k,k++; 1/2 + 1/2*(3*2^k - 2) / (2^k-1)/(2^k-2))
  # GP-Test  vector(20,k,k++; hypercube_mean_by_formula(k)) == \
  # GP-Test  vector(20,k,k++; 1/2 + 1/2*(3*2^k-3 +3 - 2) / (2^k-1)/(2^k-2))
  # GP-Test  vector(20,k,k++; hypercube_mean_by_formula(k)) == \
  # GP-Test  vector(20,k,k++; 1/2 + 3/2/(2^k-2) + 1/2/(2^k-1)/(2^k-2))
  # GP-Test  my(k=100); nearly_equal(hypercube_mean(k), 1/2, 1e-3)   \\ -> 1/2
  #
  # vector(30,k,k++; numerator(hypercube_mean(k)))    \\ 4^k
  # vector(30,k,k++; denominator(hypercube_mean(k)))  \\ binomial(2^k-1,2)
  # vector(10,k,k++; hypercube_mean(k)*1.0)

  require Graph::Maker::Star;
  require Graph::Maker::Linear;
  my @values;
  foreach my $k (1..4) {
    # my $graph = Graph::Maker->new('star', N=>$k, undirected=>1);
    # my $graph = Graph::Maker->new('linear', N=>$k, undirected=>1);

    # require Graph::Maker::BalancedTree;
    # my $graph = Graph::Maker->new('balanced_tree',
    #                               fan_out => 2, height => $k,
    #                              );

    # require Graph::Maker::BinomialTree;
    # my $graph = Graph::Maker->new('binomial_tree',
    #                               order => $k,
    #                               undirected => 1,
    #                              );

    # require Graph::Maker::Cycle;
    # my $graph = Graph::Maker->new('cycle', N => $k);

    # require Graph::Maker::Hypercube;
    # my $graph = Graph::Maker->new('hypercube', N => $k);

    require Graph::Maker::Keller;
    my $graph = Graph::Maker->new('Keller', N => $k);

    # require Graph::Maker::FibonacciTree;
    # my $graph = Graph::Maker->new('fibonacci_tree',
    #                               height => $k,
    #                               # leaf_reduced => 1,
    #                               # series_reduced => 1,
    #                              );

    # my $total = Graph_total_path_length($graph);
    my $W = MyGraphs::Graph_Wiener_index($graph);
    my $vertices = $graph->vertices;
    my $diameter = $graph->diameter || 0;
    my $div = $vertices*($vertices-1)/2;
    my $average = ($div == 0 || $diameter == 0 ? 'undef'
                   : $W / $div / $diameter);
    # my $average = ($diameter == 0 ? 'undef'
    #                : $total / $diameter / $vertices**2);
    if ($k==1) { print $graph->get_graph_attribute ('name'),"\n"; }
    print "$k W=$W diam=$diameter $average\n";
    push @values, $W;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;

  sub Graph_total_path_length {
    my ($graph) = @_;
    my $total = 0;
    # for_shortest_paths() is $u,$v and back $v,$u
    $graph->for_shortest_paths
      (sub {
         my ($t, $u,$v, $n) = @_;
         # print "path $u to $v  is ",$t->path_length($u,$v),"\n";
         $total += $t->path_length($u,$v);
       });
    return $total;
  }
}
{
  # trees or graphs with mean distance
  #
  # -----
  # trees, mean = 1/2 diameter
  # vertices 2     5        8 9 10   11
  # count    0 0 0 1 0  0   1 2  1 0  5 21 19 11 144
  # n=5 path-5
  # n=8             https://hog.grinvin.org/ViewGraphInfo.action?id=25162
  # n=9 middle 1,2  https://hog.grinvin.org/ViewGraphInfo.action?id=25164
  # n=9 symmetric   https://hog.grinvin.org/ViewGraphInfo.action?id=25166
  # n=10            https://hog.grinvin.org/ViewGraphInfo.action?id=25168
  # -----
  # all graphs, mean = 1/2 diameter
  # vertices 2     5    9  10y
  # count    0 0 0 2 0 11 673
  # n=5 kite         https://hog.grinvin.org/ViewGraphInfo.action?id=782
  #     path-5 tree

  # --------------------------------------
  # trees, mean = 2/3 diameter
  # 3  path
  # 7  https://hog.grinvin.org/ViewGraphInfo.action?id=452
  #    bi-star 4,3 (a graphedron extreme, comment posted)
  # 12 https://hog.grinvin.org/ViewGraphInfo.action?id=27412
  #    tree mean 2.666 of diam 0.666 W=176 num_pairs=66(12) diameter=4
  #         *
  #         |
  #     *   *   *
  #     |   |   |
  # *---*---*---*
  #     |   |   |
  #     *   *   *
  #         |
  #         *
  # n=13  4 of 
  # tree mean 2.666 of diam 0.666 W=208 num_pairs=78 diameter=4
  # hog not any
  # -----
  # all graphs, mean = 2/3 diameter
  # n=3 path
  # n=4 square and 3-cycle plus one
  # n=6  total 12
  #      one hanging vertex
  #      hog not
  #      sans leaf https://hog.grinvin.org/ViewGraphInfo.action?id=450
  #                = Beineke G3
  #     cf just the pyramid https://hog.grinvin.org/ViewGraphInfo.action?id=442

  # --------------------------------------
  # all graphs, mean = 3/4 diameter
  # n=3  claw
  # n=5  5-cycle
  #      3-cycle and 2 hanging
  # n=6  none
  # -----
  # tree, mean = 3/4 diameter
  # n=3  claw
  # n=16 https://hog.grinvin.org/ViewGraphInfo.action?id=27414
  #      bi-star 10,6 (comment posted)
  #      tree mean 2.25 of diam 0.75 W=270 num_pairs=120 diameter=3
  #      hog not
  # n=17 bi-star 11,6
  #      no others
  # clusters of stars up to n=25 ...

  # -----
  # all graphs, mean = 5/6 diameter
  # n=7  triangle with 4 hanging off one corner
  #        W=35 num_pairs=21(7) diameter=2
  # tree, mean = 5/6 diameter
  # n=6  6-star W=25 num_pairs=15(6) diameter=2


  # -----
  # all graphs, mean = 6/7 diameter
  # n=8  triangle with 5 hanging off one corner
  # tree, mean = 6/7 diameter
  # n=7  7-star W=36 num_pairs=21(7) diameter=2

  my $num = 2;
  my $den = 3;
  my $tree = 1;
  my $terminal = 0;

  require Graph;
  require MyGraphs;
  my @values;
  my @graphs;
  foreach my $num_vertices (13,
                            # 2 .. 6,
                            # 17,
                           ) {
    print "n=$num_vertices\n";

    my $iterator_func =  ($tree
                          ? MyGraphs::make_tree_iterator_edge_aref
                          (num_vertices => $num_vertices)
                          :  MyGraphs::make_graph_iterator_edge_aref
                          (num_vertices => $num_vertices));
    my $count = 0;
    while (my $edge_aref = $iterator_func->()) {
      my $graph = MyGraphs::Graph_from_edge_aref($edge_aref);
      my $W = ($terminal
               ? $graph->MyGraphs::Graph_terminal_Wiener_index
               : $graph->MyGraphs::Graph_Wiener_index);
      my $diameter = $graph->diameter || 0;
      my $num_path_vertices = ($terminal
                               ? $graph->MyGraphs::Graph_leaf_vertices
                               : $num_vertices);
      my $num_pairs = $num_path_vertices * ($num_path_vertices-1) / 2;
      my $divisor = $diameter * $num_pairs;
      my $mean_dist = ($num_pairs==0 ? -1 : $W / $num_pairs);
      my $mean_of_diam = ($divisor==0 ? -1 : $W / $divisor);
      my $equal = ($den*$W == $num*$divisor);  # W/divisor = num/den
      if ($equal && ($num_vertices <= 7 || @graphs < 6)) {
        my $cyclic = $graph->is_cyclic ? "cyclic" : "tree";
        print " $cyclic mean $mean_dist of diam $mean_of_diam W=$W num_pairs=$num_pairs($num_path_vertices) diameter=$diameter\n";
      } elsif ($num_vertices <= 5) {
        print "  $mean_of_diam\n";
      }
      if ($equal) {
        $count++;
        if (@graphs < 3) {
          my $num_edges = $graph->edges;
          $graph->set_graph_attribute (name => "$num_vertices vertices $num_edges edges");
          # $graph->delete_vertices(grep {$graph->vertex_degree($_)==1} $graph->vertices);
          push @graphs, $graph;
          MyGraphs::Graph_view($graph,synchronous=>0);
          # MyGraphs::Graph_print_tikz($graph);
          # Graph_tree_print($graph);
        }
      }
    }
    print "  count $count\n";
    push @values, $count;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}


{
  require Graph;
  my $pyramid = Graph->new (undirected => 1);
  $pyramid->add_cycle(1,2,3,4);
  $pyramid->add_path(1,0,2);
  $pyramid->add_path(3,0,4);
  MyGraphs::hog_searches_html($pyramid);
  exit 0;
}

{
  # terminal Wiener maximum on trees

  require Graph;
  my @graphs;
  foreach my $n (13) {
    my $iterator_func = make_tree_iterator_edge_aref
      (num_vertices => $n);

    my $max = 0;
    my @max_graphs;
    while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      # next unless Graph_num_terminal_vertices($graph) == 8;

      my $TW = Graph_terminal_Wiener_index($graph);
      if ($TW == $max) {
        push @max_graphs, $graph;
      } elsif ($TW > $max) {
        $max = $TW;
        @max_graphs = ($graph);
      }
    }
    my $max_graphs_count = scalar(@max_graphs);
    print "n=$n  $max (count $max_graphs_count)\n";
    # print "$max,";
    foreach my $graph (@max_graphs) {
      $graph->set_graph_attribute (name => "n=$n");
      Graph_view($graph);
    }
    push @graphs, @max_graphs;
  }
  hog_searches_html(@graphs);
  exit 0;

  # return the number of terminal vertices in $graph, meaning how many degree 1
  sub Graph_num_terminal_vertices {
    my ($graph) = @_;
    return scalar(grep {$graph->vertex_degree($_)==1} $graph->vertices);
  }
}



{
  # line and star  average_path_length() / diameter
  #
  #     *   *
  #      \ /
  # *--*--*--*--*--*
  #      / \
  #     *   *

  sub Graph_line_and_star {
    my ($l, $s) = @_;
    require Graph::Maker::Linear;
    my $graph = Graph::Maker->new('linear', N=>$l, undirected=>1);
    my $u = ceil($l/2);
    foreach my $i (1 .. $s) {
      $graph->add_edge($u, $l+$i);
    }
    return $graph;
  }

  # GP-DEFINE  linear_dist_at_by_sum(n,v) = sum(i=1,v-1,v-i) + sum(i=v+1,n,i-v);
  # GP-DEFINE  linear_dist_at(n,v) = 1/2*n*(n+1) - v*(n+1) + v^2;
  # GP-DEFINE  linear_dist_at(n,v) = (1/2*n - v)*(n+1) + v^2;
  # GP-DEFINE  linear_dist_at(n,v) = 1/2*n*(n+1) - v*(n-v+1);
  # GP-Test  vector(20,n,vector(n-1,v,linear_dist_at(n,v))) == vector(20,n,vector(n-1,v,linear_dist_at_by_sum(n,v)))
  # GP-Test  linear_dist_at(6,3) == 1+2 + 1+2+3
  # GP-DEFINE  \\ l vertices linear, extra s star
  # GP-DEFINE  line_and_star_W_by_terms(l,s) = \
  # GP-DEFINE    my(middle=ceil(l/2)); \
  # GP-DEFINE    linear_W(l) + (linear_dist_at(l,middle) + l)*s + 2*binomial(s,2);
  # GP-DEFINE  line_and_star_W(l,s) = \
  # GP-DEFINE    1/6*l^3 + 1/4*l^2*s + l*s + s*(s-1) - 1/6*l - if(l%2==1, 1/4*s);
  # GP-Test  matrix(20,20,l,s, line_and_star_W(l,s)) == matrix(20,20,l,s, line_and_star_W_by_terms(l,s))
  # GP-DEFINE  line_and_star_N(l,s) = l+s;
  # GP-DEFINE  line_and_star_mean_by_divison(l,s) = line_and_star_W(l,s) / (l-1) / binomial(line_and_star_N(l,s),2);
  # GP-DEFINE  line_and_star_mean_extra(l,s) = ( 1/6*l^3 - l^2 + 5/6*l - s*l + 1/4*l^2*s - if(l%2==1, 1/4*s)) / (s+l) / (s+l-1);
  # GP-DEFINE  line_and_star_mean(l,s) = 2/(l-1)*(1 + line_and_star_mean_extra(l,s));
  # GP-Test  matrix(20,20,l,s,l++;line_and_star_mean(l,s)) == matrix(20,20,l,s,l++;line_and_star_mean_by_divison(l,s))
  # my(l=20); for(s=0,9, print(line_and_star_mean_by_division(l,s)*1.0));
  # my(l=20); vector(10,s,s--; line_and_star_W_by_terms(l,s))
  # my(l=20,s=100000); line_and_star_mean_extra(l,s)*1.0
  # my(l=10,s=1000000); line_and_star_mean(l,s)*1.0
  # 2/9.0
  # for given l, diameter l-1, mean -> 2/(l-1) = 2/diameter

  my @values;
  my $l = 20;
  foreach my $s (0..30) {
    my $graph = Graph_line_and_star($l,$s);

    # my $total = Graph_total_path_length($graph);
    my $W = Graph_Wiener_index($graph);
    my $vertices = $graph->vertices;
    my $diameter = $graph->diameter || 0;
    my $div = $vertices*($vertices-1)/2;
    my $average = ($div == 0 || $diameter == 0 ? 'undef'
                   : $W / $div / $diameter);
    # my $average = ($diameter == 0 ? 'undef'
    #                : $total / $diameter / $vertices**2);
    print "l=$l s=$s W=$W diam=$diameter $average\n";
    push @values, $W;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}
{
  # among trees smallest mean/diameter for given diameter
  # is line and star

  require Graph;
  my @values;
  my @graphs;
  foreach my $num_vertices (5..15,
                           ) {
    my $iterator_func = make_tree_iterator_edge_aref
      (num_vertices => $num_vertices);
    # my $iterator_func = make_graph_iterator_edge_aref
    #   (num_vertices => $num_vertices);
    my $smallest_mean = 100;
    my $smallest_dist;
    my $smallest_graph;
    while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      my $diameter = $graph->diameter || 0;
      next unless $diameter == 5;
      my $W = Graph_Wiener_index($graph);
      my $num_pairs = $num_vertices * ($num_vertices-1) / 2;
      my $divisor = $diameter * $num_pairs;
      my $mean = $W / ($diameter * $num_pairs);
      if ($mean < $smallest_mean) {
        $smallest_mean = $mean;
        $smallest_graph = $graph;
        $smallest_dist = $W / $num_pairs;
      }
    }
    if ($smallest_graph) {
      print "n=$num_vertices   $smallest_mean   $smallest_dist\n";
      push @graphs, $smallest_graph;
      # Graph_view($smallest_graph,synchronous=>0);
      # Graph_tree_print($smallest_graph);
    }
  }
  # require Math::OEIS::Grep;
  # Math::OEIS::Grep->search(array => \@values, verbose=>1);
  hog_searches_html(@graphs);
  exit 0;
}
{
  # Trees of given diameter with mean distance = 1/2 diameter

  # binomial(7,2)==7*(7-1)/2
  # mean = W / (d * binomial(n,2));
  # mean = W / (d * n*(n-1)/2);
  # new mean = Wnew / (d * n*(n+1)/2);
  # new mean = Wnew*(n-1)/(n+1)  / (d * n*(n-1)/2);
  # Wnew >= W + 2*(1+2+...+floor(d/2))+ceil(d/2) + 2*(n-d)
  # Wnew <= n*d

  #         *
  #         |
  #   *--*--*--*--*--*   d=5
  #   3  2  1  2  3  4
  # ends(d) = 1 + 2*sum(i=2,floor(d/2)+1,i) + if(d%2==1,(d+3)/2,0);
  # my(d=5); (d+3)/2
  # my(d=5); floor(d/2)+1==3
  # ends(0)==1
  # ends(1)==1+2
  # ends(2)==1+2+2
  # ends(3)==1+2+2+3
  # ends(4)==1+2+2+3+3
  # ends(5)==1+2+2+3+3+4
  # vector(20,d,ends(d))       \\ A024206
  # ends(d) = floor((d+1)*(d+5)/4);
  # Wadd(d,n) = if(n<d+1,error()); ends(d) + (n-(d+1))*2;
  # 10 vertices ends(4)==11 using 5, rest 5*2
  # Wadd(4,5) == 11
  # Wadd(4,6) == 13
  # Wadd(4,7) == 15
  # Wadd(4,10)
  # mean can decrease a little

  my $diameter = 9;
  my $W_half = 2*$diameter;
  my %seen;
  require Graph::Maker::Linear;
  my @pending = Graph::Maker->new('linear', N=>$diameter+1,
                                  undirected=>1);
  print "initial $pending[0]\n";
  while (@pending) {
    my $graph = shift @pending;
    my $num_vertices = $graph->vertices;
    my $new_v = $num_vertices+1;

    my $pairs = $num_vertices * ($num_vertices-1) /2;
    my $W = Graph_Wiener_index($graph);
    my $mean = $W / ($diameter * $pairs);
    print "$num_vertices vertices  W=$W  mean $mean\n";

    if (2*$W == $diameter * $pairs) {
      print "HALF\n";
    }

    # n=2 will be n=3 is 2*3/2=3 pairs
    my $new_pairs = $num_vertices * ($num_vertices+1) /2;
    my $Wadd_minimum = Wadd($diameter, $num_vertices);

    foreach my $v (sort {$a<=>$b} $graph->vertices) {
      my $new_graph = $graph->copy;
      $new_graph->add_edge($v,$new_v);
      if ($new_graph->diameter != $diameter) {
        # print " v=$v diameter expands\n";
        next;
      }
      my $new_g6_str = Graph_to_graph6_str($new_graph);
      $new_g6_str = graph6_str_to_canonical($new_g6_str);
      if ($seen{$new_g6_str}++) {
        # print " v=$v seen $new_g6_str";
        next;
      }

      my $Wnew = Graph_Wiener_index($new_graph);
      my $mean_new = $Wnew / ($diameter * $new_pairs);
      my $smaller = ($mean_new < $mean ? " *****" : "");
      my $Wadd = $Wnew - $W;
      my $min = ($Wadd == $Wadd_minimum ? "min" : "");
      print " v=$v Wnew=$Wnew (+$Wadd$min)  mean $mean_new$smaller\n";
      push @pending, $new_graph;
      # die if $smaller;
      die if $Wadd < $Wadd_minimum;
    }
  }
  exit 0;

  sub Wadd {
    my ($diameter, $num_vertices) = @_;
    return int(($diameter+1)*($diameter+5)/4) + ($num_vertices-($diameter+1))*2;
  }
}




{
  # some geometric-arithmetic mean

  require Math::BigRat;
  foreach my $k (2 .. 15) {
    # require Graph::Maker::Star;
    # my $graph = Graph::Maker->new('star', N=>$k, undirected=>1);

    # require Graph::Maker::Linear;
    # my $graph = Graph::Maker->new('linear', N=>$k, undirected=>1);

    # require Graph::Maker::BalancedTree;
    # my $graph = Graph::Maker->new('balanced_tree',
    #                               fan_out => 2, height => $k,
    #                               undirected=>1,
    #                              );

    # require Graph::Maker::FibonacciTree;
    # my $graph = Graph::Maker->new('fibonacci_tree',
    #                               height => $k,
    #                               # leaf_reduced => 1,
    #                               # series_reduced => 1,
    #                               undirected=>1,
    #                              );

    require Graph::Maker::BinomialTree;
    my $graph = Graph::Maker->new('binomial_tree',
                                  order => $k,
                                  undirected => 1,
                                 );

    my %degrees = map {$_ => $graph->vertex_degree($_)} $graph->vertices;
    my $total;
    my $num_edges = 0;
    my %count_types;
    my @total_by_sqrt;
    foreach my $edge ($graph->edges) {
      my $d1 = $degrees{$edge->[0]};
      my $d2 = $degrees{$edge->[1]};
      my $num = $d1 * $d2;
      my $den = $d1 + $d2;
      if ($den) {
        $total += 2* sqrt($num) / $den;
      }
      $num_edges++;
      if ($d1 > $d2) { ($d1,$d2) = ($d2,$d1) }
      # $count_types{"$d1,$d2"}++;
      ### $num
      ### $den
      $count_types{"$num/$den"}++;
      if ($den) {
        $total_by_sqrt[$num] ||= 0;
        $total_by_sqrt[$num] += Math::BigRat->new("2/$den");
      }
    }
    ### $num_edges
    my $f = ($num_edges ? $total / $num_edges : "no edges");
    print "$k total=$total  mean=$f\n";
    foreach my $num (1 .. $#total_by_sqrt) {
      if ($total_by_sqrt[$num]) {
        print "  $num $total_by_sqrt[$num]\n";
      }
    }
  }
  exit 0;
}


{
  # terminal Wiener / diameter range
  # maximum is star
  require Graph::Reader::Graph6;
  my $reader = Graph::Reader::Graph6->new;
  $| = 1;
  foreach my $n (4 .. 20) {
    my @graphs;
    my $filename = sprintf "$ENV{HOME}/HOG/trees%02d.g6", $n;
    open my $fh, '<', $filename or die "cannot open $filename: $!";
    my $min = 1e50;
    my $max = 0;
    my @max_graphs;
    while (my $graph = $reader->read_graph($fh)) {
      my $mean = Graph_terminal_Wiener_index($graph) / $graph->diameter;
      # print $mean,"\n";
      $min = min($min, $mean);
      if ($mean > $max) {
        $max = $mean;
        push @max_graphs, $graph;
      }
    }
    my $max_graphs_count = scalar(@max_graphs);
    print "n=$n  $min  $max($max_graphs_count)\n";
    # print "$max,";
    foreach my $graph (@max_graphs) {
      $graph->set_graph_attribute (name => "n=$n");
      Graph_view($graph);
    }
  }
  exit 0;
}



{
  # Szeged index
  # same as Wiener index on trees, bigger when cycles

  unshift @INC, "$FindBin::Bin/../../dragon/tools";
  my @values;
  foreach my $k (2 .. 7) {
    # require Graph::Maker::Star;
    # my $graph = Graph::Maker->new('star', N=>$k, undirected=>1);

    # require Graph::Maker::Linear;
    # my $graph = Graph::Maker->new('linear', N=>$k, undirected=>1);

    # require Graph::Maker::BalancedTree;
    # my $graph = Graph::Maker->new('balanced_tree',
    #                               fan_out => 2, height => $k,
    #                               undirected=>1,
    #                              );

    # require Graph::Maker::FibonacciTree;
    # my $graph = Graph::Maker->new('fibonacci_tree',
    #                               height => $k,
    #                               # leaf_reduced => 1,
    #                               # series_reduced => 1,
    #                               undirected=>1,
    #                              );

    # require Graph::Maker::BinomialTree;
    # my $graph = Graph::Maker->new('binomial_tree',
    #                               order => $k,
    #                               undirected => 1,
    #                              );

    # require Graph::Maker::TwindragonAreaTree;
    # my $graph = Graph::Maker->new('twindragon_area_tree',
    #                               level => $k,
    #                               undirected => 1,
    #                              );

    require Graph::Maker::PlanePath;
    my $graph = Graph::Maker->new('planepath', level=>$k,
                                  planepath=>'TerdragonCurve',
                                  undirected => 1);

    # if ($graph->vertices < 20) {
    #   print $graph;
    #   Graph_view($graph);
    # }
    my $Sz = Graph_Szeged_index($graph);
    my $W = Graph_Wiener_index($graph);
    print "k=$k  Sz=$Sz W=$W\n";
    push @values, $Sz;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}
sub Graph_Szeged_index {
  my ($graph) = @_;
  my @vertices = $graph->vertices;
  my $total;
  foreach my $edge ($graph->edges) {
    my ($u,$v) = @$edge;
    my $nu = 0;
    my $nv = 0;
    foreach my $w (@vertices) {
      my $ulen = $graph->path_length($u,$w) // die "no path $u to $w";
      my $vlen = $graph->path_length($v,$w) // die "no path $v to $w";
      if ($ulen < $vlen) { $nu++; }
      elsif ($vlen < $ulen) { $nv++; }
    }
    $total += $nu * $nv;
  }
  return $total;
}
