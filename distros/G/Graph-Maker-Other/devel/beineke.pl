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
use MyGraphs;

use FindBin;
use lib "$FindBin::Bin/lib";
use Graph::Maker::Beineke;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Graph with all of Beineke as plain or induced subgraphs
  # geng by edge_aref

  # subgraphs only, not necessarily induced, 6 vertices
  # 12 edges https://hog.grinvin.org/ViewGraphInfo.action?id=748
  #          (comment posted)
  # 13 edges https://hog.grinvin.org/ViewGraphInfo.action?id=756
  # 13 edges https://hog.grinvin.org/ViewGraphInfo.action?id=760
  #     two squares cross linked
  # 14 edges https://hog.grinvin.org/ViewGraphInfo.action?id=230
  # 15 edges complete-6
  #
  # 12-edge
  #     G6  +----2--\--\     degrees 3,5,3,5,3,3
  #         |   / \  \  \
  #         |  3---1  5--6
  #         |   \ /  /  /
  #         +----4--/--/
  #
  # 0=2,0=3,0=4,0=5, 1=3,1=4,1=5, 2=4,2=5, 3=4,3=5, 4=5
  # degrees 4,3,3,4,5,5     cross-links 3 to 3, so 1-to-5

  # 7 of induced
  # found:
  #  0-3,1-4,0-5,2-5,0-6,1-6,2-6,4-6,0-7,1-7,3-7,4-7,5-7,0-8,1-8,2-8,4-8,5-8,6-8,7-8 [20 edges]
  # found:
  #  0-3,1-4,0-5,2-5,0-6,1-6,3-6,4-6,1-7,2-7,3-7,4-7,5-7,0-8,1-8,3-8,4-8,5-8,6-8,7-8 [20 edges]
  # found:
  #  0-3,1-4,0-5,2-5,3-5,0-6,1-6,4-6,5-6,1-7,2-7,3-7,4-7,5-7,1-8,2-8,4-8,5-8,6-8,7-8 [20 edges]
  # found:
  #  0-3,0-4,1-4,1-5,2-5,0-6,2-6,3-6,5-6,0-7,2-7,3-7,5-7,6-7,0-8,1-8,2-8,4-8,5-8,6-8 [20 edges]
  # found:
  #  0-3,1-4,2-4,1-5,2-5,0-6,1-6,3-6,0-7,2-7,3-7,4-7,5-7,0-8,1-8,2-8,3-8,4-8,6-8,7-8 [20 edges]
  # found:
  #  0-3,1-4,2-4,1-5,2-5,0-6,1-6,3-6,4-6,0-7,2-7,3-7,5-7,0-8,1-8,2-8,3-8,4-8,6-8,7-8 [20 edges]
  # found:
  #  0-3,0-4,3-4,1-5,2-5,0-6,1-6,3-6,0-7,2-7,3-7,4-7,5-7,0-8,1-8,2-8,4-8,5-8,6-8,7-8 [20 edges]

  require Graph::Graph6;
  require Graph::Maker::Beineke;

  my $induced = 0;

  my @G;
  my @G_graph;
  foreach my $N (1 .. 9) {
    my $graph = Graph::Maker->new('Beineke', G=>$N, undirected=>1);
    push @G_graph, $graph;
    $G[$N-1] = [ map{[$_->[0]-1, $_->[1]-1]} $graph->edges ];
    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    print "G$N $num_vertices $num_edges\n";
  }
  print "\n";

  my $try = sub {
    my ($edge_aref, $num_vertices) = @_;

    my $num_edges  = scalar(@$edge_aref);
    # if ($num_edges > 12) { return 0; }

    my @maps;
    foreach my $G (@G) {
      my $map = ($induced
                 ? MyGraphs::edge_aref_is_induced_subgraph($edge_aref, $G)
                 : MyGraphs::edge_aref_is_subgraph($edge_aref, $G));
      if (! $map) {
        return 0;
      }
      push @maps,$map;
    }
    Graph::Graph6::write_graph(str_ref   => \my $g6_str,
                               edge_aref => $edge_aref);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    print "found: $num_edges edges\n";
    print " ",MyGraphs::edge_aref_string($edge_aref),"\n";
    print " $g6_str";
    foreach my $map (@maps) {
      print " subgraph map: $map\n";
    }

    my $graph = MyGraphs::Graph_from_edge_aref($edge_aref,
                                               num_vertices => $num_vertices);
    print " graph $graph\n";
    foreach my $i (0 .. $#G_graph) {
      my $G = $G_graph[$i];
      print " ",($i+1)," induced map: ",
        MyGraphs::Graph_is_induced_subgraph($graph, $G),"\n";
    }
    print " line graph: ",
      (MyGraphs::Graph_is_line_graph_by_Beineke($graph) ? "yes" : "no"), "\n";

    # Graph_print_tikz($graph); exit 0;
    # MyGraphs::Graph_view($graph); exit 0;
    # return 1;

    # my $easy = Graph::Easy->new (undirected => 1);
    # foreach my $edge (@$edge_aref) {
    #   $easy->add_edge(@$edge);
    # }
    # print $easy->as_graphviz;
  };

  # $try->([ [0,2],[6,5],[0,3],[4,8],[1,2],[4,3],[7,6],[6,1],[7,2],
  #          [7,1],[4,5],[1,4],[0,8],[2,3],[6,2],[7,5],[1,3],[1,5],
  #          [0,1],[2,8] ]);
  # 173102:HoCzEt~ in geng -l output

  # $try->([ [0,2],[0,3],[1,3],[0,4],[1,4],[2,4],[3,4],
  #          [0,5],[1,5],[2,5],[3,5],[4,5],
  #
  #          [0,6] ]);

  $| = 1;
  require IPC::Run;
  my @graphs;
  foreach my $num_vertices (6 .. 6) {
    print "$num_vertices vertices\n";
    my @args = (# '-c', # connected
                $num_vertices);
    IPC::Run::run(['nauty-geng','-u',@args]);
    my $h = IPC::Run::start(['nauty-geng',@args], '>pipe', \*GENG);
    my $count = 0;
    my $t = int(time()/10);
    my @edges;
    my $edge_aref = \@edges;
    my $fh = \*GENG;
    my $found = 0;
  GRAPH: while (Graph::Graph6::read_graph(fh => $fh,
                                          edge_aref => $edge_aref)) {
      if (int(time()/10) != $t) {
        print $count,"\n";
        $t = int(time()/10);
      }
      $count++;

      my $this_found = $try->($edge_aref, $num_vertices);
      $found += $this_found;
      if ($this_found) {
        my $graph = MyGraphs::Graph_from_edge_aref
          ($edge_aref, num_vertices => $num_vertices);
        my $num_edges = $graph->edges;
        $graph->set_graph_attribute
          (name => "vertices=$num_vertices edges=$num_edges");
        push @graphs, $graph;
        # Graph_view($graph);
      }
    }
    # last if $found;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # subgraphs among Beineke (none are induced subgraphs)
  # https://hog.grinvin.org/ViewGraphInfo.action?id=25225
  # 1 subgraphs:
  # 2 subgraphs: 1,
  # 3 subgraphs: 1, 2,
  # 4 subgraphs: 1,
  # 5 subgraphs: 1, 2, 4,
  # 6 subgraphs: 1, 2, 4, 5, 7, 8,
  # 7 subgraphs: 1, 4,
  # 8 subgraphs: 1, 4,
  # 9 subgraphs: 1, 4, 7,
  # G1 claw is subgraph of all

  my @graphs = (undef,
                map {Graph::Maker->new('Beineke', G=>$_, undirected=>1)}
                1 .. 9);
  my $graph = Graph->new;
  foreach my $i (1 .. 9) {
    print "$i subgraphs: ";
    foreach my $j (1 .. 9) {
      next if $i==$j;
      if (Graph_is_subgraph($graphs[$i], $graphs[$j])) {
        print "$j, ";
        $graph->add_edge($i, $j);
      }
    }
    print "\n";
  }
  # Graph_view($graph);
  # Graph_print_tikz($graph);
  hog_searches_html($graph);
  exit 0;
}


