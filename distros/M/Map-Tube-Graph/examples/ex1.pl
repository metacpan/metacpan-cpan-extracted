#!/usr/bin/env perl

use strict;
use warnings;

use English;
use Error::Pure qw(err);
use Map::Tube::Graph;

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
my $g = Map::Tube::Graph->new(
        'tube' => $tube,
);

# Get graph.
my $graph = $g->graph;

# Output.
print $graph."\n";

# Output without arguments like:
# Usage: /tmp/SZXfa2g154 metro

# Output with 'Prague' argument like:
# A02-A01,A02-A03,A04-A03,A04-MUSTEK,A07-A08,A07-MUZEUM,A08-A09,A09-A10,A11-A10,A11-A12,A13-A12,B01-B02,B03-B02,B03-B04,B05-B04,B05-B06,B07-B06,B08-B07,B08-B09,B10-B09,B10-B11,B11-B12,B17-B16,B17-B18,B18-B19,B19-B20,B21-B20,B21-B22,B22-B23,B24-B23,C01-C02,C03-C02,C04-C03,C04-C05,C06-C05,C06-C07,C09-MUZEUM,C11-C12,C11-MUZEUM,C13-C12,C13-C14,C14-C15,C16-C15,C16-C17,C18-C17,C18-C19,C20-C19,FLORENC-B14,FLORENC-B16,FLORENC-C07,FLORENC-C09,MUSTEK-B12,MUSTEK-B14,MUSTEK-MUZEUM