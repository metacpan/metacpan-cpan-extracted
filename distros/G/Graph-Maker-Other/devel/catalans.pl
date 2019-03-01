#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
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
use List::Util 'sum';
use Graph::Maker::Catalans;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # dexter vs rotate incoming

  # [1110110000]  3 3
  #   [1011110000]  [1101100010]  **
  #   [1101100010]  [1101110000]
  #   [1110101000]  [1110101000]  **
  # vpar
  # [0,1,2,2,4]  3 3
  #   [0,0,2,3,4]  [0,1,1,3,0]  **
  #   [0,1,1,3,0]  [0,1,1,3,4]
  #   [0,1,2,2,2]  [0,1,2,2,2]  **
  #
  #      1              1           1              1
  #    h/     from     /           / \*h          /
  #    2              2          a2   5          2        2=left, no dexter
  #  g/              /             \  bc          \*g
  #  3              3   both        3              3
  #   \              \             / dex2         /
  #    4              4           4  rot1        4  rot2
  #  f/                \*f                      /       v
  #  5                  5                      5     1101110000
  #                       v              v
  #  1110110000     1110101000   1101100010
  #
  #                    1                       1
  #                     \*h                   / \
  #                      2                   2   5
  #                     /+g                   \
  #                    3                       3
  #                   /     vv                /     dex2 = rot1
  #                  4    1011110000         4
  #                 /                               v
  #                5    dex1                1101100010
  #
  # unrotate  any 11 is 11aa0 comes from 1aa0 1
  # dexter comes from right edge 0 1aa0 1
  # take all 1s before too  so  to  0 111aa0
  #                            from 0 1aa0 11

  my $N = 5;
  my @options = (vertex_name_type => 'Lweights',
                 vertex_name_type => 'vpar',
                 vertex_name_type => 'balanced',
                );
  my $dexter = Graph::Maker->new ('Catalans', N => $N, rel_type => 'dexter',
                                  @options);
  my $rotate = Graph::Maker->new ('Catalans', N => $N, rel_type => 'rotate',
                                  @options);
  "$dexter" ne "$rotate" or die;
  foreach my $v (sort $dexter->vertices) {
    my $pairs;
    foreach my $i (0 .. length($v)-2) {
      $pairs += (substr($v,$i,2) eq '11');
    }
    print "[$v]  ",scalar($dexter->predecessors($v))," ",scalar($rotate->predecessors($v))," pairs $pairs\n";

    my @d_preds = sort $dexter->predecessors($v);
    my %d_preds; @d_preds{@d_preds} = ();
    my @r_preds = sort $rotate->predecessors($v);
    foreach my $i (0 .. $#d_preds) {
      print "  [",$d_preds[$i],"]  [",$r_preds[$i],"]",
        exists $d_preds{$r_preds[$i]} ? "  **" : "", "\n";
    }
  }
  exit 0;
}

