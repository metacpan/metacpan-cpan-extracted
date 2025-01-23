#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Singapore;

# Object.
my $obj = Map::Tube::Singapore->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
); 

# Get graph to file.
$g->graph('Singapore.png');

# Print file.
system "ls -l Singapore.png";

# Output like:
# -rw-r--r-- 1 skim skim 294531 22. led 18.13 Singapore.png