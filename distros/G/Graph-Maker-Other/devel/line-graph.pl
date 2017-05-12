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
use 5.010;
use FindBin;
use File::Slurp;
use List::Util 'min','max';
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;




{
  # graphs count possible claw in N vertices
  # with            0,0,0,1, 7, 62,662,10236
  # without A022562 1,1,2,5,14, 50,191,  881,  4494,   26389,     184749,
  # total   A001349 1,1,2,6,21,112,853,11117,261080,11716571, 1006700565,
  #
  # trees count possible claw in N vertices
  # with    A144520  0,0,0,1,2,5,10,22,46,105,234,550
  #         = A000055-1 num trees, as only path-N is claw-free
  # without 1,1,1,1,1,1,1,1,1,1,1,1
  # total   A000055 1,1,1,2,3,6,11,23,47,106,235,551
  #
  my @count_with;
  my @count_without;
  my @count_total;
  foreach my $num_vertices (1 .. 12) {
    my $count_with = 0;
    my $count_without = 0;
    my $count_total = 0;

    # my $iterator_func = make_tree_iterator_edge_aref
    #   (num_vertices => $num_vertices,
    #    connected => 1);
    my $iterator_func = make_graph_iterator_edge_aref
      (num_vertices => $num_vertices,
       connected => 1);
    while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      if (Graph_has_claw($graph)) {
        $count_with++;
      } else {
        $count_without++;
      }
      $count_total++;
    }
    push @count_with, $count_with;
    push @count_without, $count_without;
    push @count_total, $count_total;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@count_with, verbose=>1, name=>'with');
  Math::OEIS::Grep->search(array => \@count_without, verbose=>1, name=>'without');
  Math::OEIS::Grep->search(array => \@count_total, verbose=>1, name=>'total');

  exit 0;
}
{
  # count graphs with or without a triangle being even,odd or any type triangle
  # even     0,0,1,1, 5, 24, 181, 1997
  # odd      0,0,0,2,13, 90, 790,10845
  # any      1,1,3,9,36,205,1647,21967
  # non      1,1,1,3, 6, 19,  59,  267    A024607 connected triangle-free

  my @count_even;
  my @count_odd;
  my @count_any;
  my @count_non;
  foreach my $num_vertices (1 .. 8) {
    my $count_even = 0;
    my $count_odd = 0;
    my $count_any = 0;
    my $count_non = 0;

    my $iterator_func = make_graph_iterator_edge_aref
      (num_vertices => $num_vertices,
       connected => 1);
    while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      # next if $graph->is_acyclic;

      my $any;
      my $any_even;
      my $any_odd;
      Graph_find_induced_triangle
        ($graph,
         pred => sub {
           my ($graph, $a,$b,$c) = @_;
           my $e = Graph_triangle_is_even($graph, $a,$b,$c);
           if ($e) { $any_even = 1; }
           else    { $any_odd = 1; }
           $any = 1;
           return 0;  # continue
         });

      $count_any++;
      if ($any)      { $count_any++; }
      else           { $count_non++; }
      if ($any_even) { $count_even++; }
      if ($any_odd)  { $count_odd++; }

      # if ($num_vertices == 5 && $any_even) {
      #   Graph_view($graph);
      # }
    }

    push @count_even, $count_even;
    push @count_odd, $count_odd;
    push @count_any, $count_any;
    push @count_non, $count_non;

    print "n=$num_vertices  $count_even, $count_odd, $count_any, $count_non\n";
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@count_even, verbose=>1, name=>'even');
  Math::OEIS::Grep->search(array => \@count_odd, verbose=>1, name=>'odd');
  Math::OEIS::Grep->search(array => \@count_any, verbose=>1, name=>'any');
  Math::OEIS::Grep->search(array => \@count_non, verbose=>1, name=>'non');

  exit 0;

  # Find an induced triangle in $graph and return its vertices ($a,$b,$c).
  # pred=>$coderef is called $coderef->($graph,$a,$b,$c) on a triangle found
  # and if false that triangle is not returned.
  #        b
  #      / |
  #    a   |
  #      \ |
  #        c
  sub Graph_find_induced_triangle {
    my ($graph, %options) = @_;
    my $pred = $options{'pred'};
    foreach my $a ($graph->vertices) {
      my @a_neighbours = $graph->neighbours($a);

      foreach my $bi (0 .. $#a_neighbours-1) {
        my $b = $a_neighbours[$bi];

        foreach my $ci ($bi+1 .. $#a_neighbours) {
          my $c = $a_neighbours[$ci];
          next unless $graph->has_edge($b,$c);

          if ($pred) { next unless $pred->($graph, $a, $b, $c); }
          return ($a,$b,$c);
        }
      }
    }
    return;  # not found
  }
}