{
  require Graph::Maker::Star;
  require Graph::Maker::Cycle;
  foreach my $N (0 .. 10) {
     my $graph = Graph::Maker->new('star', N=>$N, undirected=>1);
    # my $graph = Graph::Maker->new('cycle', N=>$N, undirected=>1);
    print "$N line graph: ", (Graph_is_line_graph_by_Beineke($graph) ? "yes" : "no"), "\n";
  }
  # foreach my $graph (MyGraphs::Graph_Beineke_graphs()) {
  #   print "$graph\n";
  # }
  exit 0;
}



{
  # geng for graphs with all of Beineke G1 to G9 as induced subgraphs

  require Graph::Maker::Beineke;
  my @G = map {Graph::Maker->new('Beineke', G=>$_, undirected=>1)} 1 .. 9;
  foreach my $G (@G) {
    my $num_vertices = $G->vertices;
    my $num_edges    = $G->edges;
    print "$num_vertices $num_edges\n";
  }

  $| = 1;
  require IPC::Run;
  my $h = IPC::Run::start(['nauty-geng',
                           '-c', # connected
                           '9', # vertices
                           '14:20'],
                          '>pipe', \*GENG);
  require Graph::Reader::Graph6;
  my $reader = Graph::Reader::Graph6->new;
  my $count = 0;
  my $t = int(time()/10);
 GRAPH: while (my $graph = $reader->read_graph(\*GENG)) {
    if (int(time()/10) != $t) {
      print $count,"\n";
      $t = int(time()/10);
    }
    $count++;
    foreach my $G (@G) {
      if (! Graph_is_induced_subgraph($graph, $G)) {
        next GRAPH;
      }
    }
    print "$graph\n";
    Graph_view($graph);
  }
  exit 0;
}


