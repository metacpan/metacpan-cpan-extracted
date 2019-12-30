#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
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
use File::Spec;
use File::Slurp;
use FindBin;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use lib File::Spec->catdir('devel','lib');
use MyGraphs;

use Graph::Maker::Circulant;

plan tests => 67;


sub make_Mobius_ladder {
  my %args = @_;
  require Graph::Maker::Ladder;
  my $rungs = $args{'rungs'};
  my $ladder = Graph::Maker->new('ladder', %args);
  $ladder->add_edge(1,2*$rungs);
  $ladder->add_edge($rungs,$rungs+1);
  return $ladder;
}

#------------------------------------------------------------------------------
# Circulant N=7 1,2,3 = Fano plane = 7,3 Symmetric Configurations

{
  #              5
  #           /  |  \
  #          /   |   \
  #         6 _  |  _ 4
  #        /    _7_    \
  #       / __-- | --__ \
  #      1 ----- 2 ----- 3
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=19174
  #   Fano plane with middle cycle
  #   Unique triangulation with 7 vertices.
  #   3 separating triangles and minimal Hamiltonian cycles.
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=58
  #   Cycles.
  #   Circulant N=7 1,2,3

  my @graphs;
  my @lines = ([1,2,3],
               [3,4,5],
               [5,6,1],

               [1,7,4],
               [3,7,6],
               [5,7,2],
               [2,4,6]);
  foreach my $method ('add_path','add_cycle') {
    my $graph = Graph->new (undirected => 1);
    $graph->set_vertex_attribute(1, x => 0);
    $graph->set_vertex_attribute(1, y => 0);
    $graph->set_vertex_attribute(2, x => 2);
    $graph->set_vertex_attribute(2, y => .1);
    $graph->set_vertex_attribute(3, x => 4);
    $graph->set_vertex_attribute(3, y => 0);
    $graph->set_vertex_attribute(4, x => 2.9);
    $graph->set_vertex_attribute(4, y => .9);
    $graph->set_vertex_attribute(5, x => 2);
    $graph->set_vertex_attribute(5, y => 2);
    $graph->set_vertex_attribute(6, x => 1.1);
    $graph->set_vertex_attribute(6, y => .9);
    $graph->set_vertex_attribute(7, x => 2.1);
    $graph->set_vertex_attribute(7, y => .53);

    $graph->set_graph_attribute (name => "Fano 7,3 Configuration $method");
    foreach my $line (@lines) {
      $graph->$method (@$line);
    }
    push @graphs, $graph;

    my @vertices = sort $graph->vertices;
    my @degrees = map {$graph->degree($_)} @vertices;
    print '# ', join(',',@degrees), "\n";
  }

  # This path form with geometric sides and crosses.
  # Omitting different combinations of 1 edge each cycle gives 16 different.
  my $paths  = $graphs[0];
  # MyGraphs::Graph_view($paths);
  # MyGraphs::Graph_run_dreadnaut($paths);

  my $cycles = $graphs[1];
  # MyGraphs::Graph_view($cycles);
  {
    my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                  N => 7, offset_list => [1,2,3]);
    ok (MyGraphs::Graph_is_isomorphic($cycles, $circulant), 1,
        'Fano plane cycles = circulant N=7 1,2,3');
  }
  my $cycles_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($cycles));
  ok (MyGraphs::hog_grep($cycles_g6), 58);

  # middle cycle
  my $middle = $paths->copy;
  $middle->set_graph_attribute (name => "Fano Plane middle cycle");
  ok (! $middle->has_edge(2,6));
  $middle->add_edge(2,6);
  my $middle_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($middle));
  ok (MyGraphs::hog_grep($middle_g6), 19174);

  # No, 7 as paths is not transitive this way.
  # foreach my $line (@lines) {
  #   my $other = $paths->copy;
  #   $other->add_cycle(@$line);
  #   ok (MyGraphs::Graph_is_isomorphic($middle, $other),
  #       'Fano plane any one line as cycle is the same');
  # }

  # {
  #   my $graph = Graph->new (undirected => 1);
  #   $graph->set_graph_attribute (name => "Fano 7,3 Symmetric Incidence");
  #   foreach my $i (0 .. $#lines) {
  #     foreach my $v (@{$lines[$i]}) {
  #       $graph->add_edge ($v, "L$i");
  #     }
  #   }
  #   print "incidence ",MyGraphs::Graph_is_configuration_incidence($graph),"\n";
  #   push @graphs, $graph;
  # }
}

#------------------------------------------------------------------------------

{
  # Circulant-6 1,3 = Complete Bipartite 3,3
  my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                    N => 6, offset_list => [1,3]);
  require Graph::Maker::CompleteBipartite;
  my $bipartite = Graph::Maker->new('complete_bipartite', undirected => 1
                                    , N1 => 3, N2 => 3);
  ok (MyGraphs::Graph_is_isomorphic($circulant, $bipartite));
}

{
  # Circulant-6 2,3 = Rook Grid 3x2, per POD

  my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                    N => 6, offset_list => [2,3]);

  require Graph::Maker::RookGrid;
  my $rook = Graph::Maker->new('rook_grid', undirected => 1, dims => [3,2]);
  ok (MyGraphs::Graph_is_isomorphic($rook, $circulant));
  ok ($circulant->ne($rook));
  ok ($circulant->ne(Graph::Maker->new('rook_grid',undirected=>1,dims=>[2,3])));

  require Graph::Maker::CircularLadder;
  my $circular_ladder = Graph::Maker->new('circular_ladder', undirected => 1,
                                          rungs => 3);
  ok (MyGraphs::Graph_is_isomorphic($circular_ladder, $circulant));
  ok (MyGraphs::Graph_is_isomorphic($circular_ladder, $rook));

  # != Mobius Ladder 3 Rungs
  my $mobius_ladder = make_Mobius_ladder(undirected => 1, rungs=>3);
  ok (! MyGraphs::Graph_is_isomorphic($mobius_ladder, $circulant));
  ok (! MyGraphs::Graph_is_isomorphic($mobius_ladder, $rook));
  ok (! MyGraphs::Graph_is_isomorphic($mobius_ladder, $circular_ladder));
}

