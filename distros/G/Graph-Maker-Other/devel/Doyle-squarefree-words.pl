#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde
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
  # Jon Doyle

  # vpar =[0,1,23,1,4,5,6,7,8,9,9,4,2,12,14,15,16,16,14,13,20,13,22,23,24,25]
  # vpar_centres(vpar)  == [1]
  # vpar_roots(vpar)    == [1]
  # vpar_diameter(vpar) == 14
  # vpar_diameter_and_count(vpar) == [14, 2]

  my $graph = Graph->new (undirected => 0);
  $graph->set_graph_attribute (flow => 'east');
  my $extend;
  my $upto_v = -1;
  my %str_to_v;
  my @v_to_str;
  my $str_to_v = sub {
    my ($str) = @_;
    # return $str;
    return ($str_to_v{$str} //= do {
      $upto_v++;
      die if defined $v_to_str[$upto_v];
      $v_to_str[$upto_v] = $str;
      $upto_v;
    });
  };
  $extend = sub {
    my ($str) = @_;
    ### $str
    # return if length($str) >= 8;
    foreach my $bit (0,1) {
      my $new_str = $str . $bit;
      if (str_is_good($new_str)) {
        $graph->add_edge($str_to_v->($str),
                         $str_to_v->($new_str));
        $extend->($new_str);
      }
    }
  };
  $extend->('0');

  MyGraphs::Graph_tree_layout($graph);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);

  ### @v_to_str
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "$num_vertices vertices, $num_edges edges\n";
  my @centre = MyGraphs::Graph_tree_centre_vertices($graph);
  print "centre ",join(' and ',@centre),"\n";
  print "  strings ",join(' and ',map{$v_to_str[$_]} @centre),"\n";

  my @vpar = MyGraphs::Graph_to_vpar($graph);
  ### @vpar
  MyGraphs::Graph_print_vpar($graph);
  exit 0;
}

sub str_is_good {
  my ($str) = @_;
  if ($str =~ /(.+)\1\1/) {
    return 0;   # has a cube X X X
  }
  if ($str =~ /(..+)\1/) {
    return 0;   # has a square X X with length(X)>=3
  }
  return 1;
}

