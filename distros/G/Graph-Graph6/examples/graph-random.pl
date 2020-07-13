#!/usr/bin/perl -w

# Copyright 2015, 2017, 2018 Kevin Ryde
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


# Usage: perl graph-random.pl
#
# Create a random Graph.pm graph and print it to stdout in graph6 format.
#
# The "header" option is included for human readability, so you don't think
# the output is tty line noise.  That header is not needed for reading and
# writing between programs.

use 5.006;
use strict;
use Graph;
use Graph::Writer::Graph6;

my $graph = Graph->random_graph (vertices => 20);
my $writer = Graph::Writer::Graph6->new (header => 1);
$writer->write_graph($graph, \*STDOUT);
exit 0;