{
  # Circulant-8 3,4,5
  # = Circulant-8 1,4,7
  # = Mobius Ladder 8

  my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                    N => 8, offset_list => [3,4,5]);
  {
    my $other = Graph::Maker->new('circulant', undirected => 1,
                                  N => 8, offset_list => [1,4,7]);
    ok (MyGraphs::Graph_is_isomorphic($circulant, $other));
  }
  {
    my $ladder = make_Mobius_ladder(undirected => 1, rungs=>4);
    ok (MyGraphs::Graph_is_isomorphic($circulant, $ladder));
  }

  {
    # only 3-equivalence for 1,4,7 is 3,4,5
    my %expect = ('1,4,7' => 1,
                  '3,4,5' => 1);
    foreach my $a (1 .. 7) {
      foreach my $b ($a+1 .. 7) {
        foreach my $c ($b+1 .. 7) {
          my $other = Graph::Maker->new('circulant', undirected => 1,
                                        N => 8, offset_list => [$a,$b,$c]);
          my $key ="$a,$b,$c";
          my $got = MyGraphs::Graph_is_isomorphic($circulant, $other) ? 1 : 0;
          my $want = $expect{$key} ? 1 : 0;
          ok ($got, $want);
        }
      }
    }
  }
  {
    # only 2-equivalence for 1,4,7 are 1,4 and 
    my %expect = ('1,4' => 1,
                  '3,4' => 1);
    foreach my $a (1 .. 4) {
      foreach my $b ($a+1 .. 4) {
        my $other = Graph::Maker->new('circulant', undirected => 1,
                                      N => 8, offset_list => [$a,$b]);
        my $key ="$a,$b";
        my $got = MyGraphs::Graph_is_isomorphic($circulant, $other) ? 1 : 0;
        my $want = $expect{$key} ? 1 : 0;
        ok ($got, $want, $key);
      }
    }
  }
}
{
  # Circulant-8 1,4 = Circulant-8 3,4
  my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                    N => 8, offset_list => [1,4]);
  my $other = Graph::Maker->new('circulant', undirected => 1,
                                N => 8, offset_list => [3,4]);
  ok (MyGraphs::Graph_is_isomorphic($circulant, $other));
}

{
  # Circulant-8 1,4 = Circulant-8 3,4
  my $circulant = Graph::Maker->new('circulant', undirected => 1,
                                    N => 8, offset_list => [1,4]);
  my $other = Graph::Maker->new('circulant', undirected => 1,
                                N => 8, offset_list => [3,4]);
  ok (MyGraphs::Graph_is_isomorphic($circulant, $other));
}

{
  # Complement Circulant-8 3,4 = Circulant-8 1,2
  my $complement = Graph::Maker->new('circulant', undirected => 1,
                                     N => 8, offset_list => [3,4])
    ->complement;

  # equivalences
  my %expect = ('1,2' => 1,
                '2,3' => 1);
  foreach my $a (1 .. 4) {
    foreach my $b ($a+1 .. 4) {
      my $other = Graph::Maker->new('circulant', undirected => 1,
                                    N => 8, offset_list => [$a,$b]);
      my $key ="$a,$b";
      my $got = MyGraphs::Graph_is_isomorphic($complement, $other) ? 1 : 0;
      my $want = $expect{$key} ? 1 : 0;
      ok ($got, $want, "complement $key");
    }
  }
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','Circulant.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $rel_type;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +N=(?<N>\d+) +(?<list>[0-9,]+)/mg) {
      $count++;
      my $id   = $+{'id'};
      my $N    = $+{'N'};
      my $list = $+{'list'};
      $shown{"N=$N $list"} = $+{'id'};
    }
    ok ($count, 30, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 30);
  ### %shown

  #     1           2,3 but not all of
  #  5     2
  #   4   3
  
  #     1           2,3 but not all of
  #  4     2
  #     3
  
  require Algorithm::ChooseSubsets;
  my $extras = 0;
  my %seen;

  # FIXME: Many N=12 not yet shown in the POD ...
  foreach my $N (3 .. 11, 13 .. 19) {
    my $half = int($N/2);
    my @possible_offsets = (1 .. $half);
    my $it = Algorithm::ChooseSubsets->new(\@possible_offsets);
    while (my $offset_list = $it->next) {
      # if ($N==7) {
      #   printf "half=%d offset_list %s\n", $half, join(',',@$offset_list);
      # }
      next if @$offset_list <= 1; # not cycle
      my $graph = Graph::Maker->new('circulant', undirected => 1,
                                    N => $N,
                                    offset_list => $offset_list);
      my $max_edges = $N*($N-1)/2;
      next if $graph->edges == $max_edges;  # not complete

      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;
      my $key = "N=$N ".join(',',@$offset_list);
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          my $num_edges = $graph->edges;
          MyTestHelpers::diag ("HOG $key not shown in POD, num edges $num_edges (out of $max_edges)");
          MyTestHelpers::diag ($g6_str);
          #          MyGraphs::Graph_view($graph);
          $extras++
        }
      }
    }
  }
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
