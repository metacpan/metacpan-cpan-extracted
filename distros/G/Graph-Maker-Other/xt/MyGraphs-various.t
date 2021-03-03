#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2021 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs 'make_tree_iterator_edge_aref','edge_aref_to_Graph',
  'Graph_tree_domnum',
  'Graph_is_domset',         'Graph_tree_domsets_count',
  'Graph_is_minimal_domset', 'Graph_tree_minimal_domsets_count';

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 102;


#------------------------------------------------------------------------------
# Graph_num_maximal_paths()

{
  my $graph = Graph->new;
  $graph->add_edges([1,2],
                    [3,4]);
  ok (MyGraphs::Graph_num_maximal_paths($graph), 2);
}


#------------------------------------------------------------------------------
# Lattices

{
  my $graph = Graph->new;
  $graph->add_edges(['L', 'A'],
                    ['L', 'B'],
                    ['A', 'H'],
                    ['B', 'H']);
  my $href = MyGraphs::Graph_lattice_minmax_hash($graph);
  foreach my $x ($graph->vertices) {
    ok ($href->{'max'}->{$x}->{$x}, $x);
    ok ($href->{'min'}->{$x}->{$x}, $x);

    foreach my $y ($graph->vertices) {
      ok (defined $href->{'max'}->{$x}->{$y}, 1);
      ok (defined $href->{'min'}->{$x}->{$y}, 1);
    }
  }
  ok ($href->{'max'}->{'A'}->{'B'}, 'H');
  ok ($href->{'min'}->{'A'}->{'B'}, 'L');
  ok ($href->{'min'}->{'B'}->{'A'}, 'L');

  ### $href
  MyGraphs::Graph_lattice_minmax_validate($graph,$href);
}


#------------------------------------------------------------------------------
# Graph_all_cycles()

{
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(1,2,3,4);
  $graph->add_cycle(5,6,7,8);
  {
    my @cycles = MyGraphs::Graph_find_all_cycles($graph);
    @cycles = sort map {join(',',@$_)} @cycles;
    ok (join(' ',@cycles), '1,2,3,4 5,6,7,8');
  }
  $graph->add_edge(1,5);
  {
    my @cycles = MyGraphs::Graph_find_all_cycles($graph);
    @cycles = sort map {join(',',@$_)} @cycles;
    ok (join(' ',@cycles), '1,2,3,4 5,6,7,8');
  }
}
{
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(1,2,3,4);
  $graph->add_cycle(4,5,6,7);
  my @cycles = MyGraphs::Graph_find_all_cycles($graph);
  @cycles = sort map {join(',',@$_)} @cycles;
  ok (join(' ',@cycles), '1,2,3,4 4,5,6,7');
}


#------------------------------------------------------------------------------
### Graph_tree_minimal_domsets_count() of all trees ...

{
  my $count = 0;
  my $bad = 0;
 NUM_VERTICES: foreach my $num_vertices (0 .. 7) {
    my $iterator_func = make_tree_iterator_edge_aref
      (num_vertices => $num_vertices);

    while (my $edge_aref = $iterator_func->()) {
      my $graph = edge_aref_to_Graph($edge_aref);
      my $by_prods = Graph_tree_minimal_domsets_count($graph);
      my $by_pred = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);

      $count++;
      if ($by_prods != $by_pred) {
        last NUM_VERTICES if ++$bad > 10;
      }
    }
  }
  MyTestHelpers::diag("minimal_domsets_count tests $count");
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
### Graph_is_hanging_cycle() ...

{
  my $graph = Graph->new (undirected => 1);
  $graph->add_path (1,2,3,4,5,3,6);
  ok (MyGraphs::Graph_is_hanging_cycle($graph,1), undef);
  my $aref = MyGraphs::Graph_is_hanging_cycle($graph,4);
  if ($aref) { @$aref = sort {$a<=>$b} @$aref; }
  ok (join(',',@$aref), '4,5');

  MyGraphs::Graph_delete_hanging_cycles($graph);
  ok ("$graph", "1=2,2=3,3=6");
}

#------------------------------------------------------------------------------
### Graph_tree_domnum_count() of path ...

{
  require Graph::Maker::Linear;
  foreach my $n (1 .. 10) {
    my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);
    if ($n) { $graph->add_vertex(1); }  # bug in Graph::Maker on N=0
    my $by_tree    = Graph_tree_domnum($graph);
    my $by_formula = int(($n+2) / 3);
    ok ($by_tree, $by_formula, "path $n domnum  tree=$by_tree formula=$by_formula");
  }
}

#------------------------------------------------------------------------------
### Graph_tree_minimal_domsets_count() of path ...

{
  require Graph::Maker::Linear;
  foreach my $n (1 .. 10) {
    my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);
    if ($n) { $graph->add_vertex(1); }  # bug in Graph::Maker on N=0
    my $by_prods = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    my $by_pred = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
    ok ($by_prods, $by_pred, "path $n minimal_domsets_count");
  }
}

#------------------------------------------------------------------------------
### Graph_tree_domsets_count() of all trees ...

{
  my $count = 0;
  my $bad = 0;
 NUM_VERTICES: foreach my $num_vertices (0 .. 7) {
    my $iterator_func = make_tree_iterator_edge_aref
      (num_vertices => $num_vertices);

    while (my $edge_aref = $iterator_func->()) {
      my $graph = edge_aref_to_Graph($edge_aref);
      my $by_prods = Graph_tree_domsets_count($graph);

      my $by_pred = 0;
      my @vertices = sort $graph->vertices;
      my $it = Algorithm::ChooseSubsets->new(\@vertices);
      while (my $aref = $it->next) {
        if (Graph_is_domset($graph,$aref)) {
          $by_pred++;
        }
      }

      $count++;
      if ($by_prods != $by_pred) {
        last NUM_VERTICES if ++$bad > 10;
      }
    }
  }
  MyTestHelpers::diag("domsets_count tests $count");
  ok ($bad, 0);
}


#------------------------------------------------------------------------------
### Graph_terminal_Wiener_index() of star ...

# formula in Gutman,Furtula,Petrovic
require Graph::Maker::Star;
foreach my $n (1 .. 15) {
  my $graph = Graph::Maker->new('star', N => $n, undirected => 1);
  my $got = MyGraphs::Graph_terminal_Wiener_index($graph);
  # n<3 is a path
  my $want = ($n<3 ? $n-1 : ($n-1)*($n-2));
  ok ($got, $want, "star n=$n got $got want $want");
}

### Graph_terminal_Wiener_index() of path ...

# formula in Gutman,Furtula,Petrovic
require Graph::Maker::Linear;
foreach my $n (1 .. 15) {
  my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);
  my $got = MyGraphs::Graph_terminal_Wiener_index($graph);
  my $want = $n-1;
  ok ($got, $want, "linear n=$n got $got want $want");
}

#------------------------------------------------------------------------------
exit 0;
