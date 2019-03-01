#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
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
use Graph;
use List::Util 'min';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant::defer five => sub {
  #       1
  #      /|\
  #    /  4  \
  #   |   |   |
  #   |   3   |
  #   | /   \ |
  #   0-------2
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (name => "Five");
  $graph->add_cycle(0,1,2);
  $graph->add_path(0,3,4,1);
  $graph->add_path(2,3);
  return $graph;
};
use constant::defer octahedral => sub {
  # https://hog.grinvin.org/ViewGraphInfo.action?id=226
  #       4 deg=4
  #    /  |  \
  #   5---|---3      hexagon and triangles inside
  #   | \/ \/ |
  #   | /\ /\ |
  #   0---|---2
  #    \  |  / 
  #       1 deg=4
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (name => "Octahedral");
  $graph->add_cycle(0,1,2,3,4,5);
  $graph->add_cycle(0,4,2);
  $graph->add_cycle(5,1,3);
  return $graph;
};





{
  # n=34
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30703
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30705

  # at 5s
  my $vpar5s = [undef, 0, 1, 2, 3, 2, 5, 2, 7, 2, 9, 1, 11, 12, 11, 14, 11, 16, 19, 2, 19, 20, 19, 22, 19, 24, 19, 26, 18, 28, 29, 28, 31, 28, 33];

  # at 4s
  my $vpar4s = [undef, 0, 1, 2, 3, 2, 5, 2, 7, 2, 9, 1, 11, 12, 11, 14, 11, 16, 28, 18, 19, 20, 19, 22, 19, 24, 19, 26, 11, 28, 29, 28, 31, 28, 33];

  my $graph4s = MyGraphs::Graph_from_vpar($vpar4s, undirected=>1);
  my $graph5s = MyGraphs::Graph_from_vpar($vpar5s, undirected=>1);
  my $minimal_domsets_count = MyGraphs::Graph_tree_minimal_domsets_count($graph4s);
  print "$minimal_domsets_count\n";
  $minimal_domsets_count == 134432 or die;

  $minimal_domsets_count = MyGraphs::Graph_tree_minimal_domsets_count($graph5s);
  print "$minimal_domsets_count\n";
  $minimal_domsets_count == 132400 or die;

  # MyGraphs::Graph_print_tikz($graph);
  MyGraphs::hog_searches_html($graph4s,$graph5s);
  exit 0;
}
{
  # n=32 exceeding 2^(n/2)
  # Bi-star 4,5 and 4,4 subdivided and middle connected
  # pictures.tex
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30700

  my $vpar = [undef, 0,1,2,3,4,5,4,7,4,9,4,11,2,13,2,15,2,17,1,19,20,21,20,23,20,25,1,27,1,29,1,31];
  my $graph = MyGraphs::Graph_from_vpar($vpar, undirected=>1);
  $graph->is_undirected or die;
  $graph->is_acyclic or die;
  $graph->vertices == 32 or die;
  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);

  {
    require Graph::Maker::BiStar;
    my $a = Graph::Maker->new('bi_star', N=>4, M=>4, undirected=>1);
    my $b = Graph::Maker->new('bi_star', N=>4, M=>5, undirected=>1);
    $a = MyGraphs::Graph_subdivide($a);
    $b = MyGraphs::Graph_subdivide($b);
    # print MyGraphs::Graph_tree_minimal_domsets_count($a)," ",MyGraphs::Graph_minimal_domsets_count_by_pred($a),"\n";
    # print MyGraphs::Graph_tree_minimal_domsets_count($b)," ",MyGraphs::Graph_minimal_domsets_count_by_pred($b),"\n";
    my $a_num_vertices = $a->vertices;
    foreach my $edge ($b->edges) {
      $a->add_edge(map {'b'.$_} @$edge);
    }
    $a->add_edge(1, 'b1');
    # MyGraphs::Graph_view($b);
    MyGraphs::Graph_is_isomorphic($graph,$a) or die;
  }

  my $minimal_domsets_count
    = MyGraphs::Graph_tree_minimal_domsets_count($graph);
  print "$minimal_domsets_count\n";
  $minimal_domsets_count==65960 or die;

  # MyGraphs::Graph_print_tikz($graph);
  exit 0;
}

