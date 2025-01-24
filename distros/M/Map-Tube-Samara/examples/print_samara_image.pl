#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Samara;

# Object.
my $obj = Map::Tube::Samara->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'driver' => 'neato',
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Samara.png');

# Print file.
system "ls -l Samara.png";

# Output like:
# -rw-r--r-- 1 skim skim 28389 Jan  8 21:11 Samara.png