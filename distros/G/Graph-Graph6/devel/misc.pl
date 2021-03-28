#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2021 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use 5.010;
use FindBin;
use File::Slurp;
use List::Util 'min','max';
use Graph;
use Graph::Writer::Graph6;
use Graph::Easy;
use Graph::Easy::As_graph6;
use Graph::Easy::Parser::Graph6;
use Graph::Graph6;
use IPC::Run;
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

BEGIN { unshift @INC, '../gmaker/lib'; }



{
  # sparse6 multiple self-loops
  my $graph = Graph->new (undirected => 1, multiedged=>1);
  $graph->add_edge(0,1);
  $graph->add_edge(0,2);
  $graph->add_edge(0,3);
  $graph->add_edge(0,0);
  $graph->add_edge(1,1);
  $graph->add_edge(2,2);
  $graph->add_edge(3,3);
  Graph::Writer::Graph6->new(format=>'sparse6')->write_graph($graph,'/dev/stdout');
  exit 0;
}
{
  # sparse6 multiple self-loops
  my $graph = Graph->new (undirected=>1, multiedged=>1);
  $graph->add_vertex(0);
  Graph::Writer::Graph6->new (format=>'graph6')->write_graph($graph,'/dev/stdout');
  Graph::Writer::Graph6->new (format=>'digraph6')->write_graph($graph,'/dev/stdout');
  Graph::Writer::Graph6->new (format=>'sparse6')->write_graph($graph,'/dev/stdout');
  $graph->add_edge(0,0);
  Graph::Writer::Graph6->new (format=>'sparse6')->write_graph($graph,'/dev/stdout');
  $graph->add_edge(0,0);
  Graph::Writer::Graph6->new (format=>'sparse6')->write_graph($graph,'/dev/stdout');
  $graph->add_edge(0,0);
  Graph::Writer::Graph6->new (format=>'sparse6')->write_graph($graph,'/dev/stdout');
  $graph->add_edge(0,0);
  Graph::Writer::Graph6->new (format=>'sparse6')->write_graph($graph,'/dev/stdout');
  exit 0;
}
{
  # exact sparse6 depends how many increment v vs bigger jumps

  # could start sparse6 encoding and stop if bigger than graph6 ...

  # sub output_size {
  #   my %options = @_;
  #   my $size = 0;
  #   if ($options{'header'}) {
  #     $size += length($format) + 4;
  #   }
  #   if ($format eq 'sparse6') {
  #   }
  # }
  exit 0;
}

{
  use Graph::Easy;
  my $graph = Graph::Easy->new (undirected => 1);
  $graph->add_edge('one', 'two');
  print $graph->is_undirected ? 1 : 0, "\n";
  print $graph->is_directed ? 1 : 0, "\n";
  print $graph->has_edge('one', 'two') ? 1 : 0, "\n";
  print $graph->has_edge('two', 'one') ? 1 : 0, "\n";
  exit 0;
}

{
  # Biregular a,b all degrees either a or b and bipartite so edges between
  # two distinct degree counts a,b.
  # Line graph is regular of degree a+b-2.
  #
  # n=5 2,3 complete bipartite
  #     graph https://hog.grinvin.org/ViewGraphInfo.action?id=264
  #     line https://hog.grinvin.org/ViewGraphInfo.action?id=746
  #          cylinder of two triangle ends
  # n=6 2,4 complete bipartite
  #     graph https://hog.grinvin.org/ViewGraphInfo.action?id=812
  #     line  not
  # n=7 2,5 complete bipartite
  #     graph https://hog.grinvin.org/ViewGraphInfo.action?id=866
  #     line  not
  # n=7 3,4 complete bipartite
  #     graph https://hog.grinvin.org/ViewGraphInfo.action?id=466
  #     line  not
  # n=8 3,5 complete bipartite
  #     graph not
  #     line  not
  # n=8 2,6 complete bipartite
  #     graph not
  #     line  not
  my @graphs;
  foreach my $num_vertices (1 .. 8) {
    print "n=$num_vertices ...\n";
    my $iterator_func = make_graph_iterator_edge_aref
      (num_vertices => $num_vertices,
       connected => 1,
       verbose => 0);
    while (my $edge_aref = $iterator_func->()) {
      next if edge_aref_is_regular($edge_aref); # graph not regular
      my $graph = Graph_from_edge_aref($edge_aref);
      next if $graph->is_acyclic;
      # next if Graph_is_regular($graph);

      my $line_graph = Graph_line_graph($graph);
      next unless Graph_is_regular($line_graph);

      # Graph_view($graph);
      # Graph_view($line_graph, synchronous=>1);
      my $num_vertices = $graph->vertices;
      my @line_vertices = $line_graph->vertices;
      my $num_edges    = $graph->edges;
      print "found n=$num_vertices e=$num_edges\n";
      my @degrees = edge_aref_degrees_distinct($edge_aref);
      print "  graph degrees ",join(',',@degrees),
        " a+b-2=",$degrees[0]+$degrees[1]-2,"\n";
      print "  line degree ",
        $line_graph->vertex_degree($line_vertices[0]),"\n";
      print "  $graph\n";
      push @graphs, $graph, $line_graph;
    }
    # last if @graphs;
  }
  hog_searches_html(@graphs);
  exit 0;

}

