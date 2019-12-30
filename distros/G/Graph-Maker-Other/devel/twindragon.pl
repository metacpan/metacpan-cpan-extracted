#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2019 Kevin Ryde
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

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::Twindragon;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # twindragon
  #   k=1 two squares F?df_ hog not
  #   k=2 four squares https://hog.grinvin.org/GraphAdded.action?id=22744
  #   k=3 https://hog.grinvin.org/ViewGraphInfo.action?id=25145
  #   k=4 https://hog.grinvin.org/ViewGraphInfo.action?id=25174
  # hanging stripped
  #   k=4 not

  my @graphs;
  for (my $k = 0; @graphs <= 6; $k++) {
    my $graph = Graph::Maker->new('twindragon', level=>$k, arms=>1,
                                  undirected=>1);

    # print "strip hanging cycles " . Graph_delete_hanging_cycles($graph) . "\n";

    # next if $graph->vertices == 0;
    last if $graph->vertices > 200;

    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # pictures
  foreach my $level (3,
                     # 0 .. 4
                    ) {
    print "level=$level\n";

    my $graph = Graph::Maker->new('twindragon',
                                  level => $level,
                                  arms => 1,
                                  undirected=>1);
    print "$graph\n";
    Graph_xy_rotate_minus90($graph);
    print "$graph\n";
    Graph_xy_print($graph);
  }

  # my $graph = Graph::Maker->new('twindragon',
  #                               level => 2,
  #                               arms => 2,
  #                               undirected=>1);
  # Graph_xy_print($graph);
  exit 0;

  sub Graph_xy_rotate_minus90 {
    my ($graph) = @_;
    foreach my $v ($graph->vertices) {
      my ($x,$y) = split /,/, $v;
      ($x,$y) = ($y,-$x);    # rotate -90
      Graph_rename_vertex($graph, $v, "r--$x,$y");
    }
    foreach my $v ($graph->vertices) {
      my $new_v = $v;
      $new_v =~ s/r--//;
      Graph_rename_vertex($graph, $v, $new_v);
    }
    return $graph;
  }
}

{
  # 3 ways to connect 4 squares
  # 4^6 == 4096
  # all 3 hog not

  require Graph::Maker::Cycle;
  my @graphs;
  foreach my $a (1 .. 4) {
    foreach my $b1 (1 .. 4) {
      foreach my $b2 (1 .. 4) {
        next if $b1==$b2;
        foreach my $c2 (1 .. 4) {
          foreach my $c3 (1 .. 4) {
            next if $c2==$c3;
            foreach my $d (1 .. 4) {
              if (status()) { print "$a,$b1, $b2,$c2, $c3,$d\r"; }

              my $graph = Graph->new(undirected=>1);

              $graph->add_cycle(1 .. 4);
              $graph->add_cycle(5 .. 8);
              $graph->add_cycle(9 .. 12);
              $graph->add_cycle(13 .. 16);

              ### try: "$a,$b1, $b2,$c2, $c3,$d"
              $graph->add_edges($a,    $b1+4,
                                $c2+8, $b2+4,
                                $c3+8, $d+12);

              my $seen = 0;
              foreach my $got (@graphs) {
                if (Graph_is_isomorphic($graph, $got)) {
                  $seen = 1;
                  last;
                }
              }

              if (! $seen) {
                print "$graph\n";
                push @graphs, $graph;
              }
            }
          }
        }
      }
    }
  }

  hog_searches_html(@graphs);
  exit 0;

  my $prev;
  sub status {
    if (! $prev || $prev != time()) {
      $prev = time();
      return 1;
    } else {
      return 0;
    }
  }
}

