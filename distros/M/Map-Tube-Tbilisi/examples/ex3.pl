#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Tbilisi;

# Object.
my $obj = Map::Tube::Tbilisi->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'driver' => 'neato',
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Tbilisi.png');

# Print file.
system "ls -l Tbilisi.png";

# Output like:
# -rw-r--r-- 1 skim skim 68209 Jan  3 11:56 Tbilisi.png