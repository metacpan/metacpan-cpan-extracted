#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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
use Graph::Maker::Johnson;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # J(5,2) complement of Petersen
  # https://hog.grinvin.org/ViewGraphInfo.action?id=21154
  require Graph::Maker::Johnson;
  my @graphs;
  my $graph = Graph::Maker->new('Johnson',
                                N => 5, K => 2,
                                undirected => 1,
                               );
  print $graph->get_graph_attribute ('name'),"\n";
  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  print "  num vertices $num_vertices  num edges $num_edges\n";
  Graph_view($graph);
  push @graphs, $graph;
  $graph = $graph->complement;
  push @graphs, $graph;
  Graph_view($graph);

  hog_searches_html(@graphs);
  exit 0;
}

{
  # 5,2 in circle layout, looking for uniform offsets

  $|=1;
  my $graph = Graph::Maker->new('Johnson',
                                N => 5, K => 2,
                                undirected => 1);
  my @cycle = ('1,2', '1,3',
               '2,3', '2,4',
               '3,4', '3,5',
               '4,5', '1,4',
               '1,5', '2,5',
              );
  require Math::Permute::Array;
  my $p = Math::Permute::Array->new([ @cycle[1..$#cycle] ]);
  print "perms ",$p->cardinal,"\n";
  my $t = time();
  my $best = 0;
 PERM: for my $pnum (0 .. $p->cardinal-1) {
    my $aref = $p->permutation($pnum);
    my @this = ($cycle[0], @$aref);
    my %this = map { $this[$_] => $_ } 0 .. $#this;
    if (time() != $t) {
      $t = time();
      print "time $pnum, best $best\r";
    }

    my $v_to_ostr = sub {
      my ($v, $pos) = @_;
      my @neighbours = $graph->neighbours($v);
      my @offsets = map {$this{$_}} @neighbours;
      @offsets = map {($_ - $pos) % scalar(@cycle)} @offsets;
      @offsets = sort {$a<=>$b} @offsets;
      return join(',',@offsets);
    };
    my $want_ostr = $v_to_ostr->($this[0], 0);
    foreach my $i (1 .. $#this) {
      my $got_ostr = $v_to_ostr->($this[$i], $i);
      if ($got_ostr ne $want_ostr) {
        # print "  not at $i\n";
        $best = max($best, $i);
        next PERM;
      }
    }
    print "$want_ostr\n";
  }
  exit 0;
}

{
  # 5,2 in circle layout

  my @cycle = ('1,2', '1,3',
               '2,3', '2,4',
               '3,4', '3,5',
               '4,5', '1,4',
               '1,5', '2,5',
              );      
  my @offsets_even = (-3, -2, -1,  1, 2, 3);
  my @offsets_odd  = (-4, -3, -1,  1, 3, 4);

  my $graph = Graph::Maker->new('Johnson',
                                N => 5, K => 2,
                                undirected => 1);
  foreach my $i (0 .. 0*$#cycle) {
    my $from = $cycle[$i];
    foreach my $offset ($i%2==0 ? @offsets_even : @offsets_odd) {
      my $j = ($i + $offset) % scalar(@cycle);
      my $to = $cycle[$j];
      if (! $graph->has_edge($from,$to)) {
        print "not $from to $to\n";
      }
    }
  }
  print "ok\n";
  exit 0;
}

{
  # Johnson 
  #
  # J(4,2) = https://hog.grinvin.org/ViewGraphInfo.action?id=226
  # J(5,2) = https://hog.grinvin.org/ViewGraphInfo.action?id=21154
  # J(6,3) = not

  require Graph::Maker::Johnson;
  my @graphs;
  foreach my $N (3 .. 7) {
    my $K = 2;
    my $graph = Graph::Maker->new('Johnson',
                                  N => $N, K => $K,
                                  undirected => 1,
                                 );
    print $graph->get_graph_attribute ('name'),"\n";
    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    print "  num vertices $num_vertices  num edges $num_edges\n";
    # Graph_view($graph);
    push @graphs, $graph;
  }
  hog_searches_html(@graphs);
  exit 0;
}
{
  # tikz print

  my $N = 5;
  my $K = 2;
  my $graph = Graph::Maker->new('Johnson',
                                N => $N, K => $K,
                                undirected => 1,
                               );
  Graph_print_tikz($graph);
  exit 0;
}

{
  # Johnson K vs N-K

  require Graph::Maker::Johnson;
  foreach my $N (0 .. 10) {
    foreach my $K (1 .. $N-1) {
      my $g1 = Graph::Maker->new('Johnson', N=>$N, K=>$K, undirected => 1);
      my $g2 = Graph::Maker->new('Johnson', N=>$N, K=>$N-$K, undirected => 1);
      my $same = Graph_is_isomorphic($g1, $g2);
      print "N=$N, K=$K ",$same ? "yes\n" : "no\n";
      if (! $same) {
        # Graph_view($Johnson);
        # Graph_view($complete);
      }
    }
  }
  exit 0;
}

{
  # Johnson K=1 is complete
  # Graph::Maker::Complete for N=1 is no vertices

  require Graph::Maker::Johnson;
  require Graph::Maker::Complete;
  foreach my $N (0 .. 7) {
    my $K = $N-1;
    my $Johnson = Graph::Maker->new('Johnson', N=>$N, K=>$K, undirected => 1);
    my $complete = Graph::Maker->new('complete', N=>$N, undirected => 1);
    my $same = Graph_is_isomorphic($Johnson, $complete);
    print "N=$N ",$same ? "yes\n" : "no\n";
    if (! $same) {
      # Graph_view($Johnson);
      # Graph_view($complete);
    }
  }
  exit 0;
}



