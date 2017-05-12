#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde
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


# Usage: perl graph-easy-print.pl filename.g6
#
# Read a file of graph6 or sparse6 graphs and print them using the
# Graph::Easy ascii box layout.
#
# For example a file of all 6-vertex trees can be found at the House of
# Graphs
#
#     https://hog.grinvin.org/Trees
#     https://hog.grinvin.org/data/trees/trees06.g6
#

use 5.006;
use strict;
use Graph::Easy::Parser::Graph6;

if (! @ARGV) {
  print STDERR "Usage: perl graph-easy-print.pl filename.g6 ...\n";
  exit 1;
}

my $parser = Graph::Easy::Parser::Graph6->new;
foreach my $filename (@ARGV) {
  open my $fh, '<', $filename or die "Cannot open $filename: $!";

  while (my $graph = $parser->from_file($fh)) {
    print "\n";
    print $graph->as_ascii;
    print '_'x70, "\n";
    print "\n";
  }
}
exit 0;
