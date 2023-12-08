#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Kiev;

# Object.
my $obj = Map::Tube::Kiev->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'driver' => 'neato',
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Kiev.png');

# Print file.
system "ls -l Kiev.png";

# Output like:
# -rw-r--r-- 1 skim skim 163162 Jan 10 14:20 Kiev.png