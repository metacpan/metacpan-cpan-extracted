#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Prague;

# Object.
my $obj = Map::Tube::Prague->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Prague.png');

# Print file.
system "ls -l Prague.png";

# Output like:
# -rw-r--r-- 1 skim skim 166110 Apr  6 23:12 Prague.png