#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::Novosibirsk;

# Object.
my $obj = Map::Tube::Novosibirsk->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# Дзержинская линия
# Ленинская линия