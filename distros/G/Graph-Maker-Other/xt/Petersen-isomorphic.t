#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019, 2021 Kevin Ryde
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

use Graph::Maker::Petersen;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 9;


#------------------------------------------------------------------------------

{
  # N=4,K=1 is cube graph

  require Graph::Maker::Hypercube;
  my $hypercube = Graph::Maker->new('hypercube', undirected => 1, N=>3);
  my $petersen  = Graph::Maker->new('Petersen',  undirected => 1, N=>4, K=>1);
  ok (MyGraphs::Graph_is_isomorphic($hypercube, $petersen));
  # MyGraphs::Graph_view($petersen);
  # MyGraphs::Graph_view($hypercube);
}

{
  # N=4,K=4 is Mobius Ladder 8 with 2 consecutive rungs removed

  my $petersen  = Graph::Maker->new('Petersen', undirected => 1, N=>4, K=>2);
  require Graph::Maker::Ladder;
  foreach my $pos (1 .. 4) {
    my $ladder = Graph::Maker->new('ladder', undirected => 1, rungs=>4);
    $ladder->add_edge(1,8);   # ends 1,5 and 4,8, cross wired
    $ladder->add_edge(5,4);

    $ladder->delete_edge($pos, $pos+4);
    my $next_pos = ($pos==4 ? 1 : $pos+1);
    $ladder->delete_edge($next_pos, $next_pos+4);
    ok (MyGraphs::Graph_is_isomorphic($ladder, $petersen));
  }
}

{
  # Petersen = 2-element subsets of 1 to 5 with edges between pairs both
  # different

  require Graph;
  my $graph = Graph->new(undirected => 1);

  require Algorithm::ChooseSubsets;
  my $it = Algorithm::ChooseSubsets->new(set=>[1..5], size=>2);
  my @vertices;
  while (my $aref = $it->next) {
    ### $aref
    push @vertices, $aref;
    $graph->add_vertex("$aref->[0],$aref->[1]");
  }

  foreach my $v1 (@vertices) {
    foreach my $v2 (@vertices) {
      if ($v1->[0] != $v2->[0]
          && $v1->[0] != $v2->[1]
          && $v1->[1] != $v2->[0]
          && $v1->[1] != $v2->[1]) {
        $graph->add_edge("$v1->[0],$v1->[1]", "$v2->[0],$v2->[1]");
      }
    }
  }
  my $petersen = Graph::Maker->new('Petersen', undirected => 1);

  ok (MyGraphs::Graph_is_isomorphic($graph, $petersen))
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','Petersen.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +N=(?<N>\d+), K=(?<K>\d+)/mg) {
      $count++;
      my $id = $+{'id'};
      my $N  = $+{'N'};
      my $K  = $+{'K'};
      $shown{"N=$N,K=$K"} = $+{'id'};
    }
    ok ($count, 21, 'HOG ID number of lines');
  }
  ok (scalar(keys %shown), 21);
  ### %shown

  # K=1 circular ladder not very relevant, limit those to N<=10
  # ENHANCE-ME: A few more at bigger N.
  #
  my $extras = 0;
  my %seen;
  foreach my $N (3 .. 15) {
    my $min_K = ($N<=10 ? 1 : 2);
    my $max_K = ($N+1)>>1;
    foreach my $K ($min_K .. $max_K) {
      my $graph = Graph::Maker->new('Petersen', undirected => 1,
                                    N => $N, K => $K);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;
      my $key = "N=$N,K=$K";
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          MyTestHelpers::diag ("HOG $key not shown in POD");
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
exit 0;
