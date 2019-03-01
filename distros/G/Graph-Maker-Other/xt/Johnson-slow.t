#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2019 Kevin Ryde
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

use Graph::Maker::Johnson;

use lib 'devel/lib';
use MyGraphs 'Graph_is_isomorphic','Graph_is_subgraph';

plan tests => 23;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = ('4,2' => 226,
               '5,2' => 21154,
              );
  my $extras = 0;
  my %seen;
  foreach my $N (3 .. 10) {
    foreach my $K (2 .. $N-2) {
      my $graph = Graph::Maker->new('Johnson', undirected => 1,
                                    N => $N, K => $K);
      my $key = "$N,$K";
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          MyTestHelpers::diag ("HOG got $key, not shown in POD");
          MyTestHelpers::diag ($g6_str);
          MyGraphs::Graph_view($graph);
          $extras++
        }
      }
    }
  }
  ok ($extras, 0);
}

#------------------------------------------------------------------------------

{
  require Graph::Maker::Petersen;
  my $petersen = Graph::Maker->new('Petersen', undirected=>1);
  my $johnson = Graph::Maker->new('Johnson', N=>5, K=>2, undirected=>1);
  my $complement = $johnson->complement;
  ok (Graph_is_isomorphic($petersen, $complement), 1);
}

{
  my @pairs;
  foreach my $i (1 .. 4) {
    foreach my $j ($i+1 .. 5) {
      push @pairs, [$i,$j];
    }
  }
  my $graph = Graph->new (undirected=>1);
  foreach my $p (@pairs) {
    $graph->add_vertex(join(',',@$p));
  }
  foreach my $i_from (0 .. $#pairs-1) {
    my $from = $pairs[$i_from];
    foreach my $i_to ($i_from+1 .. $#pairs) {
      my $to = $pairs[$i_to];

      my $count = Graph::Maker::Johnson::_sorted_arefs_count_same($from, $to);
      if ($count == 0) {
        my $v_from = join(',',@$from);
        my $v_to   = join(',',@$to);
        $graph->add_edge($v_from, $v_to);
      }
    }
  }

  require Graph::Maker::Petersen;
  my $petersen = Graph::Maker->new('Petersen', undirected=>1);
  ok (Graph_is_isomorphic($petersen, $graph), 1);
}

#------------------------------------------------------------------------------
# Johnson N,K and N,N-K are isomorphic

foreach my $N (1 .. 9) {
  foreach my $K (1 .. int($N/2)) {
    my $g1 = Graph::Maker->new('Johnson', N=>$N, K=>$K);
    my $g2 = Graph::Maker->new('Johnson', N=>$N, K=>$N-$K);
    ok (Graph_is_isomorphic($g1,$g2), 1);
  }
}


#------------------------------------------------------------------------------
exit 0;
