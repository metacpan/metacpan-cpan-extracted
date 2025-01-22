#!/usr/bin/env perl

use strict;
use warnings;

use Map::Tube::Prague;

# Object.
my $obj = Map::Tube::Prague->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print $_->name."\n"; } sort @{$lines_ar};

# Output:
# Linka A
# Linka B
# Linka C