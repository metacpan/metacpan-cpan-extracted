#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::NizhnyNovgorod;

# Object.
my $obj = Map::Tube::NizhnyNovgorod->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# Автозаводская линия
# Сормовская линия