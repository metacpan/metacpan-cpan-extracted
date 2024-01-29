#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Malaga;

# Object.
my $obj = Map::Tube::Malaga->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Malaga.png');

# Print file.
system "ls -l Malaga.png";

# Output like:
# -rw-r--r-- 1 skim skim 51733 Sep  1 14:00 Malaga.png