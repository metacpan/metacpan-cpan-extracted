#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::Vienna;

# Object.
my $obj = Map::Tube::Vienna->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# U-Bahn-Linie U1
# U-Bahn-Linie U2
# U-Bahn-Linie U3
# U-Bahn-Linie U4
# U-Bahn-Linie U6