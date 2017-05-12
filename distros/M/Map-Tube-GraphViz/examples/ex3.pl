#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Error::Pure qw(err);
use GraphViz2;
use Map::Tube::GraphViz;
use Map::Tube::GraphViz::Utils qw(node_color_without_label);

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 metro\n";
        exit 1;
}
my $metro = $ARGV[0];

# Object.
my $class = 'Map::Tube::'.$metro;
eval "require $class;";
if ($EVAL_ERROR) {
        err "Cannot load '$class' class.",
                'Error', $EVAL_ERROR;
}

# Metro object.
my $tube = eval "$class->new";
if ($EVAL_ERROR) {
        err "Cannot create object for '$class' class.",
                'Error', $EVAL_ERROR;
}

# GraphViz object.
my $g = Map::Tube::GraphViz->new(
        'callback_node' => \&node_color_without_label,
        'g' => GraphViz2->new(
                'global' => {
                        'directed' => 0,
                },
                'graph' => {
                        'label' => $metro,
                        'labelloc' => 'top',
                        'overlap' => 0,
                },
        ),
        'tube' => $tube,
);

# Get graph to file.
$g->graph($metro.'.png');

# Print file.
system "ls -l $metro.png";

# Output without arguments like:
# Usage: /tmp/SZXfa2g154 metro

# Output with 'Berlin' argument like:
# -rw-r--r-- 1 skim skim 1212857 Jan 27 07:51 Berlin.png