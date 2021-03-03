#!/usr/bin/perl -w

# Copyright 2015, 2017, 2019, 2020, 2021 Kevin Ryde
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
use Math::Trig 'pi';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use Graph::Maker::BinomialBoth;
use MyGraphs;
$|=1;
# GP-DEFINE  default(strictargs,1);
# GP-DEFINE  read("my-oeis.gp");
# GP-DEFINE  read("memoize.gp");

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # BinomialBoth Wiener index
  # not in OEIS: 0,1,8,52,300,1600,8084,39296,185640

  # Wnew_by_min() in Graph::Maker::BinomialBoth
  #  vector(9,k,k--; (k+1)*4^k - Wnew_by_min(k)) == \
  #    [0, 2, 12, 60, 280, 1260, 5544, 24024, 102960]
  # A005430 Apery numbers n*binomial(2n,n).
  #  my(want=OEIS_samples("A005430"));  /* OFFSET=0 */ \
  #    vector(#want,k,k--; (k+1)*4^k - Wnew_by_min(k)) == want
  # GP-Test  sum(k=0,20, x^k* k*binomial(2*k,k) ) == \
  # GP-Test  2*x/sqrt((1-4*x + O(x^20))^3)     /* Apery gf */
  # Vec(2*x/(1-4*x)^(3/2) + O(x^10))

  # convolution Apery with 2^k
  # Vec(2*x/(1-4*x)^(3/2) /(1-2*x) + O(x^10))
  # not in OEIS: 2, 16, 92, 464, 2188, 9920, 43864, 190688, 818956
  # Vec(1/(1-4*x)^(3/2) /(1-2*x) + O(x^10))
  # not in OEIS: 1, 8, 46, 232, 1094, 4960, 21932, 95344, 409478, 1742736

  # W sans 1/(1-2*x) convolution
  # Vec( 4*x /(1-4*x)^2 + 1 /(1-4*x) - 2*x/(1-4*x)^(3/2)  + O(x^10))
  # not in OEIS: 1, 6, 36, 196, 1000, 4884, 23128, 107048, 486864, 2183860

  # GP-Test  vector(9,k,k--; sum(u=0,k, sum(v=0,k, \
  # GP-Test     binomial(k,u)*binomial(k,v)* (u+v+1)))) == \
  # GP-Test  vector(9,k,k--; (k+1)*4^k)
  # GP-Test  vector(9,k,k--; (k+1)*4^k) == \
  # GP-Test    [1, 8, 48, 256, 1280, 6144, 28672, 131072, 589824]
  # GP-Test  my(want=OEIS_samples("A002697"));  /* OFFSET=0 */ \
  # GP-Test    vector(#want,k,k-=2; (k+1)*4^k) == want
  # A002697   Wiener index of hypercube


  #  vector(10,k,k--; W(k+1)) == \
  #  vector(10,k,k--; 2*W(k) + (k+1)*4^k - k*binomial(2*k,k))

  #  vector(10,k, W(k+1)) == \
  #  vector(10,k,    (k+1)*4^k     -       k*binomial(2*k,k) \
  #               + 2*k   *4^(k-1) - 2*(k-1)*binomial(2*(k-1),k-1) \
  #               + 4*W(k-1))

  #  vector(10,k, W(k+1)) == \
  #  vector(10,k, sum(j=0,k,     (k+1-j)*2^(k + k-j) \
  #                          - 2^j*(k-j)*binomial(2*(k-j),k-j)))

  #  vector(10,k, W(k+1)) == \
  #  vector(10,k, sum(j=0,k,   2^(k+j)*(j+1) \
  #                          - 2^(k-j)*j * binomial(2*j,j)))

  # vector(10,k, sum(j=0,k, 2^(k-j)*j * binomial(2*j,j)))
  # not in OEIS: 2, 16, 92, 464, 2188, 9920, 43864, 190688, 818956, 3485472

  # each path 0 + 1 + 1 + 2 == 4
  # except straight across throughout
  # vector(10,k, 4*W(k) + 4*Wpairs(k)) - \
  # vector(10,k, W(k+1))
  # not in OEIS: 0, 4, 20, 80, 300, 1104, 4056, 14976, 55692, 208624
  # GP-DEFINE  Wplus_shortfall(k) = {
  # GP-DEFINE    k>=0 || error();
  # GP-DEFINE    4*W(k) + 4*Wpairs(k) - W(k+1);
  # GP-DEFINE  }
  #
  # vector(10,k, Wplus_shortfall(k) - 2*Wplus_shortfall(k-1))
  # 2, 4, 12, 40, 140, 504, 1848, 6864, 25740, 97240
  # A028329  2*central binomial
  #   vector(10,k, Wplus_shortfall(k) - 2*Wplus_shortfall(k-1)) == \
  #   vector(10,k,k--; 2*binomial(2*k,k))

  #   Wplus_shortfall(0) == -1
  #   sum(k=0,19, x^k*( Wplus_shortfall(k+1) - 2*Wplus_shortfall(k) )) == \
  #   2/sqrt(1-4*x + O(x^20))
  # gshort(x)/x + 1/x - 2*gshort(x) = 2/sqrt(1-4*x)
  # gshort(x) = 2*x /( (1-2*x) * sqrt(1-4*x) )
  #   sum(k=0,20, x^k*Wplus_shortfall(k) ) == \
  #   x*(2/sqrt(1-4*x + O(x^20)) - 1/x) / (1-2*x)
  #   sum(k=0,20, x^k*Wplus_shortfall(k) ) == \
  #   (-1 + 2*x/sqrt(1-4*x + O(x^20))) / (1-2*x)

  # A082590 = 1/((1 - 2*x)*sqrt(1 - 4*x))
  # GP-DEFINE  A082590(n) = sum(j=0,n, 2^(n-j)*binomial(2*j,j));
  # vector(15,k, sum(j=0,k, 2^(k-j)*binomial(2*j,j)))
  # n*a(n) + 2*(-3*n+1)*a(n-1) + 4*(2*n-1)*a(n-2) = 0.  - R. J. Mathar
  # lindep([vector(50,k,k+=5; k*A082590(k)), \
  #         vector(50,k,k+=5; A082590(k)), \
  #         vector(50,k,k+=5; k*4^k), \
  #         vector(50,k,k+=5; 4^k), \
  #         vector(50,k,k+=5; k*2^k), \
  #         vector(50,k,k+=5; 2^k), \
  #         vector(50,k,k+=5; k^2), \
  #         vector(50,k,k+=5; k), \
  #         vector(50,k,k+=5; 1), \
  #         vector(50,k,k+=5; k*A082590(k-1)), \
  #         vector(50,k,k+=5; k*A082590(k-2)), \
  #         vector(50,k,k+=5; k*A082590(k-3)), \
  #         vector(50,k,k+=5; A082590(k-1)), \
  #         vector(50,k,k+=5; A082590(k-2)), \
  #         vector(50,k,k+=5; A082590(k-3))])

  # x/((1-2*x)*(1-4*x)) + O(x^10)
  # (-1 + 2*x/sqrt(1-4*x + O(x^10))) / (1-2*x)
  # Wplus_shortfall(k) = 4*W(k) + 4*Wpairs(k) - W(k+1)
  # 4*gW(x) - gW(x)/x + 4*x/((1-2*x)*(1-4*x)) = (-1 + 2*x/sqrt(1-4*x + O(x^10))) / (1-2*x)
  #         vector(50,k,k+=5; k^2*4^k), \
  #         vector(50,k,k+=5; 4^k), \
  #         vector(50,k,k+=5; k*4^k), \
  #         vector(50,k,k+=5; k^2*2^k), \
  #         vector(50,k,k+=5; k*2^k), \
  #         vector(50,k,k+=5; 2^k), \
  #         vector(50,k,k+=5; k^2), \
  #         vector(50,k,k+=5; k), \
  #         vector(50,k,k+=5; 1), \

  # lindep([vector(50,k,k+=5; k*W(k)), \
  #         vector(50,k,k+=5; W(k)), \
  #         vector(50,k,k+=5; k*W(k-1)), \
  #         vector(50,k,k+=5; k*W(k-2)), \
  #         vector(50,k,k+=5; k*W(k-3)), \
  #         vector(50,k,k+=5; k*W(k-4)), \
  #         vector(50,k,k+=5; W(k-1)), \
  #         vector(50,k,k+=5; W(k-2)), \
  #         vector(50,k,k+=5; W(k-3)), \
  #         vector(50,k,k+=5; W(k-4))])

  # D-finite for W
  #  vector(5,k,k+=3; (k-2)*W(k)) == \
  #  vector(5,k,k+=3;  (14*k-34)   *W(k-1) \
  #                  + (-72*k+204) *W(k-2) \
  #                  + (160*k-512) *W(k-3) \
  #                  + (-128*k+448)*W(k-4) )

  # recurrence_guess(vector(100,k, W(k+1) - 4*k*W(k)))

  #--------
  # vector(9,k,k++; TreeW(k) - W(k))
  # not in OEIS: 2, 16, 92, 464, 2188, 9920, 43864, 190688, 818956

  #--------

  # GP-DEFINE  A005259(n) = sum(k=0,n, binomial(n,k)^2*binomial(n+k,k)^2);
  # GP-Test  /* D-finite example 4 given in Manuel Kauers */ \
  # GP-Test  vector(20,n,   (n+1)^3                 *A005259(n) \
  # GP-Test               - (2*n+3)*(17*n^2+51*n+39)*A005259(n+1) \
  # GP-Test               + (n+2)^3                 *A005259(n+2)) == \
  # GP-Test  vector(20,n, 0)

  my @values;
  foreach my $order (0 .. 8) {
    my $graph = Graph::Maker->new('binomial_both',
                                  order => $order);
    # my $W = MyGraphs::Graph_Wiener_index($graph);
    my $W = $graph->diameter || 0;
    push @values, $W;
    print "$W,";
  }
  print "\n";
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}
{
  # BinomialBoth by order

  # order=0 https://hog.grinvin.org/ViewGraphInfo.action?id=1310  single vertex
  # order=1 https://hog.grinvin.org/ViewGraphInfo.action?id=19655  path-2
  # order=2 https://hog.grinvin.org/ViewGraphInfo.action?id=674   4-cycle
  # order=3 https://hog.grinvin.org/ViewGraphInfo.action?id=35455  4-cycles conn
  # order=4 https://hog.grinvin.org/ViewGraphInfo.action?id=35447
  # order=5 https://hog.grinvin.org/ViewGraphInfo.action?id=35449
  # order=6 https://hog.grinvin.org/ViewGraphInfo.action?id=35451
  # order=7 https://hog.grinvin.org/ViewGraphInfo.action?id=35453

  my @graphs;
  foreach my $order (0..3) {
    my $graph = Graph::Maker->new('binomial_both',
                                  order => $order,
                                  undirected => 1,
                                  direction_type => 'bigger',
                                 );
    # binomial_xy_hypercube($graph);
    # binomial_xy_flat($graph);
    binomial_xy_arithmetic($graph);
    print $graph->get_graph_attribute ('name'),"\n";
    push @graphs, $graph;
    if ($order==3) {
      # Could have spaced the two cycles a bit further apart actually ...
      MyGraphs::Graph_set_xy_points($graph,
                                    0 => [0,2],
                                    1 => [-1,1],
                                    2 => [1,1],
                                    3 => [0,0],

                                    4 => [3+0,2],
                                    5 => [3-1,1],
                                    6 => [3+1,1],
                                    7 => [3+0,0]);
    }
    # MyGraphs::Graph_view($graph);


  }
  MyGraphs::hog_upload_html($graphs[-1],
                            yscale => 1);
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # BinomialBoth properties
  #
  # edges
  # 0,1,4,10,22,46,94,190,382,766,1534,
  # A296953 bisymmetric order-preserving
  # 3*2^(n-1) - 2
  # A033484 same without initial 0
  #
  # intervals
  # 1,3,9,25,65,161,385,897,2049,4609,10241,
  # A002064 Cullen n*2^n + 1
  #
  # num maximal paths, start to end
  # 1,1,2,4,8,16,32,64,128,256,512
  #
  # complementary pairs
  # 0,1,2,10,50,226,962,3970,16130,65026,
  # 0 1 2  3
  # A092440 * 2
  # c(n) = if(n==0,0, (2^(n-1) - 1)^2 + 1)
  # vector(10,n,n--; c(n))
  # new is first half all except min,
  #      * second half all except max.
  #     plus min to max itself.

  my @graphs;
  foreach my $order (0 .. 10) {
    my $graph = Graph::Maker->new('binomial_both',
                                  order => $order);
    my $minmax = MyGraphs::Graph_lattice_minmax_hash($graph);
    # print scalar($graph->edges),",";
    # print MyGraphs::Graph_num_intervals($graph),",";
     print MyGraphs::Graph_num_maximal_paths($graph),",";
    # print MyGraphs::Graph_is_Hamiltonian($graph),",";
    # print MyGraphs::lattice_minmax_is_semidistributive($graph,$minmax),",";
    # print MyGraphs::lattice_minmax_num_complementary_pairs($graph,$minmax),",";
  }
  exit 0;
}