{
  # Theorem of the Day line graph, all of Beineke induced sub-graphs

  my $easy = Graph::Easy->new;
  $easy->add_edge('a','b'); $easy->add_edge('a','d'); $easy->add_edge('a','h');
  $easy->add_edge('b','c'); $easy->add_edge('b','d'); $easy->add_edge('b','h');
  $easy->add_edge('c','d'); $easy->add_edge('c','e');
  $easy->add_edge('c','g'); $easy->add_edge('c','h');
  $easy->add_edge('d','e'); $easy->add_edge('d','f'); $easy->add_edge('d','l');
  $easy->add_edge('e','f'); $easy->add_edge('e','l'); $easy->add_edge('e','k');
  $easy->add_edge('e','j'); $easy->add_edge('e','g');
  $easy->add_edge('f','l');
  $easy->add_edge('g','j'); $easy->add_edge('g','k'); $easy->add_edge('g','l');
  $easy->add_edge('g','i'); $easy->add_edge('g','h');
  $easy->add_edge('h','i'); $easy->add_edge('h','l');
  $easy->add_edge('i','l');
  $easy->add_edge('j','k');
  $easy->add_edge('k','l');
  $easy->set_attribute('flow','south');
  $easy->set_attribute('root','a'); # for as_graphviz()
  $easy->{att}->{root} = 'a';       # for root_node() for as_ascii()
  # Graph_Easy_view($easy);

  my $num_vertices = $easy->nodes;
  my $num_edges    = $easy->edges;
  print "num vertices $num_vertices  num edges $num_edges\n";

  my $graph = Graph_theorem_of_the_day();
  my @graphs;
  # 9,20
  foreach my $edge_aref ([ [108,2],[6,5],[108,3],[4,106],[1,2],[4,3],[107,6],[6,1],[107,2],[107,1],[4,5],[1,4],[108,106],[2,3],[6,2],[107,5],[1,3],[1,5],[108,1],[2,106] ],

                         [ [106,3],[108,1],[2,1],[3,4],[108,2],[1,6],[106,2],[1,4],[5,6],[2,107],[2,3],[107,3],[5,4],[2,6],[108,6],[1,5],[106,107],[106,4],[1,107],[1,3] ],

                         [ [1,3],[5,4],[1,5],[108,106],[2,6],[106,4],[1,107],[106,107],[1,6],[1,4],[106,2],[2,107],[5,6],[107,3],[2,3],[106,3],[108,3],[3,4],[108,4],[2,1],
                         ]) {

    $graph = Graph->new (undirected => 1);
    foreach my $edge (@$edge_aref) {
      $graph->add_edge(@$edge);
    }
    # Graph_view($graph);
    push @graphs, $graph;

    require Graph::Maker::Beineke;
    foreach my $G (1 .. 9) {
      my $G = Graph::Maker->new('Beineke', G=>$G, undirected=>1);
      my $bool = Graph_is_induced_subgraph($graph, $G);
      print "G$G ", $bool?"yes":"no", "\n";
    }
    print graph6_str_to_canonical(Graph_graph6_str($graph));
  }
  hog_searches_html(@graphs);
  exit 0;
}

