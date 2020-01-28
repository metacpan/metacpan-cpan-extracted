#!/usr/bin/perl -w

# Copyright 2015, 2017, 2019, 2020 Kevin Ryde
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

# uncomment this to run the ### lines
use Smart::Comments;

{
  # BinomialBoth by order

  # order=0 https://hog.grinvin.org/ViewGraphInfo.action?id=1310  single vertex
  # order=1 https://hog.grinvin.org/ViewGraphInfo.action?id=19655  path-2
  # order=3 https://hog.grinvin.org/ViewGraphInfo.action?id=674   4-cycle
  # order=4
  # order=5
  # order=6
  # order=7

  my @graphs;
  foreach my $order (4) {
    my $graph = Graph::Maker->new('binomial_both',
                                  order => $order,
                                  undirected => 0,
                                  direction_type => 'bigger',
                                 );
    # binomial_xy_hypercube($graph);
    # binomial_xy_flat($graph);
    binomial_xy_arithmetic($graph);
    print $graph->get_graph_attribute ('name'),"\n";
    push @graphs, $graph;
    if ($order==3) {
    }
      MyGraphs::Graph_view($graph);
      MyGraphs::hog_upload_html($graph);
  }
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
