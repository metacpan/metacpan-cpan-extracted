#!/usr/bin/perl -w

# Copyright 2022 Kevin Ryde
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
use List::Util 'sum';
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

plan tests => 63;

require Graph::Maker::HalvedHypercube;


#------------------------------------------------------------------------------
# Helpers

sub hammingweight {
  my ($n) = @_;
  my $ret = 0;
  while ($n) { $ret += $n&1; $n>>=1; }
  return $ret;
}   
ok (hammingweight(0), 0);
ok (hammingweight(12), 2);
ok (hammingweight(32), 1);


#------------------------------------------------------------------------------
# Halved N=3, is Complete-4 (square and diagonals)

{
  my $N = 3;
  my $halved = Graph::Maker->new('halved_hypercube',
                                 undirected => 1,
                                 N => $N);
  ok (scalar($halved->vertices), 4);
  ok (scalar($halved->edges), 6);

  require Graph::Maker::Complete;
  my $complete = Graph::Maker->new('complete',
                                  N => 4,
                                  undirected => 1);
  ok (scalar($complete->vertices), 4);
  ok (scalar($complete->edges), 6);

  ok (MyGraphs::Graph_is_isomorphic($halved, $complete), 1,
      "HalvedHypercube vs Complete-4");
}


#------------------------------------------------------------------------------
# Halved N=4, is Circulant N=8 1,2,3

{
  my $N = 4;
  my $halved = Graph::Maker->new('halved_hypercube',
                                 undirected => 1,
                                 N => $N);
  # $halved = halved_hypercube_by_flips($N);
  ok (scalar($halved->vertices), 8);
  ok (scalar($halved->edges), 24);

  require Graph::Maker::Circulant;
  my $sixteen = Graph::Maker->new('circulant',
                                  N => 8,
                                  offset_list =>[ 1,2,3],
                                  undirected => 1);
  ok (scalar($sixteen->vertices), 8);
  ok (scalar($sixteen->edges), 24);

  ok (MyGraphs::Graph_is_isomorphic($halved, $sixteen), 1,
      "HalvedHypercube vs Circulant sixteen cell");
}


#------------------------------------------------------------------------------
# Halved N=5 is Clebsch complement

{
  my $N = 5;
  my $halved = Graph::Maker->new('halved_hypercube',
                                 undirected => 1,
                                 N => $N);
  # $halved = halved_hypercube_by_flips($N);
  ok (scalar($halved->vertices), 16);
  ok (scalar($halved->edges), 80);

  require Graph::Maker::Keller;
  my $clebsch = Graph::Maker->new('Keller', undirected => 1, N => 2);
  my $clebsch_complement = $clebsch->complement;
  ok (scalar($clebsch_complement->vertices), 16);
  ok (scalar($clebsch_complement->edges), 80);

  ok (MyGraphs::Graph_is_isomorphic($halved, $clebsch_complement), 1,
        "HalvedHypercube vs Keller Clebsch complement");

  # MyGraphs::Graph_view($halved);
  # MyGraphs::Graph_view($clebsch_complement);
}


#------------------------------------------------------------------------------
# Various Equivalents

sub make_halved_hypercube_by_gmaker {
  my ($N) = @_;
  return Graph::Maker->new('halved_hypercube',
                           undirected => 1,
                           N => $N);
}

sub make_halved_hypercube_by_flips {
  my ($N) = @_;

  # Vertices are even 1s bit strings.
  # Edges between those differing exactly 2 places.
  #
  my @vertices = grep {(hammingweight($_)&1)==0}
    0 .. (1<<$N)-1;
  my $graph = Graph->new (vertices => \@vertices,
                          undirected => 1);
  foreach my $u (@vertices) {
    foreach my $v (@vertices) {
      if (hammingweight($u ^ $v) == 2) {
        # printf "%0*b\n", $N, $u;
        # printf "%0*b\n\n", $N, $v;
        $graph->add_edge($u,$v);
      }
    }
  }
  return $graph;
}

sub make_halved_hypercube_by_halve {
  my ($N) = @_;
  my $graph = Graph::Maker->new('hypercube',
                                    undirected => 1,
                                    N => $N);
  MyGraphs::Graph_distance_n ($graph, 2);
  return map { MyGraphs::Graph_induced_subgraph($graph,$_) }
    $graph->connected_components;
}

# A005864
my @want_indnum = (undef,
                   1,1,1,2,2,4,8,16,20,40,72,144);

# A288943
my @want_indsets_count = (undef,
                          2,3,5,13,57,889,104929,469095585);

foreach my $N (1..8) {
  my @graphs = (make_halved_hypercube_by_flips($N),
                make_halved_hypercube_by_gmaker($N),
                make_halved_hypercube_by_halve($N),
               );
  ok (scalar(@graphs), 4);
  foreach my $i (0 .. $#graphs-1) {
    ok (MyGraphs::Graph_is_isomorphic($graphs[$i], $graphs[$i+1]), 1,
        "various isomorphic, N=$N i=$i");
  }

  if ($N <= 5) {
    my @indsets = MyGraphs::Graph_indset_sizes($graphs[0]);
    my $indnum = $#indsets;
    my $indsets_count = sum(@indsets);
    ok ($indnum, $want_indnum[$N],
        "indnum N=$N");
    ok ($indsets_count, $want_indsets_count[$N],
        "indsets count N=$N");
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
                           'lib','Graph','Maker','HalvedHypercube.pm'));
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
    my $graph = Graph::Maker->new('halved_hypercube', undirected => 1,
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