{
  # n=11 disconnected five and octahedral
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30693

  my $graph = octahedral()->copy;
  foreach my $edge (five()->edges) {
    $graph->add_edge($edge->[0].'b', $edge->[1].'b');
  }
  {
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }
  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==135 or die;

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=11, connected 21 edges
  # :JgAK`oAOk?cJ?G`qEOi^

  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(5,8,4,0,7,1);
  $graph->add_path(1,8,0);
  $graph->add_path(5,7,4);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=11 most minimal domsets of connected graphs
  # are octahedral and five cross connected
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30689
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30691

  my @strs = (':J`AgqRGUXHcNCPSPCWy^',
              ':J`A_zDeOhhcIYGapCXN'
              # ':JgAK`oAOk?cJ?G`qEOi^',
              # ':JgAGga_Kc@caGXXdMb'
             );
  my @graphs = map {MyGraphs::Graph_from_graph6_str($_)} @strs;

  MyGraphs::Graph_is_subgraph($graphs[0],$graphs[1]) or die;

  print "five       ",MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str(five()));
  print "octahedral ",MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str(octahedral()));

  my @hog = @graphs;
  foreach my $graph (@graphs) {
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }

  foreach my $graph (@graphs) {
    ### graph: "$graph"
    # my @maps = MyGraphs::Graph_is_induced_subgraph($graph, five(), all_maps=>1);
    my @maps = MyGraphs::Graph_is_induced_subgraph($graph, octahedral(), all_maps=>1);
    ### @maps
    my %seen;
    foreach my $map (@maps) {
      my $rest = $graph->copy;
      ### delete: values %$map
      $rest->delete_vertices(values %$map);
      ### rest: "$rest"
      my $canon_g6 = MyGraphs::graph6_str_to_canonical
        (MyGraphs::Graph_to_graph6_str($rest));
      next if $seen{$canon_g6}++;
      # MyGraphs::Graph_view($rest);
      push @hog, $rest;
    }
    print "\n";
  }
  # MyGraphs::Graph_view($graphs[7]->complement);
  MyGraphs::Graph_print_tikz($graphs[1]);

  MyGraphs::hog_searches_html(@hog);
  exit 0;
}
{
  # n=10 disconnected 4-cycle and octahedral
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30677

  my $graph = octahedral()->copy;
  $graph->add_cycle('c1','c2','c3','c4');
  {
    my $graph = $graph;
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }
  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==90 or die;

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=10 connected, most minimal domsets of connected graphs
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30675

  my $graph = MyGraphs::Graph_from_graph6_str(':IcAKWQJGhhcLK`s^');
  {
    my $graph = $graph;
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }
  {
    my $cross = five()->copy;
    foreach my $edge (five()->edges) {
      $cross->add_edge($edge->[0].'b', $edge->[1].'b');
    }
    $cross->add_edge('0','0b');
    $cross->add_edge('2','2b');
    MyGraphs::Graph_is_isomorphic($graph,$cross) or die;
  }

  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==87 or die;

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=9 disconnected 4-cycle and five
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30673

  my $graph = five()->copy;
  $graph->add_cycle('c1','c2','c3','c4');

  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==54 or die;

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=9 20 edges most minimal domsets of connected graphs
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30671

  my $graph = MyGraphs::Graph_from_graph6_str(':H`AK@qEQOqPGSsPDK^');
  {
    my $graph = $graph;
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }
  {
    my $cross = five()->copy;
    # MyGraphs::Graph_view($cross);
    $cross->add_cycle('c1','c2','c3','c4');
    $cross->add_edge('c1',0);  # 0
    $cross->add_edge('c2',1);  # 4
    $cross->add_edge('c2',4);
    $cross->add_edge('c2',3);
    $cross->add_edge('c3',1);  # 7
    $cross->add_edge('c3',3);
    $cross->add_edge('c3',2);
    $cross->add_edge('c4',4);  # 1
    $cross->add_edge('c4',2);
    MyGraphs::Graph_is_isomorphic($graph,$cross) or die;
  }

  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==51 or die;

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=9 19 edges most minimal domsets of connected graphs
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30669

  my $graph = MyGraphs::Graph_from_graph6_str(':H`AK?qFG[@cIYGaDL');
  {
    my $graph = $graph;
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }
  {
    my $cross = five()->copy;
    # MyGraphs::Graph_view($cross);
    $cross->add_cycle('c1','c2','c3','c4');
    $cross->add_edge('c1','c3');  # extra across cycle
    $cross->add_edge('c1',0);  # 2
    $cross->add_edge('c2',1);  # 5
    $cross->add_edge('c2',4);
    $cross->add_edge('c3',2);  # 8
    $cross->add_edge('c3',3);
    $cross->add_edge('c4',1);  # 6
    $cross->add_edge('c4',4);
    MyGraphs::Graph_is_isomorphic($graph,$cross) or die;
  }

  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==51 or die;

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=9 18 edges most minimal domsets of connected graphs
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30667

  my $graph = MyGraphs::Graph_from_graph6_str(':H`A_wa_K`WaEQG`cJ');

  {
    my $cross = five()->copy;
    # MyGraphs::Graph_view($cross);
    $cross->add_cycle('c1','c2','c3','c4');
    $cross->add_edge('c1',1);
    $cross->add_edge('c1',4);
    $cross->add_edge('c2',0);
    $cross->add_edge('c2',2);
    $cross->add_edge('c3',1);
    $cross->add_edge('c3',4);
    $cross->add_edge('c4',3);
    MyGraphs::Graph_is_isomorphic($graph,$cross) or die;
  }
  {
    my $cross = five()->copy;
    # MyGraphs::Graph_view($cross);
    $cross->add_cycle('c1','c2','c3','c4');
    $cross->add_edge('c1',1);
    $cross->add_edge('c1',3);
    $cross->add_edge('c2',1);
    $cross->add_edge('c2',4);
    $cross->add_edge('c3',0);
    $cross->add_edge('c3',2);
    $cross->add_edge('c4',4);
    MyGraphs::Graph_is_isomorphic($graph,$cross) or die;
  }
  {
    my $graph = $graph;
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }

  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==51 or die;

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=9 most minimal domsets of connected graphs, induced subgraphs
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30667
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30669
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30671

  my @strs = (':H`A_wa_K`WaEQG`cJ',
              ':H`AK?qFG[@cIYGaDL',
              ':H`AK@qEQOqPGSsPDK^');
  my @graphs = map {MyGraphs::Graph_from_graph6_str($_)} @strs;

  foreach my $graph (@graphs) {
    my @degrees = sort map {$graph->degree($_)} $graph->vertices;
    my $num_edges = $graph->edges;
    print "num edges $num_edges, degrees ",join(',',@degrees),"\n";
  }
  my $fourcycle = Graph->new (undirected => 1);
  $fourcycle->set_graph_attribute (name => "4-Cycle");
  $fourcycle->add_cycle(0,1,2,3);

  my $fourcycle_crossed = $fourcycle->copy;
  $fourcycle_crossed->set_graph_attribute (name => "4-Cycle Crossed");
  $fourcycle_crossed->add_edge(0,2);

  my @hog = @graphs;
  foreach my $subgraph (five(), octahedral(), $fourcycle, $fourcycle_crossed) {
    print $subgraph->get_graph_attribute ('name'), "\n";
    foreach my $i (0 .. $#graphs) {
      print "i=$i\n";
      my $graph = $graphs[$i];
      ### graph: "$graph"
      my @maps = MyGraphs::Graph_is_induced_subgraph($graph, $subgraph,
                                                     all_maps=>1);
      ### @maps
      my %seen;
      foreach my $map (@maps) {
        my $rest = $graph->copy;
        ### delete: values %$map
        $rest->delete_vertices(values %$map);
        ### rest: "$rest"
        my $canon_g6 = MyGraphs::graph6_str_to_canonical
          (MyGraphs::Graph_to_graph6_str($rest));
        next if $seen{$canon_g6}++;
        print "other\n>>graph6<<",$canon_g6;
        # MyGraphs::Graph_view($rest);
        push @hog, $rest;
      }
    }
    print "\n";
  }

  # MyGraphs::Graph_print_tikz($graphs[1]);
  # # MyGraphs::Graph_view($graphs[7]->complement);

  foreach my $i (0 .. $#graphs) {
    foreach my $j (0 .. $#graphs) {
      next if $i == $j;
      my $is_subgraph = MyGraphs::Graph_is_subgraph($graphs[$i],$graphs[$j]);

      if ($is_subgraph) {
        print "subgraph $i $j  $is_subgraph\n";
        my $rest = $graphs[$i]->copy;
        while ($is_subgraph =~ /(\d+)=(\d+)/g) {
          my $to = $2;
          $rest->delete_vertex($to);
        }
        # MyGraphs::Graph_view($rest);
      }
    }
  }
  # MyGraphs::Graph_print_tikz($graphs[0]);

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}