sub binomial_xy_hypercube {
  my ($graph) = @_;
  my $limit = max($graph->vertices);
  my $order = $limit==0 ? 0 : length(sprintf '%b', $limit);
  my $a = pi/2/($order-1);
  my @basis = map { [sin($_*$a), cos($_*$a)] } 0 .. $order-1;
  foreach my $n ($graph->vertices) {
    my $x = 0;
    my $y = 0;
    foreach my $i (0 .. $order-1) {
      if ($n & (1<<$i)) {
        ### add: "n=$n i=$i $basis[$i]->[0] $basis[$i]->[1]"
        $x += $basis[$i]->[0];
        $y += $basis[$i]->[1];
      }
    }
    MyGraphs::Graph_set_xy_points($graph, $n => [$x,$y]);
  }
}
sub binomial_xy_flat {
  my ($graph) = @_;
  MyGraphs::Graph_set_xy_points($graph, 0 => [0,0]);
  foreach my $i (0 .. $graph->vertices-1) {
    my ($parent) = $graph->predecessors($i);
    my ($x,$y) = MyGraphs::Graph_vertex_xy($graph,$parent);
    next unless defined $y;
    $y--;
    $x += ($i-$parent)>>1;
    ### set: "$i to $x,$y"
    MyGraphs::Graph_set_xy_points($graph, $i => [$x,$y]);
  }
}

