#!/usr/bin/perl -w

# Copyright 2019, 2022 Kevin Ryde
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
use FindBin;
use File::Slurp;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 38;

require Graph::Maker::FoldedHypercube;

# /m/graph/hypercube-folded
# A295921 Number of (not necessarily maximum) cliques in the n-folded cube graph.


#------------------------------------------------------------------------------
# Bipartite Double Graph

# cycle becomes bigger cycle, for odd N
foreach my $N (3,5,7,9) {
  my $folded = Graph::Maker->new('folded_hypercube', undirected => 1,
                                 N => $N);
  require Graph::Maker::Cycle;
  my $cycle = Graph::Maker->new('cycle', undirected => 1, N => $N);
  my $bigger_cycle = Graph::Maker->new('cycle', undirected => 1, N => 2*$N);
  my $double = MyGraphs::Graph_bipartite_double($cycle);
  ok (MyGraphs::Graph_is_isomorphic($double, $bigger_cycle), 1);
}

{
  # Complete-4 becomes Cube-3
  require Graph::Maker::Complete;
  my $complete = Graph::Maker->new('complete', undirected => 1, N => 4);
  my $double = MyGraphs::Graph_bipartite_double($complete);
  # MyGraphs::Graph_view($double);
  require Graph::Maker::Hypercube;
  my $hypercube = Graph::Maker->new('hypercube', undirected => 1, N => 3);
  ok (MyGraphs::Graph_is_isomorphic($double, $hypercube), 1);
}

# Folded Hypercube N becomes Hypercube N, for odd N
foreach my $N (3,5,7,9) {
  my $folded = Graph::Maker->new('folded_hypercube', undirected => 1,
                                 N => $N);
  require Graph::Maker::Hypercube;
  my $hypercube = Graph::Maker->new('hypercube', undirected => 1, N => $N);
  my $double = MyGraphs::Graph_bipartite_double($folded);
  # MyGraphs::Graph_view($double);
  ok (MyGraphs::Graph_is_isomorphic($double, $hypercube), 1,
      "N=$N");
}

{
  # Grid 4x4 becomes Folded Hypercube 6
  # http://www.win.tue.nl/~aeb/drg/graphs/Folded_6-cube.html
  # where "4x4 grid" means rook moves, so edges between all in rows,columns
  #
  require Graph::Maker::RookGrid;
  my $rook = Graph::Maker->new('rook_grid', undirected => 1, dims => [4,4]);
  my $double = MyGraphs::Graph_bipartite_double($rook);
  my $folded = Graph::Maker->new('folded_hypercube', undirected => 1,
                                 N => 6);
  # MyGraphs::Graph_view($double);
  # MyGraphs::Graph_view($folded);
  ok (MyGraphs::Graph_is_isomorphic($double, $folded), 1);
}

#------------------------------------------------------------------------------
# Cliques
#
# Clique number 2 means the cliques are an empty (1 of), each vertex a
# clique size 1, and each edge a clique size 2.
#
# That the clique number is only 2 is since two neighbours by flipping a
# single bit don't have an edge between (to make a triangle) as that would
# be 2 bits flipped.  For N=3, the all bits flip is 2 bits, but not
# otherwise.


# A295921
my @want_total_cliques = (2, 2, 4, 16, 25, 57, 129, 289);
# GP-DEFINE  num_cliques(n) = {
# GP-DEFINE    if(n <= 1, num_vertices(n) + 1,
# GP-DEFINE       n == 3, 16, \
# GP-DEFINE       num_vertices(n) + num_edges(n) + 1);
# GP-DEFINE  }
#  vector(8,n,n--;  num_cliques(n)) == [2, 2, 4, 16, 25, 57, 129, 289]
# vector(20,n,n--;  num_cliques(n))

# clique number = / 1     if N=0 or 1
#                 | 4     if N=3
#                 \ 2     otherwise
#               = 1, 1, 2, 4, 2, 2, 2, ...
# not in OEIS: 1,1,2,4,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
sub want_clique_number {
  my ($N) = @_;
  return ($N <= 1 ? 1
          : $N == 3 ? 4
          : 2);
}

my @want_indnum       = (1,1,1, 1,4, 5);
my @want_indnum_count = (1,1,2, 4,2,16);

foreach my $N (0 .. 8) {
  my $graph = Graph::Maker->new('folded_hypercube', undirected => 1,
                                N => $N);
  ok (MyGraphs::Graph_clique_number($graph), want_clique_number($N));

  if ($N <= 5) {
    my ($indnum,$count) = MyGraphs::Graph_indnum_and_count($graph);
    ok ($indnum, $want_indnum[$N]);
    ok ($count, $want_indnum_count[$N]);
  }
}


#------------------------------------------------------------------------------

{
  # Folded Cube 2 = Path 3
  my $folded = Graph::Maker->new('folded_hypercube', undirected => 1,
                                 N => 2);
  require Graph::Maker::Linear;
  my $path = Graph::Maker->new('linear', undirected => 1, N => 2);
  ok (MyGraphs::Graph_is_isomorphic($folded, $path), 1);
}
{
  # Folded Cube 3 = Complete 3
  my $folded = Graph::Maker->new('folded_hypercube', undirected => 1,
                                 N => 3);
  require Graph::Maker::Complete;
  my $complete = Graph::Maker->new('complete', undirected => 1, N => 4);
  ok (MyGraphs::Graph_is_isomorphic($folded, $complete), 1);
}
{
  # Folded Cube 4 = Complete Bipartite 4,4
  my $folded = Graph::Maker->new('folded_hypercube', undirected => 1,
                                 N => 4);
  require Graph::Maker::CompleteBipartite;
  my $bipartite = Graph::Maker->new('complete_bipartite', undirected => 1
                                    , N1 => 4, N2 => 4);
  ok (MyGraphs::Graph_is_isomorphic($folded, $bipartite), 1);
}
{
  # Folded Cube 5 = Clebsch = 16-Cyclotomic = Keller N=2
  my $folded = Graph::Maker->new('folded_hypercube', undirected => 1,
                                 N => 5);
  require Graph::Maker::Keller;
  my $clebsch = Graph::Maker->new('Keller', undirected => 1, N => 2);
  ok (MyGraphs::Graph_is_isomorphic($folded, $clebsch), 1);
}


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','FoldedHypercube.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +N=(?<N>[0-9, ]+)/mg) {
      $count++;
      my $id = $+{'id'};
      foreach my $N (split /[ ,]+/, $+{'N'}) {
        $shown{"N=$N"} = $+{'id'};
      }
    }
    ok ($count, 8, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 9);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  foreach my $N (0 .. 5) {
    my $graph = Graph::Maker->new('folded_hypercube', undirected => 1,
                                  N => $N);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    my $key = "N=$N";
    ### $key
    ### vertices: scalar $graph->vertices
    last if $graph->vertices > 255;
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
    } else {
      $others++;
      if (MyGraphs::hog_grep($g6_str)) {
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ("HOG $key not shown in POD");
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
