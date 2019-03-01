#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
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

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;



{
  # Pi Graph, or multigraph, decimal digits

  # Donald Knuth, MSRI lecture "The Birth of the Giant Component", 1 Oct 2004.
  # http://archive.org/details/lecture12091/
  #
  # Slide at 13:02 in video bit hard to see, and the matrix has a couple of
  # extras over the drawing, or some such.

  # digits of pi, starting from 3
  # 3 - 1
  # 4 - 1
  # first cycle after 8, with 8 edges
  # connected after 17, with 15 edges
  # 31 41 59 26 53 58 97 93 23 84 62 64 33 83 27 95 02
  # dup 26, 62
  # dup 59, 95
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32206
  #    connected

  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new(anum => 'A000796');  # pi in decimal
  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_vertices(0 .. 9);
  my $seen_cyclic;
  my $seen_connected;
  my $seen_degrees = 1;
  my $pairnum = 0;
  my @graphs;
  for (;;) {
    my ($i,$u) = $seq->next or last;
    my (undef,$v) = $seq->next or last;
    $pairnum++;
    if ($pairnum <= 20 && $graph->has_edge($u,$v)) {
      print "pairnum=$pairnum duplicate $u-$v\n";
    }
    $graph->add_edge($u,$v);

    if (!$seen_cyclic && $graph->is_cyclic) {
      my $graph = $graph->copy;
      $graph->set_graph_attribute (name => "$pairnum pairs, cyclic");
      my $num_edges = $graph->edges;

      print "$pairnum pairs (i=$i), cyclic, $num_edges edges\n";
      $seen_cyclic = 1;
      # MyGraphs::Graph_view($graph);
      push @graphs, $graph;
    }

    if (!$seen_connected && $graph->is_connected) {
      my $graph = $graph->copy;
      $graph->set_graph_attribute (name => "$pairnum pairs, connected");
      my $num_edges = $graph->edges;

      print "$pairnum pairs (i=$i), connected, $num_edges edges\n";
      $seen_connected = 1;
      MyGraphs::Graph_view($graph);
      # MyGraphs::Graph_print_tikz($graph);

      $pairnum == 17 or die;
      $num_edges == 15 or die;
      push @graphs, $graph;
    }

    if (!$seen_degrees && Graph_is_all_different_degrees($graph)) {
      $seen_degrees = 1;
      my $num_edges = $graph->edges;
      print "$pairnum pairs (i=$i), distinct degrees, $num_edges edges, degrees: ",
        join(',',map{$graph->degree($_)}0..9),"\n";
      MyGraphs::Graph_view($graph);
    }
  }
  my $num_components = $graph->connected_components;
  print "num components $num_components\n";

  print "final degrees: ",join(',',map{$graph->degree($_)}0..9),"\n";
  MyGraphs::hog_searches_html(@graphs);
  exit 0;

  sub Graph_is_all_different_degrees {
    my ($graph) = @_;
    my %seen;
    foreach my $v ($graph->vertices) {
      if ($seen{$graph->degree($v)}++) { return 0; }
    }
    return 1;
  }
}
{
  # Pi Graph, or multigraph, decimal digit pairs

  # Donald Knuth, MSRI lecture "The Birth of the Giant Component", 1 Oct 2004.
  # http://archive.org/details/lecture12091/

  # pairs of digits of pi
  # 14 - 15,
  # 92 - 65
  # first cycle after 46 of
  # first bi-cycle after 64
  # first connected after 198 pairs, which is 195 edges
  #
  # Erdos and Renyi, late 50s, random graphs ...
  # usually one component and isolated vertices, which are swallowed
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32198
  #    first cycle
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32200
  #    bi-cyclic
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32202
  #    100 steps
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32204
  #    connected

  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new(anum => 'A000796');  # pi in decimal
  {
    # skip 3
    my ($i,$value) = $seq->next;
    $i     == 1 or die;
    $value == 3 or die;
  }
  require Graph;
  my $graph = Graph->new(undirected => 1);
  foreach my $u (0..9) {
    foreach my $v (0..9) {
      $graph->add_vertex("$u$v");
    }
  }
  my $seen_cyclic;
  my $seen_twocycles;
  my $seen_bicyclic;
  my $seen_connected;
  my $pairnum = 0;
  my @graphs;
  for ( ; $pairnum < 200; ) {
    my ($i,   $u1) = $seq->next or last;
    my (undef,$u2) = $seq->next or last;
    my (undef,$v1) = $seq->next or last;
    my (undef,$v2) = $seq->next or last;
    my $u = "$u1$u2";
    my $v = "$v1$v2";
    $pairnum++;
    $graph->add_edge($u,$v);

    if ($i <= 10) {
      print "i=$i pairnum $pairnum, edge $u-$v\n";
      foreach my $cycle (MyGraphs::Graph_find_all_cycles($graph)) {
        print "  cycle ",join(',',@$cycle),"\n";
      }
    }

    if (!$seen_cyclic && $graph->is_cyclic) {
      $seen_cyclic = 1;
      my $graph = $graph->copy;
      $graph->set_graph_attribute (name => "$pairnum pairs, first cycle");
      my $num_edges = $graph->edges;

      $pairnum == 46 or die;
      $num_edges == 46 or die;     # all distinct

      print "$pairnum pairs (i=$i), cyclic, $num_edges edges, this edge $u-$v\n";
      foreach my $cycle (MyGraphs::Graph_find_all_cycles($graph)) {
        print "  cycle ",join(',',@$cycle),"\n";
      }
      my @components = $graph->connected_components;
      print "  component sizes ",
        join(',',sort {$b<=>$a} map{scalar(@$_)}@components),"\n";

      foreach my $component (@components) {
        if (@$component == 10) {
          # size=10 component is the cycle
          my $subgraph = $graph->subgraph($component);
          # MyGraphs::Graph_view($subgraph);
        }
        if (@$component == 13) {
          # size=13 tree
          # Knuth: "looks like a plus or minus sign"
          #
          #               80
          #                |
          #               86
          #                |
          #       03--48--28--62
          #                |
          #               84
          #                |
          #   11--17--21--10--58--22
          #
          my $subgraph = $graph->subgraph($component);
          # MyGraphs::Graph_view($subgraph);
        }
        if (@$component == 4) {
          # size=4 two of, one path-4, one star-4 = claw
          my $subgraph = $graph->subgraph($component);
          # MyGraphs::Graph_view($subgraph);
        }
      }

      # MyGraphs::Graph_view($graph);
      push @graphs, $graph;
      print "\n";
    }

    if (!$seen_twocycles && MyGraphs::Graph_num_cycles($graph)>=2) {
      $seen_twocycles = 1;
      my $graph = $graph->copy;
      $graph->set_graph_attribute (name => "$pairnum pairs, two cycles");
      my $num_edges = $graph->edges;

      print "$pairnum pairs (i=$i), two cycles, $num_edges edges, this edge $u-$v\n";
      foreach my $cycle (MyGraphs::Graph_find_all_cycles($graph)) {
        print "  cycle ",join(',',@$cycle),"\n";
      }
      # MyGraphs::Graph_view($graph);

      $pairnum == 56 or die;
      $num_edges == 56 or die;     # all distinct
      $graph->is_cyclic or die;
      push @graphs, $graph;
      print "\n";
    }

    if (!$seen_bicyclic && MyGraphs::Graph_has_bicyclic_component($graph)) {
      $seen_bicyclic = 1;
      my $graph = $graph->copy;
      $graph->set_graph_attribute (name => "$pairnum pairs, bi-cyclic");
      my $num_edges = $graph->edges;

      print "$pairnum pairs (i=$i), bicyclic, $num_edges edges, this edge $u-$v\n";
      foreach my $cycle (MyGraphs::Graph_find_all_cycles($graph)) {
        print "  cycle ",join(',',@$cycle),"\n";
      }
      my @components = $graph->connected_components;
      my @component_sizes = map {scalar(@$_)} @components;
      print "  component sizes ",join(',',sort {$b<=>$a} @component_sizes),"\n";
      grep {$_==6} @component_sizes or die;

      foreach my $component (@components) {
        if (@$component == 78) {
          my $subgraph = $graph->subgraph($component);
          $graph->edges == 96 or die;
        }
      }

      $pairnum == 64 or die;
      $num_edges == 64 or die;    # all distinct
      $graph->is_cyclic or die;
      push @graphs, $graph;
      print "\n";
    }

    if ($pairnum==100) {
      my $graph = $graph->copy;
      $graph->set_graph_attribute (name => "$pairnum pairs");
      my $num_edges = $graph->edges;

      print "$pairnum pairs (i=$i),  $num_edges edges\n";
      my @components = $graph->connected_components;
      my @component_sizes = map {scalar(@$_)} @components;
      print "  component sizes ",join(',',sort {$b<=>$a} @component_sizes),"\n";

      $num_edges == 99 or die;    # 1 repeat distinct
      grep {$_==78} @component_sizes or die;
      push @graphs, $graph;
    }

    if (!$seen_connected && $graph->is_connected) {
      $seen_connected = 1;
      my $graph = $graph->copy;
      $graph->set_graph_attribute (name => "$pairnum pairs, connected");
      my $num_edges = $graph->edges;

      print "$pairnum pairs (i=$i), connected, $num_edges edges\n";
      # MyGraphs::Graph_view($graph);

      $pairnum == 198 or die;
      $num_edges == 195 or die;    # all distinct
      push @graphs, $graph;
    }
  }
  my $num_components = $graph->connected_components;
  print "num components $num_components\n";

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}