{
  # Soltes J2 for Soltes G2 = Beineke G7
  #      a----e
  #     / \   |\
  #    b---c  | g--h
  #     \ /   |/
  #      d----f
  #
  my @graphs;

  my $J2 = Graph->new (undirected => 1);
  $J2->set_graph_attribute (name => "Soltes J2");
  $J2->add_edge('a','b');$J2->add_edge('a','c');$J2->add_edge('a','e');
  $J2->add_edge('b','c');$J2->add_edge('b','d');
  $J2->add_edge('c','d');
  $J2->add_edge('d','f');
  $J2->add_edge('e','f');$J2->add_edge('e','g');
  $J2->add_edge('f','g');
  $J2->add_edge('g','h');
  push @graphs, $J2;

  # Soltes J3 for Soltes G3 = Beineke G2
  #      a---
  #     / \   \
  #    b---c   e
  #     \ / _/ |
  #      d-/---f----g
  # hog not
  #
  my $J3 = Graph->new (undirected => 1);
  $J3->set_graph_attribute (name => "Soltes J3");
  $J3->add_edge('a','b');$J3->add_edge('a','c');$J3->add_edge('a','e');
  $J3->add_edge('b','c');$J3->add_edge('b','d');
  $J3->add_edge('c','d');
  $J3->add_edge('d','e');$J3->add_edge('d','f');
  $J3->add_edge('e','f');
  $J3->add_edge('f','g');
  push @graphs, $J3;

  # Lai and Soltes H4
  # degree=6 claw-free, K5-e free, G5 free, but a non-line
  # has G2 and G8
  my $H4 = Graph_Lai_Soltes_H4();
  push @graphs, $H4;

  my $try = $H4;

  require Graph::Maker::Beineke;
  foreach my $G (1 .. 9) {
    my $G = Graph::Maker->new('Beineke', G=>$G, undirected=>1);
    my $bool = Graph_is_induced_subgraph($try, $G);
    print "G$G ", $bool?"yes":"no", "\n";
    push @graphs, $G;
  }
  hog_searches_html(@graphs);
  exit 0;
}



{
  # extending from G9

  # [108,2],[6,5],[108,3],[4,106],[1,2],[4,3],[107,6],[6,1],[107,2],[107,1],[4,5],[1,4],[108,106],[2,3],[6,2],[107,5],[1,3],[1,5],[108,1],[2,106],
  #   vertices 9 edges 20

  # [106,3],[108,1],[2,1],[3,4],[108,2],[1,6],[106,2],[1,4],[5,6],[2,107],[2,3],[107,3],[5,4],[2,6],[108,6],[1,5],[106,107],[106,4],[1,107],[1,3],
  #   vertices 9 edges 20

  # [1,3],[5,4],[1,5],[108,106],[2,6],[106,4],[1,107],[106,107],[1,6],[1,4],[106,2],[2,107],[5,6],[107,3],[2,3],[106,3],[108,3],[3,4],[108,4],[2,1],
  #   vertices 9 edges 20


  require Graph::Maker::Beineke;
  my $G9 = Graph::Maker->new('Beineke', G=>9, undirected=>1);
  my @G = map {Graph::Maker->new('Beineke', G=>$_, undirected=>1)} 1 .. 8;

  my %seen;
  my @pending = ([$G9,0]);
  while (@pending) {
    use sort 'stable';
    my $num_pending = scalar(@pending);
    @pending = sort {$b->[1] <=> $a->[1]} @pending;
    my $c = shift @pending;
    my ($parent,$count) = @$c;

    my @vertices = $parent->vertices;
    @vertices = sort {$a<=>$b} @vertices;
    my $num_vertices = scalar(@vertices);
    print "try $num_vertices($count)  $parent  (pending $num_pending)\n";
    my $new = 100 + $num_vertices;
    $parent->add_vertex($new);
    my $same_count = 0;
    foreach my $i (1 .. 2**scalar(@vertices)-1) {
      my $g = $parent->copy;
      foreach my $bit (0 .. $#vertices) {
        if ($i & (1 << $bit)) {
          $g->add_edge($new, $vertices[$bit]);
        }
      }
      next if scalar($g->edges) > 20;

      if ($seen{graph6_str_to_canonical(Graph_graph6_str($g))}++) {
        $same_count++;
        # printf "  %b skip\n", $i;
        next;
      }

      my $count = 0;
      my @got;
      foreach my $n (0 .. $#G) {
        my $map = Graph_is_induced_subgraph($g, $G[$n]);
        if ($map) {
          push @got, 'G'.($n+1);
          $count++;
          # printf "  %b  G%d %s\n", $i, $n+1, $map;
        } else {
          if ($num_vertices == 8) {  # so $g is 8
            push @got, 'not'.($n+1);
            last;
          }
        }
      }
      # printf "  %b  %s\n", $i, join(',',@got);

      if ($count == 8) {
        print "found $g\n";
        foreach my $e ($g->edges) {
          print "[$e->[0],$e->[1]],"
        }
        print "\n";
        print "  vertices ",scalar($g->vertices)," edges ",scalar($g->edges),"\n";
        Graph_view($g);
        next;
      }
      if ($num_vertices < 8) {  # so $g is 8
        push @pending, [$g, $count];
      }
    }
    print "  skipped $same_count same\n";
  }
  exit 0;
}