{
  # n=8 as two 4-cycles cross-connected
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30664

  my $graph = MyGraphs::Graph_from_graph6_str(':GaHgyMCUSTn');

  my $two = Graph->new (undirected => 1);
  $two->add_cycle(0,1,2,3);
  $two->add_cycle(4,5,6,7);
  $two->add_edge(0,5);  $two->add_edge(0,7);
  $two->add_edge(1,4);  $two->add_edge(1,5);
  $two->add_edge(2,6);
  $two->add_edge(3,4);
  MyGraphs::Graph_is_isomorphic($graph,$two) or die;
  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==36 or die;

  MyGraphs::hog_searches_html(':GaKM{UQ', $graph);
  exit 0;
}
{
  # n=7 most minimal domsets
  # https://hog.grinvin.org/ViewGraphInfo.action?id=868
  #    graphedron

  my $graph = MyGraphs::Graph_from_graph6_str(':FaqiBQRP^');
  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  print "minimal_domsets_count $minimal_domsets_count\n";
  $minimal_domsets_count==22 or die;
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=6 most minimal domsets
  # https://hog.grinvin.org/ViewGraphInfo.action?id=226

  my $graph = octahedral();
  # MyGraphs::Graph_view($graph);
  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  print "minimal_domsets_count $minimal_domsets_count\n";
  $minimal_domsets_count==15 or die;
  MyGraphs::Graph_is_isomorphic
      ($graph,MyGraphs::Graph_from_graph6_str(':Ea@_WGxGs')) or die;
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # n=5 most minimal domsets
  # https://hog.grinvin.org/ViewGraphInfo.action?id=438

  my $graph = five();
  my $minimal_domsets_count
    = MyGraphs::Graph_minimal_domsets_count_by_pred($graph);
  $minimal_domsets_count==9 or die;
  MyGraphs::hog_searches_html($graph);
  exit 0;
}


{
  # n=6 octahedral
  # my $graph = MyGraphs::Graph_from_graph6_str(':Eg@_WCb_QN');
  my $graph = MyGraphs::Graph_from_graph6_str(':Ea@cgGwCs');
  MyGraphs::Graph_print_tikz($graph);
  exit 0;
}