{
  # line graph conditions van Rooij and Wilf, vs Beineke
  my $iterator_func = make_graph_iterator_edge_aref
    (num_vertices_min => 1,
    );
  while (my $edge_aref = $iterator_func->()) {
    my $graph = Graph_from_edge_aref($edge_aref);

    {
      my $l1 = Graph_is_line_graph_by_van_Rooij_Wilf($graph);
      my $l2 = Graph_is_line_graph_by_Beineke($graph);
      if ($l1 != $l2) {
        my $i = Graph_van_Rooij_Wilf_condition_i($graph);
        my $ii = ! Graph_has_claw($graph) ? 1 : 0;
        my @list = Graph_Beineke_subgraph_list($graph);
        print "$l1($i,$ii) vs $l2(",join(',',@list),")\n";
        my $g6_str = Graph_to_graph6_str($graph);
        print $g6_str;
        Graph_view($graph, synchronous=>1);
      }
    }
  }
  exit 0;

  sub Graph_is_line_graph_by_van_Rooij_Wilf {
    my ($graph) = @_;
    return (Graph_van_Rooij_Wilf_condition_i($graph)
            && ! Graph_has_claw($graph)
            ? 1 : 0);
  }

  BEGIN {
    my @G_graphs;
    require Graph::Maker::Beineke;
    @G_graphs = map {
      Graph::Maker->new('Beineke', G=>$_, undirected=>1)
      } 1 .. 9;

    # return a list of integers 1,...,9 which are the Beineke graphs which
    # are induced subgraphs of $graph
    sub Graph_Beineke_subgraph_list {
      my ($graph) = @_;
      my @list;
      foreach my $i (0 .. $#G_graphs) {
        if (Graph_is_induced_subgraph($graph, $G_graphs[$i])) {
          push @list, $i+1;
        }
      }
      return @list;
    }
  }
  
  # Return true if every adjacent induced pair of triangles has at least one
  # of the pair an even triangle.  Or equivalently there are no induced
  # pairs of triangles both odd.
  sub Graph_van_Rooij_Wilf_condition_i {
    my ($graph) = @_;
    my $good = 1;
    my @triangles = Graph_find_two_induced_adjacent_triangles
      ($graph,
       pred => sub {
         my ($graph, $a,$b,$c,$d) = @_;
         ### i pred: "$a,$b,$c,$d"
         if (Graph_triangle_is_even($graph, $a,$b,$c)
             || Graph_triangle_is_even($graph, $d,$b,$c)) {
           ### good ...
           $good = 1;
           return 0;  # continue
         } else {
           ### bad, both odd ...
           $good = 0;
           return 1;  # stop
         }
       });
    ### i final: $good
    return $good;
  }

  #        b
  #      / | \
  #    a   |   d
  #      \ | /
  #        c
  sub Graph_find_two_induced_adjacent_triangles {
    my ($graph, %options) = @_;
    my $pred = $options{'pred'};
    foreach my $b ($graph->vertices) {
      my @b_neighbours = $graph->neighbours($b);
      ### $b
      ### neighbours: join(' ',@b_neighbours)

      foreach my $ai (0 .. $#b_neighbours) {
        my $a = $b_neighbours[$ai];
        ### try: "$a $b"

        foreach my $ci (0 .. $#b_neighbours) {
          next if $ci == $ai;
          my $c = $b_neighbours[$ci];
          ### try: "$a $b $c"
          next unless $graph->has_edge($a,$c);

          foreach my $di (0 .. $#b_neighbours) {
            next if $di == $ai || $di == $ci;
            my $d = $b_neighbours[$di];

            ### try: "$a $b $c $d"
            unless ($graph->has_edge($c,$d)) {
              ### no edge: "$c $d"
              next;
            }
            if ($graph->has_edge($a,$d)) {
              ### has edge: "$a $d"
              next;
            }

            if ($pred) { next unless $pred->($graph, $a, $b, $c, $d); }
            return ($a,$b,$c,$d);
          }
        }
      }
    }
    return;  # not found
  }

  sub Graph_two_adjacent_triangles_are_both_even {
    my ($graph, $a,$b,$c,$d) = @_;
    return Graph_triangle_is_even($graph, $a,$b,$c)
      &&   Graph_triangle_is_even($graph, $d,$b,$c);
  }
}
{
  # count graphs with induced pair of triangles (not in OEIS)
  # even_even  0,0,0,1,2, 9, 50, 423
  # even_odd   0,0,0,0,3,21,177,1992
  # odd_odd    0,0,0,0,3,49,599,9742
  # total      0,0,0,1,8,66,659,9979
  # n=4 vertices is the pair of adjacent triangles only
  # cf A006785 number of triangle-free graphs

  my @count_even_even;
  my @count_even_odd;
  my @count_odd_odd;
  my @count_total;
  foreach my $num_vertices (1 .. 8) {
    my $count_even_even = 0;
    my $count_even_odd = 0;
    my $count_odd_odd = 0;
    my $count_total = 0;

    my $iterator_func = make_graph_iterator_edge_aref
      (num_vertices => $num_vertices);
    while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      # next if $graph->is_acyclic;

      my $any;
      my $any_even_even;
      my $any_even_odd;
      my $any_odd_odd;
      Graph_find_two_induced_adjacent_triangles
        ($graph,
         pred => sub {
           my ($graph, $a,$b,$c,$d) = @_;
           $any = 1;
           my $e1 = Graph_triangle_is_even($graph, $a,$b,$c);
           my $e2 = Graph_triangle_is_even($graph, $d,$b,$c);
           if ($e1 && $e2) { $any_even_even = 1; }
           if (!$e1 && !$e2) { $any_odd_odd = 1; }
           if (($e1 && !$e2)
               || (!$e1 && $e2)) { $any_even_odd = 1; }
           return 0;  # continue
         });

      if ($any) { $count_total++; }
      if ($any_even_even) { $count_even_even++; }
      if ($any_even_odd) { $count_even_odd++; }
      if ($any_odd_odd) { $count_odd_odd++; }

      if ($num_vertices == 5 && $any_even_even) {
        Graph_view($graph);
      }
    }
    # $count_even_even
    #   + $count_even_odd
    #   + $count_odd_odd
    #   == $count_total or die "not $count_even_even + $count_even_odd + $count_odd_odd == $count_total";

    push @count_even_even, $count_even_even;
    push @count_even_odd, $count_even_odd;
    push @count_odd_odd, $count_odd_odd;
    push @count_total, $count_total;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@count_even_even, verbose=>1, name=>'even_even');
  Math::OEIS::Grep->search(array => \@count_even_odd, verbose=>1, name=>'even_odd');
  Math::OEIS::Grep->search(array => \@count_odd_odd, verbose=>1, name=>'odd_odd');
  Math::OEIS::Grep->search(array => \@count_total, verbose=>1, name=>'total');

  exit 0;
}

