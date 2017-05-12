#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Kharkiv;

# Object.
my $obj = Map::Tube::Kharkiv->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'driver' => 'neato',
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Kharkiv.png');

# Print file.
system "ls -l Kharkiv.png";

# Output like:
# -rw-r--r-- 1 skim skim 94579 Dec 23 14:15 Kharkiv.png