#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Nanjing;

# Object.
my $obj = Map::Tube::Nanjing->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'driver' => 'neato',
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Nanjing.png');

# Print file.
system "ls -l Nanjing.png";

# Output like:
# -rw-r--r-- 1 skim skim 336513 21. led 21.02 Nanjing.png