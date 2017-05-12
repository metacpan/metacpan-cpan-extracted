#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::SaintPetersburg;

# Object.
my $obj = Map::Tube::SaintPetersburg->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
);

# Get graph to file.
$g->graph('SaintPetersburg.png');

# Print file.
system "ls -l SaintPetersburg.png";

# Output like:
# -rw-r--r-- 1 skim skim 207926 Feb 18 07:13 SaintPetersburg.png