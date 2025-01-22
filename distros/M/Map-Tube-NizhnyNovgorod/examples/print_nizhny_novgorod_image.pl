#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);
use Map::Tube::NizhnyNovgorod;

# Object.
my $obj = Map::Tube::NizhnyNovgorod->new;

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'driver' => 'neato',
        'tube' => $obj,
);

# Get graph to file.
$g->graph('NizhnyNovgorod.png');

# Print file.
system "ls -l NizhnyNovgorod.png";

# Output like:
# -rw-r--r-- 1 skim skim 38058 22. led 11.37 NizhnyNovgorod.png