{
  # which G1-G9 subgraphs
  {
    # Soltes H1
    #    a---b
    #    | / |
    #    c---d
    #    | / |
    #    e---f
    #     \ /
    #      g
    #
    my $H1 = Graph->new (undirected => 1);
    $H1->add_edge('a','b'); $H1->add_edge('a','c');
    $H1->add_edge('b','c'); $H1->add_edge('b','d');
    $H1->add_edge('c','d'); $H1->add_edge('c','e');
    $H1->add_edge('d','e'); $H1->add_edge('d','f');
    $H1->add_edge('e','f');
    $H1->add_edge('e','g');$H1->add_edge('f','g');
    my @graphs = ($H1);

    # Soltes H2
    #
    require Graph::Maker::Wheel;
    my $H2 = Graph::Maker->new('wheel', G=>6, undirected=>1);
    $H2->set_graph_attribute (name => 'H2');
    $H2->add_edge(2,'a');
    $H2->add_edge(3,'a');
    push @graphs, $H2;

    # Soltes H3
    #
    require Graph::Maker::Wheel;
    my $H3 = Graph::Maker->new('wheel', G=>6, undirected=>1);
    $H3->set_graph_attribute (name => 'H3');
    $H3->add_edge(2,'a'); $H3->add_edge(3,'a');
    $H3->add_edge(3,'b'); $H3->add_edge(4,'b');
    $H3->add_edge('a','b');
    push @graphs, $H3;

    # Soltes J2,J3
    my $J2 = Graph_Soltes_J2();
    my $J3 = Graph_Soltes_J3();
    push @graphs, $J2, $J3;

    my $try = $J3;
    # $try->add_edge('g','1');
    # $try->add_edge('1','2');

    require Graph::Maker::Beineke;
    foreach my $G (1 .. 9) {
      my $G = Graph::Maker->new('Beineke', G=>$G, undirected=>1);
      my $bool = Graph_is_induced_subgraph($try, $G);
      print "G$G ", $bool?"yes":"no", "\n";
      push @graphs, $G;
    }
    hog_searches_html(@graphs);
  }
  exit 0;
}



