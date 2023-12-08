#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::Yekaterinburg;

# Object.
my $obj = Map::Tube::Yekaterinburg->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'tube' => $obj,
);

# Get graph to file.
$g->graph('Yekaterinburg.png');

# Print file.
system "ls -l Yekaterinburg.png";

# Output like:
# -rw-r--r-- 1 skim skim 28866 Feb 17 20:42 Yekaterinburg.png