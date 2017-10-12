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

use strict;
use Graph;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # count trees no square grid layout
  # A000055 trees n nodes
  # A144520 trees n nodes degree <= n-2, so skip star-n A000055-1
  # A144527 trees n nodes degree <= n-3,  A000055-2
  # not     trees n nodes degree <= n-4
  # A000602 trees n nodes degree 1,4  2     5     8    11    14    17    20
  #                       sans zeros  1,0,0,1,0,0,1,0,0,1,0,0,2,0,0,3,0,0,5
  # A000672 trees degree 1,2,3
  # not     trees degree 1,2,4
  #         trees degree 1,2,3,4 not square grid n=12  1,4,14,43,136
  #         trees degree 1,2,  4 not square grid n=14  1,2,5,13,30,69,162
  #         trees degree 1,    4 not square grid n=14 1of2  n=17 2of3
  # 1,2,3 always square grid?

  # 1,2,3,4 is 12 with 1,3,4
  # 1,2,4   is 14 with 1,4
  # for exactly 1,2,3,4 add to one of the two leaf types in 1,3,4
  # for exactly 1,2,4 add to one of the two leaf types in 1,4

  #-------------------------------------------------------------
  # trees degree <=6 on triangular grid
  # counts 1,3,8,27,79,232
  # n=11 first
  #      https://hog.grinvin.org/ViewGraphInfo.action?id=650
  #      (comment posted)


  my $grid = '6';
  my @values;
  my @graphs;
  my $seen_graphs;
  foreach my $num_vertices (2..20) {
    my $degree_list = [
                       # 1,4,
                       1,2,3,4,5,6
                      ];
    my $iterator_func = MyGraphs::make_tree_iterator_edge_aref
      (num_vertices => $num_vertices,
       # degree_max => $num_vertices-4,
       degree_max => $grid,
       # degree_list => $degree_list,
      );
    my $name = "tree $num_vertices degrees ".join(',',@$degree_list);
    my $count = 0;
    my $count_total = 0;
  GRAPH: while (my $edge_aref = $iterator_func->()) {
      $count_total++;
      my $parent_aref = MyGraphs::edge_aref_to_parent_aref($edge_aref);

      # restricting to exactly certain set of degrees ...
      # my @actual_degrees = MyGraphs::edge_aref_degrees($edge_aref);
      # join('',@actual_degrees) eq '1234' or next;

      my $layout = grid_layout($parent_aref, grid => $grid);
      if ($layout) {
        # grid_layout_check ($edge_aref, $parent_aref, $layout);
        next;
      } else {
        # print "Cannot layout\n";
      }

      if (! $seen_graphs) {
        $name .= " (actual "
          . join(',',MyGraphs::edge_aref_degrees($edge_aref))
          . ")";
        my $easy = MyGraphs::edge_aref_to_Graph_Easy($edge_aref);
        $easy->set_attribute(label => $name);
        push @graphs, $easy;
        require Graph::Easy::As_graph6;
        my $g6_str = $easy->as_graph6;
        print MyGraphs::edge_aref_string($edge_aref),"\n";
        MyGraphs::Graph_Easy_print_adjacency_matrix($easy);
        print $g6_str;
        print MyGraphs::graph6_str_to_canonical($g6_str);
      }
      $count++;
    }
    push @values, $count;
    print "n=$num_vertices  $count (out of $count_total)\n";

    if (@graphs && ! $seen_graphs) {
      MyGraphs::hog_searches_html(@graphs);
    }
    $seen_graphs ||= @graphs;
  }
  # require Math::OEIS::Grep;
  # Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}

{
  # complete binary tree layout

  # diamond         * H=2            *     H=3               *      H=4
  #                 | 5 points     * * *   13 points       * * *    25
  #             *---*---*        * * * * *               * * * * *
  #                 |              * * *               * * * * * * *
  #                 *                *                   * * * * *
  #                                                        * * *
  #                                                          *
  # p(H) = 4*H*(H-1)/2+1; \\ points reachable
  # v(H) = 2^H-1;         \\ vertices to be drawn
  # d(H) = p(H) - v(H);
  # vector(8,H,p(H))
  # vector(8,H,v(H))
  # vector(8,H,d(H))
  # at H=6
  # p(6) == 61
  # v(6) == 63  \\ too many, so H=5 biggest with layout
  #
  # ternary
  # v(H) = sum(i=0,H-1,3^i);      \\  to be drawn
  # at H=3
  # p(3) == 13
  # v(3) == 13  \\ but not layout, so H=2 biggest ternary with layout
  #
  # A001699 = 1, 1, 3, 21 offset 0
  # a(2) is 3 trees of height 2 being 2 levels including the root
  # A000235 = 0, 0, 0, 1 offset 1
  # a(4)=1 is 1 height 3 tree of 4 nodes  similar A000299

  require Graph::Maker::BalancedTree;
  my $row_start = 0;
  my $row_end = 0;
  my $upto = 1;
  my @edges;
  my $edge_aref = \@edges;
  foreach my $height (2 .. 2) {
    print "height=$height\n";
    foreach my $v ($row_start .. $row_end) {
      push @edges, [$v,$upto++];
      push @edges, [$v,$upto++];
      push @edges, [$v,$upto++]; # ternary
    }
    $row_start = $row_end+1;
    $row_end = $upto-1;
    my $parent_aref = edge_aref_to_parent_aref($edge_aref);
    my $layout = grid_layout($parent_aref);
    if ($layout) {
      grid_layout_check ($edge_aref, $parent_aref, $layout);
      print "  has layout\n";
      foreach my $i (0 .. $upto-1) {
        print "  $i  ",join(',',@{$layout->[$i]}),"\n";
      }
    } else {
      print "  no layout\n";
    }
  }
  exit 0;
}



