#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Moscow;

# Object.
my $obj = Map::Tube::Moscow->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Moscow.png');

# Print file.
system "ls -l Moscow.png";

# Output like:
# -rw-r--r-- 1 skim skim 549576 Mar  9 21:39 Moscow.png