{
  require Graph::Maker::Complete;
  my $graph = Graph::Maker->new('complete', N=>6, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  print "$num_vertices $num_edges\n";
  exit 0;
}

{
  my $graph = Graph->new (undirected => 1);
  $graph->add_vertex(0);
  $graph->add_vertex(2);
  my $l = $graph->path_length(0,0);
  ### $l
  my $d = $graph->diameter;
  ### $d
  my $dd = $graph->diameter // 0;
  ### $dd
  exit 0;
}

{
  # degree >=2 counts, drawing
  # 1,3,11,62,510,7459
  # cf A069725 up to 62

  my $num_vertices = 5;

  require IPC::Run;
  my @args = ('-d2', # degree >=2
              $num_vertices);
  my $h = IPC::Run::start(['nauty-geng',@args], '>pipe', \*GENG);
  require Graph::Reader::Graph6;
  my $fh = \*GENG;
  my @array;

  require Graph::Maker::Complete;
  my $complete = Graph::Maker->new('complete', N=>$num_vertices);

  # my $parser = Graph::Easy::Parser::Graph6->new;
  # while (my $easy = $parser->from_file($fh)) {
  #   $easy->set_attribute('x-dot-overlap',"false");
  #   $easy->set_attribute('x-dot-splines',"true");
  #   # Graph_Easy_view($easy);
  #   push @array, $easy;
  # }

  my $reader = Graph::Reader::Graph6->new;
  my $count = 0;
 GRAPH: while (my $graph = $reader->read_graph($fh)) {
    {
      my $odd = 0;
      foreach my $v ($graph->vertices) {
        if ($graph->degree($v) % 2) {
          $odd++;
          next GRAPH if $odd > 2;
        }
      }
    }
    $count++;
    # Graph_view($graph);
    # push @array, $graph;
    # if (Graph_is_isomorphic($graph, $complete)) {
    #   $graph->set_graph_attribute (name => "complete $num_vertices");
    # }
  }
  print "count $count\n";
  hog_searches_html(@array);
  exit 0;
}


{
  # Gutman, Furtula, Petrovic n=12 vertices
  # maximum terminal Wiener index for k terminals
  #
  my @graphs;
  require Graph::Maker::Caterpillar;
  {
    # n=10 equal maximum  caterpillar 5,5
    # https://hog.grinvin.org/ViewGraphInfo.action?id=112
    my $graph = Graph::Maker->new('caterpillar', N_list=>[5,5], undirected=>1);
    $graph->set_graph_attribute (name => "n=10");
    $graph->set_graph_attribute('flow','east');
    push @graphs, $graph;
  }
  {
    # n=10 equal maximum  star 10
    # https://hog.grinvin.org/ViewGraphInfo.action?id=34
    require Graph::Maker::Star;
    my $graph = Graph::Maker->new('star', N=>10, undirected=>1);
    $graph->set_graph_attribute (name => "n=10");
    $graph->set_graph_attribute('flow','east');
    push @graphs, $graph;
  }

  {
    # n=11 unique maximum
    # is n=3*s+2 for s=3, case d k=2*s+3=9 pendent, ceil((s-1)/2)=1 of
    #
    # https://hog.grinvin.org/ViewGraphInfo.action?id=650
    my $graph = Graph::Maker->new('caterpillar', N_list=>[6,5],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=11");
    $graph->set_graph_attribute('flow','east');
    push @graphs, $graph;
  }

  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[3,1,1,1,1,1,1,3],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=4");
    $graph->set_graph_attribute('flow','east');
    push @graphs, $graph;
  }

  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[4,1,1,1,1,1,3],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=5");
    push @graphs, $graph;
  }
  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[3,2,1,1,1,1,3],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=5");
    push @graphs, $graph;
  }
  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[3,1,2,1,1,1,3],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=5");
    push @graphs, $graph;
  }
  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[3,1,1,2,1,1,3],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=5");
    push @graphs, $graph;
  }

  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[4,1,1,1,1,4],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=6");
    push @graphs, $graph;
  }

  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[5,1,1,1,4],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=7");
    push @graphs, $graph;
  }
  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[4,2,1,1,4],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=7");
    push @graphs, $graph;
  }
  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[4,1,2,1,4],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=7");
    push @graphs, $graph;
  }

  {
    # unique maximum n=12 k=8
    # https://hog.grinvin.org/ViewGraphInfo.action?id=426
    my $graph = Graph::Maker->new('caterpillar', N_list=>[5,1,1,5],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=8");
    push @graphs, $graph;
  }

  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[6,1,5],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=9");
    push @graphs, $graph;
  }
  {
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[5,2,5],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=9");
    push @graphs, $graph;
  }

  {
    # n=12 k=10 caterpillar 6,6 is overall maximum
    # https://hog.grinvin.org/ViewGraphInfo.action?id=36
    my $graph = Graph::Maker->new('caterpillar', N_list=>[6,6],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=12 k=10");
    push @graphs, $graph;
  }

  {
    # n=13 A
    # https://hog.grinvin.org/ViewGraphInfo.action?id=80
    my $graph = Graph::Maker->new('caterpillar', N_list=>[6,1,6],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=13 A");
    push @graphs, $graph;
  }
  {
    # n=13 B
    # https://hog.grinvin.org/ViewGraphInfo.action?id=38
    my $graph = Graph::Maker->new('caterpillar', N_list=>[7,6],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=13 B");
    push @graphs, $graph;
  }

  {
    # n=14 A
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[7,1,6],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=14 A");
    push @graphs, $graph;
  }
  {
    # n=14 B
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[6,2,6],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=14 B");
    push @graphs, $graph;
  }

  {
    # n=15
    # https://hog.grinvin.org/ViewGraphInfo.action?id=200
    my $graph = Graph::Maker->new('caterpillar', N_list=>[7,1,7],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=15");
    push @graphs, $graph;
  }

  {
    # n=16 A
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[7,1,1,7],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=16 A");
    push @graphs, $graph;
  }
  {
    # n=16 B
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[8,1,7],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=16 B");
    push @graphs, $graph;
  }
  {
    # n=16 C
    # hog not
    my $graph = Graph::Maker->new('caterpillar', N_list=>[7,2,7],
                                  undirected=>1);
    $graph->set_graph_attribute (name => "n=16 C");
    push @graphs, $graph;
  }


  hog_searches_html(@graphs);
  exit 0;
}

{
  {  # Star with N=0
    require Graph::Maker::Star;
    my $graph = Graph::Maker->new('star', N=>0, undirected=>1);
    my $num_vertices = $graph->vertices;
    print "N=0 num_vertices=$num_vertices  $graph\n";
  }
  {
    # Star with N=1
    require Graph::Maker::Star;
    my $graph = Graph::Maker->new('star', N=>1,
                                  undirected=>1,
                                 );
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "N=1 num_vertices=$num_vertices num_edges=$num_edges  $graph\n";
  }
  exit 0;
}

{
  my @num_edges_max = (1, 2, 4, 6, 9, 13, 17);
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@num_edges_max,
                           max_matches => undef);
  exit 0;
}

{
  #       4   5     3
  #        \ /      |
  # 9---1--11---2--10---0---8       0-10-11-1-9
  #        / \
  #       6   7
  my $edge_aref = [[0,8],[1,9],[0,10],[2,10],[3,10],[1,11],[2,11],[4,11],[5,11],[6,11],[7,11]];
  my $subgraph_edge_aref = [[0,1],[1,2],[2,3],[3,4],[1,5],[2,6]];
  my $ret = edge_aref_is_subgraph($edge_aref, $subgraph_edge_aref);
  print "$ret\n";
  exit 0;
}

{
  # trees

  # require Math::PlanePath::SierpinskiTriangle;
  # my $path = Math::PlanePath::SierpinskiTriangle->new;

  require Math::PlanePath::ToothpickTree;
  my $path = Math::PlanePath::ToothpickTree->new;

  my $depth = 5;
  my $n_lo = $path->n_start;
  my $n_hi = $path->tree_depth_to_n_end($depth);

  require Graph::Easy;
  my $graph = Graph::Easy->new();
  foreach my $n ($n_lo .. $n_hi) {
    foreach my $c ($path->tree_n_children($n)) {
      $graph->add_edge($n,$c);
    }
  }
  print "$graph\n";
  print $graph->as_ascii;
  print $graph->as_graphviz();
  exit 0;
}

#------------------------------------------------------------------------------