{
  # n=9 most minimal domsets of connected graphs
  # subtract induced 4-cycle
  # first and third 4-cycle and n=5 minimal
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30667
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30669
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30671

  my @strs = qw(
                 :HeAGga_COwBGU?PBH
                 :HeAGgBH?Gg@CKcPBIZ
                 :HeA?POAIG`caGXW@CSv
              );
  my @graphs = map {MyGraphs::Graph_from_graph6_str($_)} @strs;

  foreach my $graph (@graphs) {
    my %seen;
    my @vertices = $graph->vertices;
    foreach my $a (0 .. $#vertices) {

      foreach my $b (0 .. $#vertices) {
        next if $a==$b;
        next unless $graph->has_edge($vertices[$a],$vertices[$b]);

        foreach my $c (0 .. $#vertices) {
          next if $c==$a || $c==$b;
          next unless $graph->has_edge($vertices[$b],$vertices[$c]);
          next if $graph->has_edge($vertices[$a],$vertices[$c]);

          foreach my $d ($c+1 .. $#vertices) {
            next if $d==$a || $d==$b || $d==$c;
            next unless $graph->has_edge($vertices[$c],$vertices[$d]);
            next unless $graph->has_edge($vertices[$d],$vertices[$a]);
            next if $graph->has_edge($vertices[$b],$vertices[$d]);

            my $cycle = $graph->copy;
            $cycle->delete_vertices(grep {$_ ne $vertices[$a]
                                            && $_ ne $vertices[$b]
                                            && $_ ne $vertices[$c]
                                            && $_ ne $vertices[$d]} @vertices);
            $cycle->vertices == 4 or die;
            my $canon_g6 = MyGraphs::graph6_str_to_canonical
              (MyGraphs::Graph_to_graph6_str($cycle));
            # print "$vertices[$a], $vertices[$b], $vertices[$c], $vertices[$d]  $canon_g6";
            # MyGraphs::Graph_view($cycle, synchronous=>1);
            $canon_g6 eq "Cr\n" or die;

            my $sans = $graph->copy;
            $sans->delete_vertices($vertices[$a],
                                   $vertices[$b],
                                   $vertices[$c],
                                   $vertices[$d]);
            $sans->vertices == 5 or die;
            next unless $sans->is_connected;
            $canon_g6 = MyGraphs::graph6_str_to_canonical
              (MyGraphs::Graph_to_graph6_str($sans));
            next if $seen{$canon_g6}++;

            if ($canon_g6 eq "Dr[\n") {
              print "other n=5 minimal\n";
            }
            # MyGraphs::Graph_view($sans, synchronous=>1);
          }
        }
      }
    }
    print scalar(keys %seen)," others\n\n";
  }
  exit 0;
}

{
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle(0,1,2);
  $graph->add_path(0,3,4,1);
  $graph->add_path(2,3);
  my $canon_g6 = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print $canon_g6;
  MyGraphs::Graph_view($graph);
  exit 0;
}




{
  # Most Minimal Domsets in Graphs of n

  # n=4  4-cycle
  # n=5
  #       3---1--\
  #       |   |   |
  #       0---2-\ |
  #        \----- 4
  # https://hog.grinvin.org/ViewGraphInfo.action?id=438
  #    graphedron
  #
  # n=6 octahedral two tetrahedrons
  # https://hog.grinvin.org/ViewGraphInfo.action?id=226
  #
  # n=7
  # https://hog.grinvin.org/ViewGraphInfo.action?id=868
  #    graphedron
  #
  # n=8 two 4-cycles
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1415
  # and certain wheel type, or 4-cycles cross connected
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30664
  #
  # n=9 4-cycle and n=5
  #
  my @strs = qw(
                 :BcN
                 :CoKN
                 :Dg@_WCn
                 :Eg@_WCb_QN
                 :FkHI@IQL^

                 :Go@_YMb
                 :GkGChGwChGs

                 :Hg?K?qFG[?c
                 :Ig?K?qFG[?cJ?HA~
              );
  my @graphs = map {MyGraphs::Graph_from_graph6_str($_)} @strs;

  # MyGraphs::Graph_view($graphs[7]->complement);
  MyGraphs::Graph_print_tikz($graphs[6]->complement);

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}




{
  require Graph;
  foreach my $num_vertices (15) {
    my $target = 2**$num_vertices;
    my $iterator_func = MyGraphs::make_tree_iterator_edge_aref
      (num_vertices => $num_vertices);
    my $max_count = 0;
    my $max_reps = 0;
    my $i = 0;
    while (my $edge_aref = $iterator_func->()) {
      $i++;

      my $graph = Graph->new (undirected => 1);
      foreach my $edge (@$edge_aref) {
        foreach my $offset (0, $num_vertices) {
          $graph->add_edge ($edge->[0]+$offset, $edge->[1]+$offset)
        }
      }
      foreach my $attach (0 .. $num_vertices-1) {
        $graph->add_edge ($attach, $attach+$num_vertices);

        $graph->is_connected or die;
        $graph->is_acyclic or die;

        my $minimal_domsets_count
          = MyGraphs::Graph_tree_minimal_domsets_count($graph);
        if ($minimal_domsets_count > $max_count) {
          my $size = $graph->vertices;
          print "at $i size $size new high $minimal_domsets_count (target $target)\n";
          # MyGraphs::Graph_view($graph);
          print "vpar_minimal_domsets_count(",MyGraphs::Graph_vpar_str($graph),")\n";
          $max_count = $minimal_domsets_count;
          $max_reps = 0;
        }
        if ($minimal_domsets_count == $max_count) {
          $max_reps++;
        }
        $graph->delete_edge ($attach, $attach+$num_vertices);
      }
    }
    print "max count $max_count reps $max_reps\n";
  }
  exit 0;
}
{
  # complete binary tree minimal domsets count
  # not in OEIS: 2, 4, 41, 1438, 4897682,

  require Graph::Maker::BalancedTree;
  my $num_children = 2;
  foreach my $n (2 .. 6) {
    my $graph = Graph::Maker->new('balanced_tree',
                                  fan_out => $num_children, height => $n,
                                  undirected => 1,
                                 );
    my $minimal_domsets_count
      = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    # print "n=$n  $minimal_domsets_count\n";
    print "$minimal_domsets_count, ";
  }
  exit 0;
}
{
  # path minimal domsets count
  # 1,1,2,2,4,4,7,9,13,18,25,36,49
  # A253412 binary words with maximal set of 1s

  require Graph::Maker::Linear;
  my $num_children = 2;
  foreach my $n (5) {
    my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);
    my $minimal_domsets_count
      = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "n=$n  minimal domsets count $minimal_domsets_count";
  }
  exit 0;
}
{
  # n=12

  #    / *--*              2
  #   *--*--*--*--*        4
  #    \ *--*--*--*--*     5
  #              1 2 3 4 5 6 7 8 9 10 11 12
  # vpar  n=12   0 1 2 3 4 5 2 7 1  9 10 11

  require Graph;
  require Algorithm::ChooseSubsets;
  my $graph = Graph->new (undirected=>1);

  $graph->add_path('01','02','03','04','05','06');
  $graph->add_path(     '02','07','08');
  $graph->add_path('01','09','10','11','12');

  # $graph->add_path('01','02','03','04','05','12');
  # $graph->add_path('06','07','08','09',     '12');
  # $graph->add_path('10','11',               '12');

  # MyGraphs::Graph_view($graph);
  print "by pred ", MyGraphs::Graph_minimal_domsets_count_by_pred($graph),"\n";
  mindomset_parts_show($graph, '01', print=>1);

  foreach (1 .. 20) {
    my $minimal_domsets_count
      = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "count $minimal_domsets_count\n";
  }
  exit 0;

  sub is_domset_without_dom_notsole {
    my ($graph, $aref, $v) = @_;
    if (grep {$_==$v} @$aref) { return 0; }
    $graph = $graph->copy;
    my $extra = 'is_domset_without_sole';
    $graph->add_edge ($v, $extra);
    return MyGraphs::Graph_is_minimal_domset($graph, [$extra,@$aref]);
  }

  sub is_domset_with_notmin_unless_undom_above {
    my ($graph, $aref, $v) = @_;
    if (! grep {$_==$v} @$aref) { return 0; }
    if (MyGraphs::Graph_is_minimal_domset($graph,$aref)) { return 0; }
    $graph = $graph->copy;
    my $extra = 'is_domset_with_notmin_unless_undom_above';
    $graph->add_edge ($v, $extra);
    return MyGraphs::Graph_is_minimal_domset($graph, $aref);
  }

  sub mindomset_parts_show {
    my ($graph, $root, %options) = @_;
    my $total = 0;
    my $with        = 0;
    my $without_dom = 0;
    my $without_dom_notsole = 0;
    my $with_notmin_unless_undom_above = 0;
    my @vertices = sort $graph->vertices;
    my $it = Algorithm::ChooseSubsets->new(\@vertices);
    while (my $aref = $it->next) {
      if (is_domset_with_notmin_unless_undom_above($graph,$aref,$root)) {
        $with_notmin_unless_undom_above++;
      }

      if (MyGraphs::Graph_is_minimal_domset($graph,$aref)) {
        my $contains = sub {
          my ($v) = @_;
          return !! (grep {$_==$v} @$aref);
        };

        $total++;
        my $is_with = $contains->($root);
        my $is_without_dom = ! $is_with;
        my $is_without_dom_notsole = $is_without_dom
          && is_domset_without_dom_notsole($graph,$aref,$root);
        my $is_without_dom_sole = $is_without_dom
          && ! $is_without_dom_notsole;
        $with                += $is_with;
        $without_dom         += $is_without_dom;
        $without_dom_notsole += $is_without_dom_notsole;

        #       /-7--8            2
        #   1--2--3--4--5--6      6
        #    \-9-10-11-12         4

        my $show = sub {
          my ($v) = @_;
          return $contains->($v) ? '*' : '.';
        };
        if ($options{'print'}) {
          print "    /-",$show->('07'),"--",$show->('08'),"    ",$is_without_dom_sole?' sole':'',"\n";
          print $show->('01'),"--",$show->('02'),"--",$show->('03'),"--",$show->('04'),"--",$show->('05'),"--",$show->('06'),"\n";
          print " \\-",$show->('09'),"--",$show->('10'),"--",$show->('11'),"--",$show->('12'),"\n";
          print "\n";
        }
      }
    }
    my $without_dom_sole = $without_dom - $without_dom_notsole;
    ### $with_notmin_unless_undom_above
    ### $with
    ### $without_dom
    ### $without_dom_sole
    ### $without_dom_notsole
    ### $total
  }
}
{
  # path minimal domsets parts
  # 2+4+5 + 1 == 12

  # p1      with_notmin_unless_undom_above_gross => 6
  #         without_undom => 2
  #         with_notmin_unless_undom_above = 4
  # path-4  without_undom => 1
  #
  # p1      without_undom => 2
  # path-4  with_notmin_unless_undom_above_gross => 1
  #         without_undom => 1
  #         with_notmin_unless_undom_above = 0


  require Algorithm::ChooseSubsets;
  require Graph::Maker::Linear;
  my @path_graphs;
  my @data;
  foreach my $n (0 .. 7) {
    my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);
    my $data = MyGraphs::Graph_tree_minimal_domsets_count_data($graph);
    printf "n=%2d   %s  %2s-%2s  %2s-%s  %s  notmin %s\n",
      $n,
      $data->{'with_req_notbelow'},
      $data->{'with_req_below_gross'}, $data->{'with_req_below_sub'},
      $data->{'without_dom_notsole_gross'}, $data->{'without_undom'},
      $data->{'without_dom_sole'},
      $data->{'with_notmin_unless_undom_above_gross'};
    $data[$n] = $data;
    $path_graphs[$n] = $graph;
  }

  # n= 2   0   1- 0   1-0  0
  # n= 4   1   2- 1   2-1  1
  # n= 5   0   2- 0   2-0  0

  #       /-*--*            2
  #   *--*--*--*--*--*      6
  #    \-*--*--*--*         4

  ### path-2 ...
  ### data: $data[2]

  ### path-4 ...
  ### data: $data[4]

  my $p1 = MyGraphs::tree_minimal_domsets_count_data_product($data[4],$data[2]);
  ### $p1
  ### p1 with_notmin_unless_undom_above: $p1->{'with_notmin_unless_undom_above_gross'} - $p1->{'without_undom'}
  ### p1 without_dom_sole   : $p1->{'without_dom_sole'}
  ### p1 without_dom_notsole: $p1->{'without_dom_notsole_gross'} - $p1->{'without_undom'}
  ### p1 without_dom        : $p1->{'without_dom_notsole_gross'} - $p1->{'without_undom'} + $p1->{'without_dom_sole'}
  my $p1_ret    = MyGraphs::tree_minimal_domsets_count_data_ret($p1);
  my $path7_ret = MyGraphs::tree_minimal_domsets_count_data_ret($data[7]);
  ### p1        : "$p1_ret"
  ### cf path-7 : "$path7_ret"

  ### p1 ...
  mindomset_parts_show($path_graphs[7], '3', print=>0);

  ### path-4: $data[4]

  my $r = MyGraphs::tree_minimal_domsets_count_data_product($p1, $data[4]);
  ### $r
  ### r with       : $r->{'with_req_notbelow'} + $r->{'with_req_below_gross'} - $r->{'with_req_below_sub'}
  ### r without dom: $r->{'without_dom_notsole_gross'} - $r->{'without_undom'} + $r->{'without_dom_sole'}
  ### r without dom sole   : $r->{'without_dom_sole'}
  ### r without dom notsole: $r->{'without_dom_notsole_gross'} - $r->{'without_undom'}

  my $minimal_domsets_count = MyGraphs::tree_minimal_domsets_count_data_ret($r);
  ### $minimal_domsets_count

  exit 0;
}


{
  # v_mindomsets = v_with + v_without_dom
  #
  # v_with =   prod(c_with_req_below + c_without)
  #          - prod(c_with_req_below)
  # at least one c_without
  #
  # v_without_dom =   prod(c_without_dom + c_with)
  #                 - prod(c_without_dom)
  # at least one c_with
  #
  # v_without_dom += exactly_one_notmin
  # exactly_one_notmin = exactly_one_notmin * c_without_dom
  #                    + prod_c_without_dom * c_with_notmin_unless_undom_above
  # prod_c_without_dom *= c_without_dom

  #           0 1 2 3 4 5 6 7  8  9 10
  # want path 1,1,2,2,4,4,7,9,13,18,25,36,49,70,97,137,191,268,376,526,738,

  #             0 1 2 3 4
  # want binary 1,2,4,41,1438

  # leaf
  my $v_with_req_notbelow       = 1;
  my $v_with_req_below      = 0;
  my $v_with_notmin_unless_undom_above = 0;
  my $v_without_dom_sole    = 0;
  my $v_without_dom_notsole = 0;
  my $v_without_undom       = 1;
  my $fan = 1;

  {
    my $n = 1;
    my $v_mindomsets = $v_with_req_notbelow + $v_with_req_below
      + $v_without_dom_sole + $v_without_dom_notsole;
    print "n=$n mindomsets $v_mindomsets  with $v_with_req_notbelow+$v_with_req_below  without $v_without_dom_sole+$v_without_dom_notsole+$v_without_undom    req below $v_with_req_below notmin unless $v_with_notmin_unless_undom_above\n";
  }

  foreach my $n (2 .. 8) {
    my $c_without_dom_sole    = $v_without_dom_sole;
    my $c_without_dom_notsole = $v_without_dom_notsole;
    my $c_without_undom       = $v_without_undom;
    my $c_with_req_notbelow       = $v_with_req_notbelow;
    my $c_with_req_below      = $v_with_req_below;
    my $c_with                = $c_with_req_notbelow + $c_with_req_below;
    my $c_with_notmin_unless_undom_above = $v_with_notmin_unless_undom_above;
    my $c_without_dom = $c_without_dom_sole + $c_without_dom_notsole;

    ### $n
    ### $c_with_req_notbelow
    ### $c_with_req_below
    ### $c_with
    ### $c_with_notmin_unless_undom_above
    ### $c_without_dom_sole
    ### $c_without_dom_notsole
    ### $c_without_undom

    #----

    # =0 child undom
    $v_with_req_notbelow = ($c_without_dom_notsole)**$fan;

    # >=1 child undom
    $v_with_req_below
      = ($c_with_req_below + $c_without_dom_notsole + $c_without_undom)**$fan
      - ($c_with_req_below + $c_without_dom_notsole                   )**$fan;


    # =1 child with notmin unless undom above,
    # this v without cannot be re-dominated above
    $v_without_dom_sole
      = $fan* $c_without_dom**($fan-1) * $c_with_notmin_unless_undom_above;

    # =0 child with
    $v_without_undom = $c_without_dom**$fan;

    # >=1 child with
    $v_without_dom_notsole
      = ($c_with           + $c_without_dom)**$fan
      - $v_without_undom;
    # - (                    $c_without_dom)**$fan;

    # at least one c_with
    $v_with_notmin_unless_undom_above
      = ($c_with_req_below + $c_without_dom)**$fan
      - $v_without_undom;
    #   (                    $c_without_dom)**$fan;

    my $v_with        = $v_with_req_notbelow + $v_with_req_below;
    my $v_without_dom = $v_without_dom_sole + $v_without_dom_notsole;
    my $v_mindomsets = $v_with + $v_without_dom;

    print "n=$n mindomsets $v_mindomsets  with $v_with  without $v_without_dom_sole + $v_without_dom_notsole + $v_without_undom  req below $v_with_req_below notmin unless $v_with_notmin_unless_undom_above\n";
  }

  # with = (1 + 3) - 1 = 3
  # 1,3,5
  # 2,3,5 <-- not minimal
  #  2, 5

  exit 0;
}

{
  # counts of minimal dominating sets

  # h=2 complete binary tree
  # 1              1 1,0 plus 1      with
  # 2,3            1 0,1 plus 0      without notsole
  # none without undom

  # h=3 complete binary tree
  # 1,4,5,6,7      1 1,0 plus 1      with, and is req below
  # 2,3            1 0,1 plus 0      without notsole
  # 2,6,7          1 0,1 plus 0      without notsole
  # 3,4,5          1 0,1 plus 0      without notsole
  # 4,5,6,7                          without undom
  # 1,2,3          0 0,0 plus 1
  # 1,2,6,7        0 0,0 plus 1
  # 1,3,4,5        0 0,0 plus 1
  #
  #  with req   without   undom
  # (    1    +   1     +  0)^2 = 4    - 1^2 = 3
  # 1,4,5,3    not minimal, as 1 covered
  # 1,2,6,7    not minimal, as 1 covered

  # n=4 path
  # 1,4            1 1,0 plus 1      with
  # 2,4            1 0,1 plus 0      with
  # 1,3            1 1,0 plus 1      without dom notsole
  # 2,3            1 0,1 plus 0      without dom sole
  #  2                               without undom

  # n=5 path with 2, without 2
  # 1,3,5          1 1,0 plus 1      with
  # 2,5            1 0,1 plus 0      with
  # 1,4            1 1,0 plus 1      without dom notsole
  # 2,4            1 0,1 plus 0      without dom notsole
  #  1,3                             without undom   from 4 without dom notsole
  #  2,3                             without undom   from 4 without dom sole
  # 1,2,5          0 0,0 plus 1
  # minimal domsets         4
  # minimal domsets with    2
  # minimal domsets without 2

  # n=6 path
  # 1,4,6          1 1,0 plus 1      with   from 5 dom notsole
  # 2,4,6          1 0,1 plus 0      with   from 5 dom notsole
  # 1,3,6          1 1,0 plus 1      with   from 5 undom
  # 2,3,6          1 0,1 plus 0      with   from 5 undom
  # 2,5            1 0,1 plus 0      without notsole
  # 1,3,5          1 1,0 plus 1      without notsole
  # 1,4,5          1 1,0 plus 1      without sole
  # 1,2,5          0 0,0 plus 1      without undom


  require Algorithm::ChooseSubsets;
  require Graph::Maker::BalancedTree;
  require Graph::Maker::Linear;
  my $num_children = 2;
  my $n = 2;
  my $graph = Graph::Maker->new('balanced_tree',
                                fan_out => $num_children, height => $n,
                                undirected => 1,
                               );
  # my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);

  my $root = 1;
  my $graph_plus = $graph->copy;
  $graph_plus->add_edge ($root,'extra');

  # MyGraphs::Graph_view($graph);
  print "graph $graph\n";
  print "graph_plus $graph_plus\n";

  my @vertices = sort {$a<=>$b} $graph->vertices;
  my $it = Algorithm::ChooseSubsets->new(\@vertices);
  my $count_domsets = 0;
  my $count_minimal_domsets = 0;
  my $count_minimal_domsets_with = 0;
  my $count_minimal_domsets_without = 0;
  while (my $aref = $it->next) {
    my $any = 0;

    my $is_domset = MyGraphs::Graph_is_domset($graph,$aref) ? 1 : 0;
    # $any ||= $is_domset;
    $count_domsets += $is_domset;

    my $is_minimal_domset = MyGraphs::Graph_is_minimal_domset($graph,$aref)?1:0;
    $any ||= $is_minimal_domset;
    $count_minimal_domsets += $is_minimal_domset;

    my $includes_root = grep {$_ eq $root} @$aref;
    my $is_minimal_domset_with    =  $includes_root & $is_minimal_domset;
    my $is_minimal_domset_without = !$includes_root & $is_minimal_domset;

    $count_minimal_domsets_with    += $is_minimal_domset_with;
    $count_minimal_domsets_without += $is_minimal_domset_without;

    my $plus_is_minimal_domset = MyGraphs::Graph_is_minimal_domset($graph_plus,$aref)?1:0;
    $any ||= $plus_is_minimal_domset;

    if ($any) {
      my $aref_str = join(',',@$aref);
      printf "%-14s %d %d %d,%d plus %d\n",
        $aref_str, $is_domset,
        $is_minimal_domset, $is_minimal_domset_with,$is_minimal_domset_without,
        $plus_is_minimal_domset;
    }
  }
  print "domsets $count_domsets\n";
  print "minimal domsets         $count_minimal_domsets\n";
  print "minimal domsets with    $count_minimal_domsets_with\n";
  print "minimal domsets without $count_minimal_domsets_without\n";
  exit 0;
}
{
  # try Graph_tree_minimal_domsets_count()

  # 81 pairs 19,20  1649265868801
  # 12161^3      == 1798489329281
  # k=3  count      1798489329281

  require Graph;
  require Math::BigInt;
  Math::BigInt->import(try=>'GMP');
  # for (my $n = 9; $n <= 55; $n += 2) {
  foreach my $n (3*27) {
    my $max_count = 0;
    my $max_L_pairs = 0;
    my $max_R_pairs = 0;
    my $pairs = ($n-3)/2;
    foreach my $L_pairs (0 .. int($pairs/2)) {
      my $R_pairs = $pairs - $L_pairs;
      my $graph = make_T1 ($L_pairs, $R_pairs);
      my $minimal_domsets_count
        = MyGraphs::Graph_tree_minimal_domsets_count($graph);
      print "n=$n pairs $L_pairs+$R_pairs = $pairs  count $minimal_domsets_count\n";

      if ($max_count < $minimal_domsets_count) {
        $max_count = $minimal_domsets_count;
        $max_L_pairs = $L_pairs;
        $max_R_pairs = $R_pairs;
      }
    }
    print "max L_pairs $max_L_pairs R_pairs $max_R_pairs  count $max_count\n";
    print "\n";
  }
  exit 0;

  sub make_T1 {
    my ($L_pairs, $R_pairs, $k) = @_;
    $k ||= 1;
    my @pairs = shift; push @pairs, shift;
    my $graph = Graph->new (undirected => 1);
    my $from;
    foreach my $kk (1 .. $k) {
      foreach my $side (0,1) {
        my $side_name = ($side == 0 ? 'L' : 'R');
        foreach my $i (1 .. $pairs[$side]) {
          $graph->add_path ("${side_name}_leaf_${i}_k$kk",
                            "${side_name}_mid_${i}_k$kk",
                            "${side_name}_k$kk");
        }
      }
      $graph->add_path ("L_k$kk","T_k$kk","R_k$kk");
      if (defined $from) {
        my $to = "L_mid_1_k$kk";
        $graph->add_edge ($from, $to);
      }
      $from = "R_mid_1_k$kk",
    }
    return $graph;
  }
}
{
  # n=27 minimal_domsets_count max
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28551

  # non maximum, arms length 4
  # my $graph = MyGraphs::Graph_from_graph6_str(':Z_`abc`e`g`i`k_mnopmrmtmvmx');

  # maximum, 6,6
  my $graph = MyGraphs::Graph_from_graph6_str(':Z_`a`c`e`g`i`k_mnmpmrmtmvmx');
  MyGraphs::Graph_view($graph);
  print MyGraphs::Graph_tree_minimal_domsets_count($graph),"\n";
  MyGraphs::hog_searches_html($graph);

  # MyGraphs::Graph_view($graph);
  foreach (1 .. 20) {
    my $minimal_domsets_count
      = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "count $minimal_domsets_count\n";
  }
  exit 0;
}
{
  # try Graph_tree_minimal_domsets_count()

  # 81 pairs 19,20  1649265868801
  # 12161^3      == 1798489329281

  require Graph;
  require Math::BigInt;
  Math::BigInt->import(try=>'GMP');
  require Math::BigFloat;
  my $base;
  foreach my $k (1 .. 5) {
    my $graph = make_T1 (6,6,$k);
    my $num_vertices = $graph->vertices;
    # MyGraphs::Graph_view($graph);
    my $count = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "k=$k  count $count  n=$num_vertices\n";

    if ($k==1) { $base = $count; }
    else {
      my $pow = $base ** $k;
      print "           $pow\n";
      my $two = Math::BigFloat->new(2)**(($num_vertices)/2);
      print "   2^(n/2) $two\n";
    }
  }

  my $graph = make_T1 (19,20);
  my $minimal_domsets_count
    = MyGraphs::Graph_tree_minimal_domsets_count($graph);
  my $num_vertices = $graph->vertices;
  print "$num_vertices   count $minimal_domsets_count\n";
  exit 0;
}