{
  # Beineke

  my @graphs;
  foreach my $G (1 .. 9) {
    require Graph::Maker::Beineke;
    my $graph = Graph::Maker->new('Beineke', G=>$G, undirected=>1);
    push @graphs, $graph;
  }
  {
    # Soltes H1
    # G8 a---b
    #    | / |
    #    c---d
    #    | / |
    #    e---f
    #     \ /
    #      g
    # https://hog.grinvin.org/ViewGraphInfo.action?id=21103
    #
    my $easy = Graph::Easy->new (undirected => 1);
    $easy->set_attribute (label => 'H1');
    $easy->add_edge('a','b'); $easy->add_edge('a','c');
    $easy->add_edge('b','c'); $easy->add_edge('b','d');
    $easy->add_edge('c','d'); $easy->add_edge('c','e');
    $easy->add_edge('d','e'); $easy->add_edge('d','f');
    $easy->add_edge('e','f');
    $easy->add_edge('e','g');$easy->add_edge('f','g');
    push @graphs, $easy;
  }
  {
    # Soltes H2
    # https://hog.grinvin.org/ViewGraphInfo.action?id=21105
    #
    require Graph::Maker::Wheel;
    my $graph = Graph::Maker->new('wheel', G=>6, undirected=>1);
    $graph->set_graph_attribute (name => 'H2');
    $graph->add_edge(2,'a');
    $graph->add_edge(3,'a');
    push @graphs, $graph;
  }
  {
    # Soltes H3
    # https://hog.grinvin.org/ViewGraphInfo.action?id=21107
    #
    require Graph::Maker::Wheel;
    my $graph = Graph::Maker->new('wheel', G=>6, undirected=>1);
    $graph->set_graph_attribute (name => 'H3');
    $graph->add_edge(2,'a'); $graph->add_edge(3,'a');
    $graph->add_edge(3,'b'); $graph->add_edge(4,'b');
    $graph->add_edge('a','b');
    push @graphs, $graph;
  }

  {
    # Soltes J1, same as Beineke G4 = Soltes G1
    #          c
    #         /|\
    #    a---b | e---f
    #         \|/
    #          d
    # https://hog.grinvin.org/ViewGraphInfo.action?id=922
    my $easy = Graph::Easy->new (undirected => 1);
    $easy->set_attribute (label => 'J1');
    $easy->add_edge('a','b');
    $easy->add_edge('b','c'); $easy->add_edge('b','d');
    $easy->add_edge('c','d'); $easy->add_edge('c','e');
    $easy->add_edge('d','e');
    $easy->add_edge('e','f');
    push @graphs, $easy;
  }
  {
    # Soltes J2
    #      a----e
    #     / \   |\
    #    b---c  | g--h
    #     \ /   |/
    #      d----f
    # https://hog.grinvin.org/ViewGraphInfo.action?id=21113
    #
    my $easy = Graph::Easy->new (undirected => 1);
    $easy->set_attribute (label => 'J2');
    $easy->add_edge('a','b');$easy->add_edge('a','c');$easy->add_edge('a','e');
    $easy->add_edge('b','c');$easy->add_edge('b','d');
    $easy->add_edge('c','d');
    $easy->add_edge('d','f');
    $easy->add_edge('e','f');$easy->add_edge('e','g');
    $easy->add_edge('f','g');
    $easy->add_edge('g','h');
    push @graphs, $easy;
  }
  {
    # Soltes J3
    #      a---
    #     / \   \
    #    b   c   e
    #     \ / _/ |
    #      d-/---f----g
    # https://hog.grinvin.org/ViewGraphInfo.action?id=21115
    #
    my $easy = Graph::Easy->new (undirected => 1);
    $easy->set_attribute (label => 'J3');
    $easy->add_edge('a','b');$easy->add_edge('a','c');$easy->add_edge('a','e');
    $easy->add_edge('b','d');
    $easy->add_edge('c','d');
    $easy->add_edge('d','e');$easy->add_edge('d','f');
    $easy->add_edge('e','f');
    $easy->add_edge('f','g');
    push @graphs, $easy;
  }
  {
    # Soltes J4, same as Beineke G5 = Soltes G4
    #    a---c
    #    |\ /|\
    #    | . | e---f
    #    |/ \|/
    #    b---d
    # hog not
    #
    my $easy = Graph::Easy->new (undirected => 1);
    $easy->set_attribute (label => 'J4');
    $easy->add_edge('a','b');$easy->add_edge('a','d');$easy->add_edge('a','c');
    $easy->add_edge('b','d');$easy->add_edge('b','c');
    $easy->add_edge('c','d');$easy->add_edge('c','e');
    $easy->add_edge('d','e');
    $easy->add_edge('e','f');
    push @graphs, $easy;
  }
  {
    # Soltes J6 = Claw = Star-4
    # https://hog.grinvin.org/ViewGraphInfo.action?id=500
    require Graph::Maker::Star;
    my $graph = Graph::Maker->new('star', G=>4, undirected=>1);
    $graph->set_graph_attribute (name => 'J6');
    push @graphs, $graph;
  }
  {
    # Lai and Soltes H4
    # [hog recheck]
    my $H4 = Graph_Lai_Soltes_H4();
    push @graphs, $H4;
  }
  hog_searches_html(@graphs);
  exit 0;
}

