#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Bucharest;

# Object.
my $obj = Map::Tube::Bucharest->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
 'callback_node' => \&node_color_without_label,
 'driver' => 'neato',
 'tube' => $obj,
);

# Get graph to file.
$g->graph('Bucharest.png');

# Print file.
system "ls -l Bucharest.png";

# Output like:
# -rw-r--r-- 1 skim skim 151426 Dec 24 12:03 Bucharest.png