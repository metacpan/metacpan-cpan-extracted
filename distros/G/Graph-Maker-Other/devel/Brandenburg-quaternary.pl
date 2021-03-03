#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde
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
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Graph;
use List::Util 'min','max';

use FindBin;
use lib::abs "$FindBin::Bin/lib";
use MyGraphs 'Graph_set_xy_points';
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


# Franz-Josef Brandenburg, "Uniformly Growing k-th Power-Free Homomorphisms",
# Theoretical Computer Science, volume 23, 1983
#
# power 3/2 is reps length >= 3/2*original
# strict power 3/2 is reps length > 3/2*original
# ab power 3/2 = aba
# ab strict power 3/2 = abab
#
# w is k'th power-free if w does not ahve the k'th power as a substring
# w is weakly k'th power-free if w does not ahve the k'th power as a strict substring
#
# FREE(<k) k'th power-free strings
# FREE(<=k) k'th weakly power-free strings
# FREE(=k) exactly k'th power-free strings
#          = FREE(<=k) - FREE(<k)
#          has k'th power but does not have m'th power m>k


{
  # quaternary starting a,c nowhere a,b and 3/2 power free
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=35483
  #
  # strings in FREE(=k) with k < 3/2
  # (ii) no a,b substring
  #
  # a c b a d b c a X
  #               b
  # aca
  # acbda X
  #    dad
  # acbd,ac
  #
  # acbadbcd acbd cad
  #          b  not

  my $graph = Graph->new (undirected => 1, countedged=>1);
  $graph->set_graph_attribute (flow => 'east');
  my $upto_v = 0;
  my @alphabet = qw(a b c d);
  my @strs = ('');
  my @unwanted_re = (qr/ab/,        # nowhere ab
                     qr/^[^a]/,     # must start ac
                     qr/^a[^c]/,
                    );
  my $count_leaves = 0;
  my %str_to_v;
  my @v_to_str;
  foreach my $len (1 .. 30) {
    print "len=$len count ",scalar(@strs),"\n";
    {
      my $Xlen = ($len+1)>>1;  # round up    X Y X
      my $Ylen = $len-$Xlen;
      my $re = ($Ylen ? qr/(.{$Xlen}).{$Ylen}\1/ : qr/(.{$Xlen})\1/);
      $re = qr/(.{$Xlen}).{$Ylen}\1/;
      my $Wlen = $Xlen + $Ylen;
      $Wlen + $Xlen >= $Wlen*3/2 or die "len=$len";

      # # X Y X with length(Y) <= length(X), including Y empty
      # my $re = qr/(.{$len}).{0,$len}\1/;

      push @unwanted_re, $re;
      print "  new re $re\n";
    }
    my @new_strs;
    foreach my $str (@strs) {
      my $leaf = 1;
    SYMBOL: foreach my $symbol (@alphabet) {
        my $new_str = $str.$symbol;
        ### $new_str
        foreach my $re (@unwanted_re) {
          if ($new_str =~ $re) {
            ### matches: $re
            next SYMBOL;
          }
        }
        push @new_strs, $new_str;
        $leaf = 0;
        my $v = $upto_v++;
        $graph->add_vertex($v);
        $str_to_v{$new_str} = $v;
        $v_to_str[$v] = $new_str;
        $graph->set_vertex_attribute ($v, name => $symbol);
        if (defined(my $from = $str_to_v{$str})) {
          $graph->add_edge($from,$v);
        }
      }
      $count_leaves += $leaf;
    }
    @strs = @new_strs;
    foreach my $str (@strs) {
      print "$str\n";
    }
  }
  print "total leaves $count_leaves\n";

  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "$num_vertices vertices, $num_edges edges\n";

  $graph->set_graph_attribute(root => 0);

  my %str_to_offset
    = (acb => 2.5,
       acd => -2,

       acba => 1.5,
       acbd => -1,
       acda => 1,
       acdb => -1.5,

       acbda => .5,
       acbdc => -.5,
       acdba => 1.5,
       acdbc => -1.5,

       acbadb => .5,
       acbadc => -.5,

       acbadbca => .5,
       acbadbcd => -.5,
       acdbadca => .5,
       acdbadcb => -.5,

       acbdcadba => 1,
       acbdcadbc => -.5,

       acdbcadcba => 1,
       acdbcadcbd => -.5,

       acbdcadbacb => .5,
       acbdcadbacd => -.5,

       acdbcadcbacda => .5,
       acdbcadcbacdb => -.5,

       acbdcadbcdacba => .5,
       acbdcadbcdacbd => -.5,

       acbdcadbcdacbadb => .5,
       acbdcadbcdacbadc => -.5,

       acbadbcdacbdcadba => .5,
       acbadbcdacbdcadbc => -.5,

       acdbcadcbdacdbadca => .5,
       acdbcadcbdacdbadcb => -.5,

       acbadbcdacbdcadbacb => .5,
       acbadbcdacbdcadbacd => -.5,

       acdbadcbdacdbcadcbacda => .5,
       acdbadcbdacdbcadcbacdb => -.5,
      );
  Graph_set_xy_points($graph, 0 => [0,0]);
  my @pending = (0);
  my %seen_xy;
  my $successors_func = sub {
    my ($v) = @_;
    return grep {length($v_to_str[$_]) > length($v_to_str[$v])}
      $graph->neighbours($v);
  };
  my $predecessors_func = sub {
    my ($v) = @_;
    return grep {length($v_to_str[$_]) < length($v_to_str[$v])}
      $graph->neighbours($v);
  };
  while (defined(my $v = shift @pending)) {
    ### $v
    push @pending, $successors_func->($v);
    if ($v) {
      my ($parent) = $predecessors_func->($v);
      my ($x,$y) = MyGraphs::Graph_vertex_xy($graph,$parent);
      my $str = $v_to_str[$v];
      $x += 1;
      $y += ($str_to_offset{$str} || 0);
      Graph_set_xy_points($graph, $v => [$x,$y]);
      if ($seen_xy{$x,$y}++) {
        print "oops, overlap $x,$y  v=$v str=$str\n";
      }
    }
  }
  foreach my $str (keys %str_to_offset) {
    if (! exists $str_to_v{$str}) {
      print "offset $str no such vertex\n";
    }
  }

  MyGraphs::Graph_view($graph, scale=>1.5, is_xy=>1);
  MyGraphs::hog_upload_html($graph);
  MyGraphs::hog_searches_html($graph);

  {
    my $canon_s6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_sparse6_str($graph),
       format => 'sparse6');
    print "canonical: ",$canon_s6;
    my $want_s6 = <<'HERE';
:~?@YdpYXEHeYexq^Fh}_gYIbhIUgHyahhywkixyqKJIpeHuyLJMVjY}mjKGpmXAPcxIToCM{OSI|Nb}SDSQKDBULLb]NMRmMMBiAQGCUQG@HSWWvPg\@PwKwPW_HHggJIgODJ^
HERE
    $canon_s6 eq $want_s6 or die;
  }
  print "end\n";
  exit 0;


  # MyGraphs::Graph_tree_layout($graph,
  #                             order => 'name');
  # foreach my $v (sort $graph->vertices) {
  #   my ($x,$y) = MyGraphs::Graph_vertex_xy($graph,$v);
  #   ### vertex: "$v at $x,$y"
  #   my $min_y = $x;
  #   my $max_y = $y;
  #   foreach my $c ($graph->successors($v)) {
  #     my ($x,$y) = MyGraphs::Graph_vertex_xy($graph,$c);
  #     ### child: "$c at $x,$y"
  #     $min_y = min($min_y,$y);
  #     $max_y = max($min_y,$y);
  #   }
  #   my $offset = ($min_y + $max_y)/2 - $y;
  #   ### $min_y
  #   ### $max_y
  #   ### $offset
  #   foreach my $c ($graph->all_successors($v)) {
  #     my ($x,$y) = MyGraphs::Graph_vertex_xy($graph,$c);
  #     $y -= $offset/2;
  #     ### move: "$c to $x,$y"
  #     Graph_set_xy_points($graph, $c => [$x,$y]);
  #   }
  # }
}
