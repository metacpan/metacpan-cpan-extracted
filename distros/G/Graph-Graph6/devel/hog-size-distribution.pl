#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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


# Usage: perl hog-size-distribution.pl
#
# Input file: $HOME/HOG/all.g6
#
# $HOME/HOG/all.g6 is a graph6 file of all graphs in the House of Graphs.
# Look at the distribution of graph sizes, and in particular build some
# chunk sizes suitable for the examples/hog-fetch-all.pl download of this
# "all.g6" file.
#
# This program uses Graph::Graph6 read_graph() to read the graph sizes.
# This is a full parse of the graph6 file.  It validates file contents, but
# is a touch slow.  Perhaps Graph::Graph6 could have some option for reading
# just the size of each graph and ignoring its content (ie. set of edges).
#

use 5.006;
use strict;
use warnings;
use File::HomeDir;
use File::Spec;
use Graph::Graph6;
$|=1;

# ~/HOG/all.g6
my $home_dir = File::HomeDir->my_home;
my $all_filename = File::Spec->catfile($home_dir, 'HOG', 'all.g6');

open my $fh, '<', $all_filename or die;
my @counts;
my @sizes;
my $total_size = 0;
my $count = 0;
while (defined (my $str = readline $fh)) {
  Graph::Graph6::read_graph(str => $str,
                            num_vertices_ref => \my $num_vertices)
      or die "error reading graph6 from $all_filename";
  $count++;
  my $size = length($str);
  $total_size += $size;
  $counts[$num_vertices]++;
  $sizes[$num_vertices] += $size;
}

print "  num      num       size\n";
print "vertices  graphs    (bytes)\n";
foreach my $num_vertices (0 .. $#sizes) {
  if (defined $sizes[$num_vertices]) {
    printf "  %3d %8d  %8d\n",
      $num_vertices, $counts[$num_vertices], $sizes[$num_vertices];
  }
}
print "total $count graphs, $total_size bytes\n";

# about 11 mbytes / 20 parts = 550k each
my $parts = 20;
my $part_size = int($total_size / $parts);
my $target = $part_size;
my $cumul = 0;
my $count_parts = 0;
print "split to $parts parts roughly equal size ($part_size bytes)\n";
print "0, ";
foreach my $num_vertices (0 .. $#sizes) {
  if (defined $sizes[$num_vertices]) {
    $cumul += $sizes[$num_vertices];
    if ($cumul >= $target) {
      $count_parts++;
      if ($count_parts >= $parts) {
        print "999999";
        last;
      }
      print "$num_vertices, ";
      $target += $part_size;
    }
  }
}
print "\n";

exit 0;
