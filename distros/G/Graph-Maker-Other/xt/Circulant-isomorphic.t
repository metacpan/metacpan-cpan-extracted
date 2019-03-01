#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde
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

use lib 'devel/lib';
use MyGraphs;

use Graph::Maker::Circulant;

plan tests => 61;


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
  my %shown = ('N=6 1,2' => 226,
               'N=6 1,3' => 84,
               'N=6 2,3' => 746,
               'N=7 1,2' => 710,
               'N=8 1,2' => 160,
               'N=8 1,3' => 570,
               'N=8 1,2,3' => 176,
               'N=8 1,4' => 640,
               'N=8 2,4' => 116,
               'N=9 1,3' => 328,
               'N=9 1,2,4' => 370,
               'N=10 1,2' => 21063,
               'N=10 2,4' => 138,
               'N=10 1,2,4' => 21117,
               'N=10 1,2,3,4' => 148,
               'N=10 1,2,5' => 20611,
               'N=10 1,3,5' => 252,
               'N=10 1,2,3,5' => 142,
              );
  my $extras = 0;
  my %seen;
  foreach my $N (3 .. 11) {
    my $half = int($N/2);
    foreach my $offset_flags (0 .. (1<<$half)-1) {
      my @offset_list;
      foreach my $o (1 .. $half) {
        if ($offset_flags & (1<<($o-1))) {
          push @offset_list, $o;
        }
      }
      next if @offset_list < 2;
      next if @offset_list == $half;

      my $graph = Graph::Maker->new('circulant', undirected => 1,
                                    N => $N, offset_list => \@offset_list);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;
      my $key = "N=$N ".join(',',@offset_list);
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          my $num_edges = $graph->edges;
          MyTestHelpers::diag ("HOG $key not shown in POD, num edges $num_edges");
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
