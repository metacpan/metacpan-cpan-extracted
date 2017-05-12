#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde
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

use strict;
use Graph;
use MyGraphs;

{
  # Konigsberg bridges, edges between bridges
  #
  #                                  0              2
  #     ---0---1-----2---                  1
  #               |
  #               3                          3
  #               |
  #     ---4---5-----6---                  5
  #                                  4              6
  #
  # plain underlying https://hog.grinvin.org/ViewGraphInfo.action?id=28
  # bridge links not
  #
  require Graph::Graph6;
  require Graph::Easy;
  require Graph::Easy::Parser::Graph6;
  require Graph::Easy::As_graph6;
  my $filename = '/tmp/2.g6';
  my $edge_aref = [ [0,1],[0,2],  [0,3], [0,4],[0,5],
                    [1,2],[1,3], [1,4],[1,5],
                    [2,3],[2,6],
                    [3,4],[3,5],[3,6],
                    [4,5],[4,6],
                    [5,6] ];
  Graph::Graph6::write_graph(filename => $filename,
                             edge_aref => $edge_aref)
      or die $!;
  my $parser = Graph::Easy::Parser::Graph6->new;
  my $easy = $parser->from_file($filename);


  $easy = Graph::Easy->new;
  $easy->add_edge('A','C', '0');
  $easy->add_edge('A','C', '1');
  $easy->add_edge('C','D', '2');
  $easy->add_edge('A','D', '3');
  $easy->add_edge('A','B', '4');
  $easy->add_edge('A','B', '5');
  $easy->add_edge('B','D', '6');
  my $g6_land_str = $easy->as_graph6;
  print $easy->as_ascii;


  my $dual = MyGraphs::Graph_Easy_line_graph($easy);

  Graph::Graph6::write_graph(str_ref => \my $g6_str,
                             edge_aref => $edge_aref)
      or die $!;
  my $dual_g6 = $dual->as_graph6;
  print $g6_str;
  print $dual_g6;
  print graph6_str_to_canonical($g6_str);
  print graph6_str_to_canonical($dual_g6);

  hog_searches_html($easy, $dual);

  exit 0;

  sub Graph_Easy_Edge_name {
    my ($edge) = @_;
    return $edge->from->name . $edge->to->name;
  }
}

{
  # Konigsberg, bridges and land
  #
  #             C
  #
  #     ---g----f-----e---
  #                |
  #          A     d     D
  #                |
  #     ---a----b-----c---
  #
  #             B
  #

  {
    my $filename = '/tmp/2.g6';
    my $a = 0;
    my $b = 1;
    my $c = 2;
    my $d = 3;
    my $e = 4;
    my $f = 5;
    my $g = 6;
    my $A = 7;
    my $B = 8;
    my $C = 9;
    my $D = 10;
    my $edge_aref = [ [$C,$g],[$C,$f],[$C,$e],
                      [$A,$a],[$A,$b],[$A,$d],[$A,$f],[$A,$g],
                      [$D,$c],[$D,$d],[$D,$e],
                      [$B,$a],[$B,$b],[$B,$c] ];
    Graph::Graph6::write_graph(filename => $filename,
                               edge_aref => $edge_aref)
        or die $!;
    my $parser = Graph::Easy::Parser::Graph6->new;
    my $easy = $parser->from_file($filename);
    my $g6_str = $easy->as_graph6;
    print $g6_str;
    print graph6_str_to_canonical($g6_str);

    $easy->set_attribute('root','07'); # for as_graphviz()
    $easy->{att}->{root} = '07';       # for root_node() for as_ascii()
    $easy->set_attribute('flow','south');
    hog_searches_html($easy);
    exit 0;
  }
  {
    my $filename = '/tmp/2.g6';
    my $easy = Graph::Easy->new;
    $easy->add_vertices('a','b','c','d','e','f','g');
    foreach my $elem (
                      ['g','C'],['f','C'],['e','C'],
                      ['a','B'],['b','B'],['c','B'],
                      ['A','a'],['A','b'],['A','d'],['A','f'],['A','g'],
                      ['D','c'],['D','d'],['D','e'],

                      # # pasted, typo first f is b
                      # ['A','a'], ['A','b'], ['A','d'], ['A','f'], ['A','g'],
                      # ['D','c'], ['D','d'], ['D','e'],
                      # ['a','B'], ['b','B'], ['c','B'],
                      # ['e','C'], ['f','C'], ['g','C'],

                     ) {
      $easy->add_edge(reverse @$elem);
    }
    my $g6_str = $easy->as_graph6;
    $easy->set_attribute('root','A'); # for as_graphviz()
    $easy->{att}->{root} = 'A';       # for root_node() for as_ascii()
    $easy->set_attribute('flow','south');
    my $graphviz_str = $easy->as_graphviz;

    print $g6_str;
    print graph6_str_to_canonical($g6_str);

    MyGraphs::hog_searches_html($easy);

    exit 0;
  }
}
{
  # Konigsberg, vertex for each side of each bridge
  #
  #                                               1
  #        0    1     2                        0-----2
  #     ---g----f-----e---
  #        3    4  |  5                         3--4         5
  #               6d7                                5     7 |
  #        8    9  |  10                        8--9         3
  #     ---a----b-----c---
  #       11   12     13                       11----13
  #                                               12

  my $filename = '/tmp/2.g6';
  my $easy = Graph::Easy->new;
  foreach my $elem (
                    [0,3],[1,4],[2,5],
                    [0,1],[0,2],[1,2], # clique

                    [8,11],[9,12],[10,13], [6,7],

                    [3,4],[3,6],[3,8],[3,9],  # clique
                    [4,6],[4,8],[4,9],
                    [6,8],[6,9],
                    [8,9],

                    [5,7],[5,10],[7,10], # clique
                    [11,12],[11,13],[12,13], # clique
                   ) {
    $easy->add_edge(@$elem);
  }

  $easy->set_attribute('root','1'); # for as_graphviz()
  $easy->{att}->{root} = '1';       # for root_node() for as_ascii()
  $easy->set_attribute('flow','south');
  hog_searches_html($easy);
  exit 0;
}

{
  # Konigsberg bridges, edges between unconnected bridges
  #
  #                                  0              2
  #     ---0---1-----2---                  1
  #               |
  #               3                          3
  #               |
  #     ---4---5-----6---                  5
  #                                  4              6
  #
  my $edge_aref = [ [0,1],[0,2],  [0,3], [0,4],[0,5],
                    [1,2],[1,3], [1,4],[1,5],
                    [2,3],[2,6],
                    [3,4],[3,5],[3,6],
                    [4,5],[4,6],
                    [5,6] ];
  my $graph = Graph->new (undirected => 1);
  foreach my $edge (@$edge_aref) {
    $graph->add_edge(@$edge);
  }

  print scalar($graph->edges)," edges\n";
  $graph = $graph->complement;
  Graph_view($graph);
  print "complement ",scalar($graph->edges)," edges\n";
  exit 0;
}


