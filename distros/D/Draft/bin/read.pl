#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use Draft;
use Data::Dumper;

# Simple example, reads a drawing from disk and dumps the memory
# structure.

$Draft::PATH = $ARGV[0] || die "Usage: $0 /path/to/data.drawing/\n";

Draft->Read;

$Data::Dumper::Indent = 1;

print Dumper $Draft::WORLD;

1;