{
  # octahedral, two pyramids
  # https://hog.grinvin.org/ViewGraphInfo.action?id=226
  #
  # wheel-5 (subgraph by deleting 1 vertex)
  # https://hog.grinvin.org/ViewGraphInfo.action?id=442
  #
  # diamond/kite (subgraph by deleting 2 adjacent vertices)
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28

  require Graph::Maker::Wheel;
  require Graph::Maker::Complete;
  my $octahedral = Graph_make_octahedral (undirected => 1);
  my $wheel = Graph::Maker->new('wheel', N=>5, undirected => 1);
  $wheel->set_graph_attribute (name => "Wheel");
  my $kite = Graph_make_kite (undirected => 1);
  my $complete = Graph::Maker->new('complete', N=>4, undirected => 1);

  # complete-4 line graph is octahedral
  {
    my $s = Graph_line_graph($complete);
    my $iso = Graph_is_isomorphic($s,$octahedral);
    print "complete line $iso\n";
    $iso or die;
  }

  # kite line graph giving is wheel
  {
    my $s = Graph_line_graph($kite);
    my $iso = Graph_is_isomorphic($s,$wheel);
    print "wheel line $iso\n";
    $iso or die;
  }

  # hanging line graph giving is wheel
  {
    my $hanging = Graph->new (undirected => 1);
    $hanging->set_graph_attribute (name => "Hanging");
    $hanging->add_path(1,2,3,1,4);
    my $s = Graph_line_graph($hanging);
    my $iso = Graph_is_isomorphic($s,$kite);
    print "hanging line $iso\n";
    $iso or die;
  }

  # octahedral delete any vertex is wheel
  foreach my $v ($octahedral->vertices) {
    my $s = $octahedral->copy;
    $s->delete_vertex($v);
    my $iso = Graph_is_isomorphic($s,$wheel);
    print "wheel $iso\n";
    $iso or die;
  }

  # octahedral delete any adjacent vertices is kite
  foreach my $e ($octahedral->edges) {
    my ($u,$v) = @$e;
    my $s = $octahedral->copy;
    $s->delete_vertex($u);
    $s->delete_vertex($v);
    # Graph_view($s);
    # Graph_view($kite);
    my $iso = Graph_is_isomorphic($s,$kite);
    print "kite $iso\n";
    $iso or die;
  }

  # wheel delete any except centre is kite
  foreach my $v (2 .. 5) {
    my $s = $wheel->copy;
    $s->delete_vertex($v);
    my $iso = Graph_is_isomorphic($s,$kite);
    print "wheel->kite $iso\n";
    $iso or die;
  }

  hog_searches_html($octahedral, $wheel, $kite, $complete);
  exit 0;

  sub Graph_make_octahedral {
    my $graph = Graph->new (@_);
    $graph->set_graph_attribute (name => "Octahedral");
    $graph->add_cycle(1,2,3,4);
    $graph->add_path(1,'a',2);
    $graph->add_path(3,'a',4);
    $graph->add_path(1,'b',2);
    $graph->add_path(3,'b',4);
    return $graph;
  }
  sub Graph_make_kite {
    my $graph = Graph->new (@_);
    $graph->set_graph_attribute (name => "Kite");
    $graph->add_cycle(1,2,4,3);
    $graph->add_edge(2,3);
    return $graph;
  }
}