{
  # intervals lattice
  # rotate intervals lattice num cover edges
  # not in OEIS: 3,18,144,1140
  # maybe 2* A006634 9,72,570
  #
  my @graphs;
  foreach my $N (
                 6,
                ) {
    print "N=$N\n";
    my $base = Graph::Maker->new
      ('Catalans',
       N          => $N,
       undirected => 0,
       # rel_direction => 'down',
       # rel_direction => 'up',
       # rel_type => 'rotate_Cempty',
       rel_type => 'split',
       rel_type => 'rotate_first',
       rel_type => 'rotate_last',
       rel_type => 'flip',
       rel_type => 'filling',
       rel_type => 'rotate_Bempty',
       rel_type => 'rotate_Aempty',
       rel_type => 'rotate_leftarm',
       rel_type => 'rotate_rightarm',
       rel_type => 'dexter',
       rel_type => 'rotate',
       # vertex_name_type => 'vpar_postorder',
       # vertex_name_type => 'run1s',
       # vertex_name_type => 'bracketing',
       # vertex_name_type => 'bracketing_reduced',
       # vertex_name_type => 'Ldepths',
       # vertex_name_type => 'Rdepths_inorder',
       # vertex_name_type => 'Rdepths_postorder',
       vertex_name_type => 'vpar',
       vertex_name_type => 'balanced',
       vertex_name_type => 'Lweights',
       comma => '',
      );
    print "base num intervals ", MyGraphs::Graph_num_intervals($base),"\n";

    my $graph = MyGraphs::Graph_make_intervals_lattice($base, 1);
    $graph = MyGraphs::Graph_covers($graph);
    push @graphs, $graph;
    $graph->set_graph_attribute (flow => 'east');
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6) || "not";
    print "$num_vertices vertices, $num_edges edges diam=$diameter  $hog\n";

    MyGraphs::Graph_run_dreadnaut($graph->is_directed ? $graph->undirected_copy : $graph,
                                  verbose=>0, base=>1);
    # print "vertices: ",join('  ',$graph->vertices),"\n";
    if ($graph->vertices < 70) {
      MyGraphs::Graph_view($graph, synchronous=>0);
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  my @graphs;
  foreach my $N (
                  4..6,
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new
      ('Catalans',
       N          => $N,
       undirected => 0,
       # rel_direction => 'down',
       # rel_direction => 'up',
       # rel_type => 'rotate_Cempty',
       rel_type => 'split',
       rel_type => 'rotate',
       rel_type => 'rotate_first',
       rel_type => 'rotate_last',
       rel_type => 'flip',
       rel_type => 'filling',
       rel_type => 'rotate_Bempty',
       rel_type => 'rotate_Aempty',
       rel_type => 'rotate_leftarm',
       rel_type => 'rotate_rightarm',
       rel_type => 'dexter',
       # vertex_name_type => 'vpar_postorder',
       # vertex_name_type => 'run1s',
       # vertex_name_type => 'bracketing',
       # vertex_name_type => 'bracketing_reduced',
       # vertex_name_type => 'Ldepths',
       # vertex_name_type => 'Rdepths_inorder',
       # vertex_name_type => 'Rdepths_postorder',
       vertex_name_type => 'vpar',
       vertex_name_type => 'balanced',
       vertex_name_type => 'Lweights',
       comma => '',
      );
    push @graphs, $graph;
    print "directed ",$graph->is_directed,"\n";
    $graph->set_graph_attribute (flow => 'north');
    $graph->set_graph_attribute (flow => 'east');
    print $graph->get_graph_attribute('name'),"\n";
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6) || "not";
    print "$num_vertices vertices, $num_edges edges diam=$diameter  $hog\n";

    MyGraphs::Graph_run_dreadnaut($graph->is_directed ? $graph->undirected_copy : $graph,
                                  verbose=>0, base=>1);
    # print "vertices: ",join('  ',$graph->vertices),"\n";
    if ($graph->vertices < 50) {
      MyGraphs::Graph_view($graph, synchronous=>0);
    }

    my $d6str = MyGraphs::Graph_to_graph6_str($graph, format=>'digraph6');
    # print Graph::Graph6::HEADER_DIGRAPH6(), $d6str;
    print "\n";

    MyGraphs::Graph_print_tikz($graph);
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # tikz with coordinate vectors

  my $N = 5;
  my $graph = Graph::Maker->new
    ('Catalans',
     N          => $N,
     undirected => 0,
    );

  my @vertices = sort $graph->vertices;
  foreach my $v (@vertices) {
    my $vn = vertex_name_to_tikz($v);
    my $at = node_to_location($v);
    # print "  \\node ($vn) at ($at) [my box] {$vn};\n";
    print "  \\node ($vn) at ($at) [my box];\n";
  }
  print "\n";

  my $arrow = $graph->is_directed ? "->" : "";
  foreach my $edge ($graph->unique_edges) {
    my ($from,$to) = @$edge;
    my $count = $graph->get_edge_count($from,$to);
    my $node = ($count == 1 ? ''
                : "node[pos=.5,auto=left] {$count} ");

    $from = vertex_name_to_tikz($from);
    $to   = vertex_name_to_tikz($to);
    if ($from eq $to) {
      print "  \\draw [$arrow,loop below] ($from) to $node();\n";
    } else {
      print "  \\draw [$arrow] ($from) to $node($to);\n";
    }
  }
  print "\n";
  exit 0;

  sub node_to_location {
    my ($str) = @_;
    my @array = split /,/, $str;
    foreach my $i (0 .. $#array) {
      $array[$i] = "$array[$i]*(vec$i)";
    }
    return '$' . join('+',@array) . '$';
  }
  sub vertex_name_to_tikz {
    my ($str) = @_;
    $str =~ s/,//g;
    return $str;
  }
}

{
  my $N = 10;
  print "N=$N\n";
  my $graph = Graph::Maker->new
    ('Catalans',
     N          => $N,
     undirected => 0,
     rel_type => 'leftmost_rotates',
     rel_type => 'rotate_last',
     rel_type => 'rotate_first',
     rel_type => 'flip',
     rel_type => 'all',
     rel_type => 'rotate',
     rel_direction => 'up',
     vertex_name_type => 'sizes',
     vertex_name_type => 'vpar_postorder',
     vertex_name_type => 'postorder_Ldepths',
     vertex_name_type => 'Lweights',
     vertex_name_type => 'vpar',
     vertex_name_type => 'Ldepths',
     vertex_name_type => 'Rdepths',
     vertex_name_type => 'balanced',
    );
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "$num_vertices vertices, $num_edges edges\n";
  exit 0;
}


{
  # diameter undirected
  # 0,0,1,2,4,5,7,
  # A182136 ,1,3,5,7,10,12,15,18,21,
  #
  # diameter directed
  # 0,0,1,2,4,6,9,
  #

  my @graphs;
  foreach my $N (0 .. 20) {
    my $graph = Graph::Maker->new ('Catalans', N => $N,
                                   undirected => 1,
                                  );
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    # print "$num_vertices,";
    print "$diameter,";
  }
  exit 0;
}

{
  my $graph = Graph::Maker->new
    ('Catalans',
     N            => 6,
    );
  MyGraphs::Graph_view($graph, synchronous=>1);
  exit 0;
}

CHECK {
  ! Scalar::Util::looks_like_number('1,1') or die;
}

#------------------------------------------------------------------------------

sub balanced_list {
  my ($n) = @_;
  my @ret;
  my @array = (1,0) x $n;
  do {
    push @ret, [@array];
  } while (Graph::Maker::Catalans::_balanced_next(\@array));
  return @ret;
}


#------------------------------------------------------------------------------
# UNUSED

# sub _vertex_name_type_Bdepths {
#   return _vertex_name_type_Rdepths(@_,1);
# }
# sub _vertex_name_type_Rdepths {
#   my ($aref, $l) = @_;
#   $l ||= 0;
#   ### _vertex_name_type_Bdepths(): "l=$l"
#   my @pos = (0);
#   my @ret;
#   my $d = 0;
#   foreach my $i (0 .. $#$aref) {
#     ### at: "i=$i d=$d"
#     if ($aref->[$i]) {
#       push @ret, $pos[-1] + $d;
#       push @pos, $pos[-1];   # copy
#       $d += $l;
#     } else {
#       pop @pos;       # backtrack and go right
#       $pos[-1]++;
#       $d -= $l;
#     }
#   }
#   return @ret;
# }
#
#       {
#         my @by_binary_tree = binary_tree_to_depths($binary_tree,'pre','R');
#         my $by_binary_tree = join(',',@by_binary_tree);
#         my @by_func = Graph::Maker::Catalans::_vertex_name_type_Rdepths(\@array);
#         my $by_func = join(',',@by_func);
#         ok ($by_func, $by_binary_tree,
#             '_vertex_name_type_Rdepths() vs binary_tree_to_depths()');
#         ok (! $seen{$by_func}++, 1,
#             '_vertex_name_type_Rdepths() distinct');
#       }

# sub _weights_step {
#   my ($aref) = @_;
#   foreach my $pos (reverse 1.. $#$aref) {
#     if ($aref->[$pos] < $pos+1) {
#       $aref->[$pos] += $aref->[$pos - $aref->[$pos]];
#       return 1;
#     }
#     $aref->[$pos] = 1;
#   }
#   return 0;
# }


