#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::Singapore;

# Object.
my $obj = Map::Tube::Singapore->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# Circle MRT Line
# Downtown MRT Line
# East West MRT Line
# North East MRT Line
# North South MRT Line