{
  # trees no layout on square grid
  #
  # 3,3,3,0 https://hog.grinvin.org/ViewGraphInfo.action?id=582
  # 3,3,2,1 not
  # 3,2,2,2 not
  my $n = 1;
  foreach my $list ([3, 3, 3, 0],
                    [3, 3, 2, 1],
                    [3, 2, 2, 2]) {
    $list->[0]+$list->[1]+$list->[2]+$list->[3] == 9 or die;
    print @$list,"  n=$n\n";

    my $graph = Graph->new (undirected => 1);
    $graph->add_vertex(0);
    $graph->add_edge(0,1);
    $graph->add_edge(0,2);
    $graph->add_edge(0,3);
    $graph->add_edge(0,4);
    my $v = 5;
    foreach my $i (0 .. $#$list) {
      my $from = $i+1;
      foreach (1 .. $list->[$i]) {
        $graph->add_edge($from, $v++);
      }
    }
    require Graph::Writer::Graph6;
    my $writer = Graph::Writer::Graph6->new;
    $writer->write_graph($graph, "/tmp/$n.g6");

    print "  centre: ",join(' ',$graph->centre_vertices),"\n";

    {
      require Graph::Convert;
      my $easy = Graph::Convert->as_graph_easy($graph);
      my $graphviz_str = $easy->as_graphviz;
      # print $graphviz_str;
      my $png_filename = "/tmp/$n.png";
      require IPC::Run;
      IPC::Run::run(['dot','-Tpng'], '<',\$graphviz_str, '>',$png_filename);
      # print $easy->as_ascii;
    }

    $n++;
  }
  exit 0;
}

{
  # 12 vertices no square grid layout
  # https://hog.grinvin.org/ViewGraphInfo.action?id=604
  # is K???????{XMC
  # but picture K?????H@b_OF ... due to vertices overlapping edges

  require Graph::Easy::As_graph6;
  my $orig_g6_str;
  my %seen;
  my $try_tree = sub {
    my ($parent_aref, $edge_aref) = @_;
    # print "$num_vertices vertices   p=",@$parent[1 .. $num_vertices-1],
    #   " nc=",@num_children[0 .. $num_vertices-1],"\n";

    my $num_vertices = scalar(@$parent_aref);
    my $layout = grid_layout($parent_aref);
    if ($layout) {
      grid_layout_check ($edge_aref, $parent_aref, $layout);
    } else {
      print "Cannot layout\n";
    }
    if ($num_vertices < 5 && $layout) {
      print "can layout\n";
    }
    my $easy = parent_aref_to_Graph_Easy($parent_aref);
    my $g6_str = $easy->as_graph6;

    my $canonical = graph6_str_to_canonical($g6_str);
    # if ($seen{$canonical}++) {
    #   print "duplicate $canonical\n";
    #   return;
    # }
    # print "new $canonical\n";

    if ($num_vertices <= 0 || ! $layout) {
      $easy->layout(timeout => 999);
      print "num_vertices $num_vertices\n";
      print $easy->as_ascii,"\n";
    }

    if (! $layout) {
      {
        print "original\n";
        print $orig_g6_str;
        Graph::Graph6::read_graph(str => $orig_g6_str,
                                  edge_func => sub { print "  ",join('-', @_) });
        print "\n";
        print "\n";

        print "easy $easy  ",($easy->is_directed ? 'directed' : 'undirected'), "\n";
        print " ", Graph_Easy_edges_string($easy),"\n";
        Graph_Easy_print_adjacency_matrix($easy);

        print "via parent_aref\n";
        print $g6_str;
        Graph::Graph6::read_graph(str => $g6_str,
                                  edge_func => sub { print "  ",join('-', @_) });
        print "\n";
        print "  parents  ", join(' ', map {defined $_ ? $_ : 'undef'} @$parent_aref), "\n";
        print "\n";

        print "canonical\n";
        print $canonical;
        Graph::Graph6::read_graph(str => $canonical,
                                  edge_func => sub { print "  ",join('-', @_) });
        print "\n";
        print graph6_str_to_canonical($orig_g6_str);
        print "\n";

        open my $fh, '>', '/tmp/1.g6' or die;
        print $fh $g6_str or die;
        close $fh or die;
      }
      my $graphviz_str = $easy->as_graphviz;
      require File::Slurp;
      File::Slurp::write_file('/tmp/cannot.dot', $graphviz_str) or die;

      IPC::Run::run(['dot', '-Tpng', '/tmp/cannot.dot', '-o', '/tmp/1.png']);
      if ($ENV{'DISPLAY'}) {
        IPC::Run::run(['xdot', '/tmp/cannot.dot']);
      }
    }
  };

  {
    my $iterator_func = make_tree_iterator_edge_aref(num_vertices_min => 12,
                                                     num_vertices_max => 12,
                                                     degree_max => 4);
    my $count = 0;
    while (my $edge_aref = $iterator_func->()) {
      $count++;
      Graph::Graph6::write_graph(str_ref => \$orig_g6_str,
                                 edge_aref => $edge_aref);
      my $parent_aref = edge_aref_to_parent_aref($edge_aref);
      $try_tree->($parent_aref, $edge_aref);
    }
    print "count $count trees\n";
    exit 0;
  }

  {
    $orig_g6_str = 'K??????wCwO['."\n";
    my @edges;
    Graph::Graph6::read_graph(str => $orig_g6_str,
                              edge_aref => \@edges);
    my @parent = (undef, 0,0,0,0, 1,1,1, 2,2,2, 3,3,3, 4);
    @parent = (undef, 0,0,0, 1,1,1, 2,2,2, 3,3);
    $try_tree->(\@parent, \@edges);
    exit 0;
  }

  exit 0;
}

