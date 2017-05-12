#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Map::Tube::Kharkiv;

# Object.
my $obj = Map::Tube::Kharkiv->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# Олексіївська лінія
# Салтівська лінія
# Холодногірсько-Заводська лінія