sub Graph_Lai_Soltes_H4 {
  # Lai and Soltes H4
  # https://hog.grinvin.org/ViewGraphInfo.action?id=21117
  require Graph::Maker::Cycle;
  my $H4 = Graph::Maker->new('cycle', N=>10, undirected=>1);
  $H4->set_graph_attribute (name => 'Lai and Soltes H4');
  foreach my $parity (0, 1) {
    for (my $i = 1; $i <= 10; $i += 2) {
      for (my $j = $i+2; $j <= 10; $j += 2) {
        $H4->add_edge($i+$parity,$j+$parity);
      }
    }
  }
  return $H4;
}

sub Graph_Soltes_J2  {
  # Soltes J2
  # https://hog.grinvin.org/ViewGraphInfo.action?id=21113
  #      a----e
  #     / \   |\
  #    b---c  | g--h
  #     \ /   |/
  #      d----f
  #
  require Graph;
  my $J2 = Graph->new (undirected => 1);
  $J2->set_graph_attribute (name => 'J2');
  $J2->add_edge('a','b');$J2->add_edge('a','c');$J2->add_edge('a','e');
  $J2->add_edge('b','c');$J2->add_edge('b','d');
  $J2->add_edge('c','d');
  $J2->add_edge('d','f');
  $J2->add_edge('e','f');$J2->add_edge('e','g');
  $J2->add_edge('f','g');
  $J2->add_edge('g','h');
  return $J2;
}
sub Graph_Soltes_J3 {
  # Soltes J3
  #      a---                  misprint should b--c so that Soltes G3
  #     / \   \                = Beineke G2 is a subgraph
  #    b---c   e
  #     \ / _/ |
  #      d-/---f----g
  # hog not
  #
  require Graph;
  my $J3 = Graph->new (undirected => 1);
  $J3->set_graph_attribute (name => 'J3');
  $J3->add_edge('a','b');$J3->add_edge('a','c');$J3->add_edge('a','e');
  $J3->add_edge('b','c');$J3->add_edge('b','d');
  $J3->add_edge('c','d');
  $J3->add_edge('d','e');$J3->add_edge('d','f');
  $J3->add_edge('e','f');
  $J3->add_edge('f','g');
  return $J3;
}







#------------------------------------------------------------------------------

sub Graph_theorem_of_the_day {
  my $g = Graph->new (undirected => 1);
  $g->add_edge('a','b'); $g->add_edge('a','d'); $g->add_edge('a','h');
  $g->add_edge('b','c'); $g->add_edge('b','d'); $g->add_edge('b','h');
  $g->add_edge('c','d'); $g->add_edge('c','e');
  $g->add_edge('c','g'); $g->add_edge('c','h');
  $g->add_edge('d','e'); $g->add_edge('d','f'); $g->add_edge('d','l');
  $g->add_edge('e','f'); $g->add_edge('e','l'); $g->add_edge('e','k');
  $g->add_edge('e','j'); $g->add_edge('e','g');
  $g->add_edge('f','l');
  $g->add_edge('g','j'); $g->add_edge('g','k'); $g->add_edge('g','l');
  $g->add_edge('g','i'); $g->add_edge('g','h');
  $g->add_edge('h','i'); $g->add_edge('h','l');
  $g->add_edge('i','l');
  $g->add_edge('j','k');
  $g->add_edge('k','l');
  $g->set_graph_attribute (name => 'Very Non-Line Graph');
  # $g->set_attribute('flow','south');
  # $g->set_attribute('root','a'); # for as_graphviz()
  # $g->{att}->{root} = 'a';       # for root_node() for as_ascii()
  return $g;
}
