#!/usr/bin/perl -w

# Copyright 2019, 2020 Kevin Ryde
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
use List::Util 'sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Cube-Free Substring Relations

  # 11,19,31,49,77,117
  # v = apply(n->2*n+1,[11,19,31,49,77,117])
  # vector(#v-1,i,v[i+1]-v[i]) \\ A028445 cubefrees

  my $max_len = 8;
  my $delta1 = 1;
  my $prefix = 1;

  my @cubefrees = ('');
  {
    my @pending = ('');
    foreach my $len (1 .. $max_len) {
      my @new_pending;
      foreach my $str (@pending) {
        foreach my $ext ('0','1') {
          my $new_str = $str.$ext;
          if (is_cubefree($new_str)) {
            push @new_pending, $new_str;
          }
        }
      }
      @pending = @new_pending;
      push @cubefrees, @pending;
    }
  }
  my $num_vertices = scalar(@cubefrees);
  print "num_vertices = $num_vertices\n";

  require Graph;
  my $graph = Graph->new (undirected => 0);
  $graph->set_graph_attribute
    (name => "Cubefree Substring Relations, Max Length $max_len");
  $graph->set_graph_attribute (root => "!");
  $graph->set_graph_attribute (flow => "east");
  foreach my $from_i (0 .. $#cubefrees) {
    my $from_str = $cubefrees[$from_i];
    foreach my $to_i (0 .. $from_i-1) {
      my $to_str = $cubefrees[$to_i];
      if ($delta1) {
        next unless length($from_str) - length($to_str) == 1;
      }
      my $pos = index($from_str,$to_str);
      if ($prefix) {
        next unless $pos==0;
      }
      if ($pos >= 0) {
        my $from_str = (length($from_str) ? $from_str : '!');
        my $to_str = (length($to_str) ? $to_str : '!');
        $graph->add_edge($to_str, $from_str);
      }
    }
  }

  MyGraphs::Graph_view($graph);
  print "tree\n";
  MyGraphs::Graph_tree_print($graph, cmp => \&MyGraphs::cmp_alphabetic);
  # Graph_print_tikz($graph);
  # MyGraphs::hog_searches_html($graph);
  exit 0;

  sub find_cube {
    my ($str) = @_;
    foreach my $c (1 .. int(length($str)/3)) {
      my $re = '('.('.' x $c).')\\1\\1';
      ### $re
      if ($str =~ $re) {
        ### $str
        ### cube: $1
        return $1;
      }
    }
    return undef;
  }
  sub is_cubefree {
    my ($str) = @_;
    return ! defined find_cube($str);
  }
}
