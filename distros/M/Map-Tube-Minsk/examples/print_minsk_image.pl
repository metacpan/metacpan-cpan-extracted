#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Minsk;

# Object.
my $obj = Map::Tube::Minsk->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'driver' => 'neato',
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Minsk.png');

# Print file.
system "ls -l Minsk.png";

# Output like:
# -rw-r--r-- 1 skim skim 85988 Jan  4 11:32 Minsk.png