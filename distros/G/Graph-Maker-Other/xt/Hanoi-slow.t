#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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

use Graph::Maker::Hanoi;

use lib 'devel/lib';
use MyGraphs 'Graph_is_isomorphic','Graph_is_subgraph';

plan tests => 62;

# uncomment this to run the ### lines
# use Smart::Comments;


sub Graph_is_edge_subset {
  my ($graph,$subgraph) = @_;
  my %seen;
  @seen{map { join('--',sort @$_) } $graph->edges} = ();  # hash slice
  ### %seen
  foreach my $edge ($subgraph->edges) {
    my $key = join('--',sort @$edge);
    if (! exists $seen{$key}) {
      print "missing $key\n";
      print "$graph\n";
      print "$subgraph\n";
      return 0;
    }
  }
  return 1;
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = ('2,3,any' => 1,
               '2,3,linear' => 1,
               '3,3,any' => 1,
               '2,4,any' => 1,
               '2,4,cyclic' => 1,
               '2,4,linear' => 1,
               '2,4,star' => 1,
              );
  my $extras = 0;
  my %seen;
  foreach my $discs (2 .. 4) {
    foreach my $spindles (3 .. 5) {
      foreach my $adjacency ("any", "cyclic", "linear", "star") {
        my $graph = Graph::Maker->new('hanoi', undirected => 1,
                                      discs => $discs,
                                      spindles => $spindles,
                                      adjacency => $adjacency);
        my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
        $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
        next if $seen{$g6_str}++;
        my $key = "$discs,$spindles,$adjacency";
        next if $shown{$key};
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
  }
  ok ($extras, 0);
}

#------------------------------------------------------------------------------

{
  # star discs=2 spindles=4

  #           22               sub-stars low digit
  #            |               
  #           20               edges between them
  #          /  \              changing high digit 0 <-> non-0
  #        23    21
  #         |    |
  #        03    01
  #       /  \  /  \
  #     13    00    31
  #      |     |     |
  #     10    02    30
  #    /  \  /  \  /  \
  #  11    12    32    33

  my $graph = Graph->new(undirected => 1);
  $graph->add_edges(['01', '21'],
                    ['20', '21'],
                    ['03', '23'],
                    ['00', '01'],
                    ['00', '02'],
                    ['02', '12'],
                    ['20', '23'],
                    ['00', '03'],
                    ['10', '12'],
                    ['30', '33'],
                    ['01', '31'],
                    ['03', '13'],
                    ['10', '11'],
                    ['30', '32'],
                    ['10', '13'],
                    ['20', '22'],
                    ['02', '32'],
                    ['30', '31']);

  my $star = Graph::Maker->new('hanoi',
                               discs => 2, spindles => 4,
                               adjacency => 'star',
                               undirected => 1,
                               vertex_names => 'digits');
  ok ($graph eq $star, 1);
}

#------------------------------------------------------------------------------

{
  # spindles<=2   any = cyclic = linear = star

  foreach my $discs (1 .. 5) {
    foreach my $spindles (1 .. 2) {
      my $any = Graph::Maker->new('hanoi',
                                  discs => $discs, spindles => $spindles,
                                  undirected => 1);
      my $cyclic = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'cyclic',
                                     undirected => 1);
      my $linear = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'linear',
                                     undirected => 1);
      my $star = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'star',
                                   undirected => 1);
      ok ($any eq $cyclic, 1);
      ok ($any eq $linear, 1);
      ok ($any eq $star, 1);
    }
  }
}

{
  # spindles=3 has any = cyclic > linear
  #                linear isomorphic star

  my $spindles = 3;
  foreach my $discs (1 .. 5) {
    my $any = Graph::Maker->new('hanoi',
                                discs => $discs, spindles => $spindles,
                                undirected => 1);
    my $cyclic = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'cyclic',
                                   undirected => 1);
    my $linear = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'linear',
                                   undirected => 1);
    my $star = Graph::Maker->new('hanoi',
                                 discs => $discs, spindles => $spindles,
                                 adjacency => 'star',
                                 undirected => 1);
    ok ($any eq $cyclic, 1);
    ok (Graph_is_edge_subset ($cyclic, $linear), 1);
    ok (Graph_is_isomorphic($linear, $star), 1);
  }
}

{
  # any >= cyclic >= linear

  foreach my $discs (1 .. 6) {
    foreach my $spindles (4 .. 6) {
      my $any = Graph::Maker->new('hanoi',
                                  discs => $discs, spindles => $spindles,
                                  undirected => 1);
      my $cyclic = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'cyclic',
                                     undirected => 1);
      my $linear = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'linear',
                                     undirected => 1);
      # my $ac = Graph_is_isomorphic($any, $cyclic)
      #   || Graph_is_subgraph($any, $cyclic)    ? 1 : 0;
      # my $cl = Graph_is_isomorphic($cyclic, $linear)
      #   || Graph_is_subgraph($cyclic, $linear) ? 1 : 0;
      my $ac = Graph_is_edge_subset ($any, $cyclic);
      my $cl = Graph_is_edge_subset ($cyclic, $linear);
      # print "$any\n";
      # print "$cyclic\n";

      ok ($cl, 1, "cyclic>=linear  discs=$discs spindles=$spindles");
      last if $any->edges >= 10_000;
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