sub _count_1bits {
  my ($n) = @_;
  my $ret = 0;
  while ($n) { $ret += $n&1; $n >>= 1; }
  return $ret;
}
sub binomial_xy_arithmetic {
  my ($graph) = @_;
  foreach my $i (0 .. scalar($graph->vertices)-1) {
    ### $i
    MyGraphs::Graph_set_xy_points($graph, $i => [$i>>1, - _count_1bits($i)]);

    # my $x = 0;
    # my $y = 0;
    # my $v = $i;
    # while ($v) {
    #   $v > 0 or die "$v";
    #   my $low1 = (($v ^ ($v-1)) + 1) >> 1;
    #   ### $v
    #   ### $low1
    #   $x += $low1 >> 1;
    #   $y--;
    #   $v -= $low1;
    # }
  }
}

{
  # Binomial Lattice
  # edges
  # vector(7,n, 3*2^n - 2)
  #
  # intervals n*2^n + 1
  # 9, 25, 65, 161, 385, 897

  require Graph;
  my @graphs;
  foreach my $k (2..7) {
    my $graph = Graph->new(undirected => 0);
    foreach my $n (0 .. (1<<$k)-1) {
      my $bit = 1;

      # hypercube
      # foreach (1 .. $k) {
      #   $graph->add_edge($n,  $n & $bit ? $n & ~$bit : $n | $bit);
      #   $bit <<= 1;
      # }

      $bit = 1;
      foreach (1 .. $k) {
        if ($n & $bit) {
          last;
        } else {
          $graph->add_edge($n,  $n | $bit);   # upwards
        }
        $bit <<= 1;
      }

      $bit = 1;
      foreach (1 .. $k) {
        if ($n & $bit) {
          $graph->add_edge($n & ~$bit,  $n);  # upwards
        } else {
          last;
        }
        $bit <<= 1;
      }
    }
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $num_intervals = MyGraphs::Graph_num_intervals($graph);
    print "$num_vertices vertices, $num_edges edges, $num_intervals intervals\n";
    # MyGraphs::Graph_view($graph);


    my $tree = Graph::Maker->new('binomial_tree',
                                 order => $k,
                                 undirected => 1);
    {
      my $num_vertices = $tree->vertices;
      my $num_edges = $tree->edges;
      print "  tree $num_vertices vertices $num_edges edges\n";
    }
    MyGraphs::Graph_is_subgraph($graph,$tree) or die;

    foreach my $edge ($tree->edges) {
      my ($from,$to) = @$edge;
      $tree->add_edge(2**$k-1 - $from, 2**$k-1 - $to);
    }
    MyGraphs::Graph_is_isomorphic($graph,$tree) or die "different";

    my $minmax = MyGraphs::Graph_lattice_minmax_hash($graph);
    my $str = MyGraphs::Graph_lattice_minmax_reason($graph,$minmax);
    if ($str) {
      print "  not a lattice: $str\n";
    }
    my $covers = MyGraphs::Graph_covers($graph);
    MyGraphs::Graph_is_isomorphic($graph,$covers) or die "not covers";

    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
