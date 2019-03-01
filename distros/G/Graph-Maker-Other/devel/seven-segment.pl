#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde
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

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


#   *--0--*
#   |     |
#   1     2
#   |     |
#   *--3--*
#   |     |
#   4     5
#   |     |
#   *--6--*
my @nine_without = (0,1,2,3,5);
my @nine_with    = (0,1,2,3,5, 6);
my @seven_without = (0,2,5);
my @seven_with    = (0,2,5, 1);
my @digit_to_segnums = ([0,1,2,4,5,6],   # 0
                        [2,5],           # 1
                        [0,2,3,4,6],     # 2
                        [0,2,3,5,6],     # 3
                        [1,2,3,5],       # 4
                        [0,1,3,5,6],     # 5
                        [0,1,3,4,5,6],   # 6
                        [0,2,5],         # 7
                        [0,1,2,3,4,5,6], # 8
                        [0,1,2,3,5],     # 9
                       );
# foreach my $aref (@digit_to_segnums) {
#   @$aref = sort @$aref;
# }

my @digit_to_flags;
sub make_digit_to_flags {
  foreach my $i (0 .. 9) {
    my @flags;
    foreach my $segnum (@{$digit_to_segnums[$i]}) {
      $flags[$segnum] = 1;
    }
    $digit_to_flags[$i] = \@flags;
  }
}
make_digit_to_flags();

sub flags_is_subset {
  my ($aref, $subset) = @_;
  foreach my $i (0 .. 6) {
    if ($subset->[$i] && !$aref->[$i]) { return 0; }
  }
  return 1;
}

{
  # seven segment LED subsets
  
  # 7=without, 9=with, Robinson published by Gardner
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=30627

  my @graphs;
  foreach my $seven_with (0,
                          # 1
                         ) {
    foreach my $nine_with (
                           # 0,
                           1) {
      $digit_to_segnums[7] = ($seven_with ? \@seven_with : \@seven_without);
      $digit_to_segnums[9] = ($nine_with  ? \@nine_with  : \@nine_without);
      make_digit_to_flags();

      my $graph = Graph->new(undirected => 1);
      $graph->set_graph_attribute (flow => 'south');
      $graph->set_graph_attribute
        (name => "Seven Segment Subsets seven=$seven_with nine=$nine_with");
      foreach my $i (0 .. 9) {
      J: foreach my $j (0 .. 9) {
          next if $i == $j;
          if (flags_is_subset($digit_to_flags[$i], $digit_to_flags[$j])) {
            foreach my $k (0 .. 9) {
              next if $k == $i || $k == $j;
              if (flags_is_subset($digit_to_flags[$i], $digit_to_flags[$k])
                  && flags_is_subset($digit_to_flags[$k], $digit_to_flags[$j])) {
                next J;
              }
            }
            $graph->add_edge ($i, $j);
          }
        }
      }
      # MyGraphs::Graph_view($graph);
      # MyGraphs::Graph_print_tikz($graph);

      my @vertices = sort $graph->vertices;
      print "degrees", join(',',map{$graph->vertex_degree($_)} @vertices),"\n";
      push @graphs, $graph;
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # seven segment LED print

  foreach my $i (0 .. 9) {
    my $aref = $digit_to_flags[$i];
    print "digit $i\n";
    print "*",$aref->[0] ? '-----' : '     ',"*\n";
    foreach (1..3) {
      print $aref->[1] ? '|' : ' ','     ',$aref->[2] ? '|' : ' ',"\n";
    }
    print "*",$aref->[3] ? '-----' : '     ',"*\n";
    foreach (1..3) {
      print $aref->[4] ? '|' : ' ','     ',$aref->[5] ? '|' : ' ',"\n";
    }
    print "*",$aref->[6] ? '-----' : '     ',"*\n";
    print "\n";
  }
  exit 0;
}
