#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Vienna;

# Object.
my $obj = Map::Tube::Vienna->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Vienna.png');

# Print file.
system "ls -l Vienna.png";

# Output like:
# -rw-r--r-- 1 skim skim 294217 Jan 25 01:11 Vienna.png