#------------------------------------------------------------------------------
BEGIN {
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
  my @dir6_to_dy = (0, 1, 1, 0, -1,-1);

  sub grid_layout {
    my ($parent_aref, %options) = @_;
    ### grid_layout() ...

    my $grid = $options{'grid'} || '4';
    my $dir_to_dx;
    my $dir_to_dy;
    if ($grid eq '6') {
      $dir_to_dx = \@dir6_to_dx;
      $dir_to_dy = \@dir6_to_dy;
    } else {
      $dir_to_dx = \@dir4_to_dx;
      $dir_to_dy = \@dir4_to_dy;
    }

    my $num_vertices = scalar(@$parent_aref);
    my $origin = $#$parent_aref + 5;
    my @layout = ([$origin, $origin]);  # v=0
    my @occupied;

    $occupied[$origin][$origin] = 0;
    my @directions = (3, -1);   # direction of $v from its parent

    my $v = 1;
    for (;;) {
      my $dir = ++$directions[$v];
      ### at: "$v consider direction $dir  parent $parent_aref->[$v]"
      if ($dir > $#$dir_to_dx) {
        ### backtrack ...
        $v--;
        if ($v < 1) {
          return undef;
        }
        # unplace $v
        my ($x,$y) = @{$layout[$v]};
        undef $occupied[$x][$y];
        next;
      }

      my ($x,$y) = @{$layout[$parent_aref->[$v]]};
      $x += $dir_to_dx->[$dir];
      $y += $dir_to_dy->[$dir];
      if (defined $occupied[$x][$y]) {
        next;
      }

      # place and go to next vertex
      $occupied[$x][$y] = $v;
      @{$layout[$v]} = ($x, $y);
      $v++;
      if ($v >= $num_vertices) {
        ### successful layout ...
        ### @layout
        return \@layout;
      }
      $directions[$v] = -1;
    }
  }
}

sub grid_layout_check {
  my ($edge_aref, $parent_aref, $layout_aref) = @_;
  # my $num_vertices = edge_aref_num_vertices($edge_aref);
  my $bad;
  foreach my $edge (@$edge_aref) {
    my ($from, $to) = @$edge;
    if (! defined $layout_aref->[$from]) {
      $bad = "missing layout for vertex $from";
      last;
    }
    if (! defined $layout_aref->[$to]) {
      $bad = "missing layout for vertex $to";
      last;
    }

    my ($x_from,$y_from) = @{$layout_aref->[$from]};
    my ($x_to,$y_to)     = @{$layout_aref->[$to]};
    if ($x_from < 0 || $y_from < 0) {
      $bad = "negative coordinate at $from";
      last;
    }
    if ($x_to < 0 || $y_to < 0) {
      $bad = "negative coordinates at $to";
      last;
    }
    if (abs($x_from - $x_to) + abs($y_from - $y_to) != 1) {   # dx+dy
      $bad = "layout not a unit step $from to $to";
      last;
    }
  }
  if ($bad) {
    print "layout length ", scalar(@$layout_aref),"\n";
    foreach my $v (0 .. $#$layout_aref) {
      print "$v at ",join(', ', @{$layout_aref->[$v]}),"\n";
    }
    print "edges";
    foreach my $edge (@$edge_aref) {
      print "  ",join('-', @$edge);
    }
    print "\n";
    print "parents  ", join(' ', map {defined $_ ? $_ : 'undef'} @$parent_aref), "\n";
    die $bad
  }
}
