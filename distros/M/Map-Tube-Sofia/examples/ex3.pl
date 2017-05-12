#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Sofia;

# Object.
my $obj = Map::Tube::Sofia->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
); 

# Get graph to file.
$g->graph('Sofia.png');

# Print file.
system "ls -l Sofia.png";

# Output like:
# -rw-r--r-- 1 skim skim 78091 Jan 25 20:04 Sofia.png