{
  # look for line graphs with a pair of adjacent induced triangles which are
  # both even

  my $iterator_func = make_graph_iterator_edge_aref
    (num_vertices_min => 1,
    );
  while (my $edge_aref = $iterator_func->()) {
    my $graph = Graph_from_edge_aref($edge_aref);
    next unless Graph_is_line_graph_by_Beineke($graph);

    my $found = 0;
    my @triangles = Graph_find_two_induced_adjacent_triangles
      ($graph,
       pred => sub {
         my ($graph, $a,$b,$c,$d) = @_;
         if (Graph_triangle_is_even($graph, $a,$b,$c)
             && Graph_triangle_is_even($graph, $d,$b,$c)) {
           $found = 1;
           return 1;  # stop
         } else {
           return 0;  # continue
         }
       });
    next unless $found;

    Graph_view($graph, synchronous=>1);
  }
  exit 0;
}
{
  # G2   1--\                  ----- 0-----
  #     / \  \                /     / \    \
  #    2---3  5              5---- 2---4    3
  #     \ /  /                \     \ /    /
  #      4--/                  ----- 1-----

  #   1=0, 2=2, 3=4, 4=1, 5=3

  # odd:  4 2 1
  # even: 5 2 1

  my $graph = Graph_from_graph6_str('E]zo');
  require Graph::Maker::Beineke;
  my $G2 = Graph::Maker->new('Beineke', G=>2, undirected=>1);
  my $G2_is_subgraph = Graph_is_induced_subgraph($graph, $G2);
  print "G2_is_subgraph  $G2_is_subgraph\n";

  my $i = Graph_van_Rooij_Wilf_condition_i($graph);
  my $ii = ! Graph_has_claw($graph) ? 1 : 0;
  print "i=$i\n";
  print "ii=$ii\n";

  Graph_view($graph);
  exit 0;
}
{
  require Graph::Maker::Beineke;
  my $graph = Graph::Maker->new('Beineke', G=>2, undirected=>1);
  foreach (1 .. 1000) {
    my $i = Graph_van_Rooij_Wilf_condition_i($graph);
    if ($i) {
      print "$i\n";
    }
  }
  exit 0;
}


