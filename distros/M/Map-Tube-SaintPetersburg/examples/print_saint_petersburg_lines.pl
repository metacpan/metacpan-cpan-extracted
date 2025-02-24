#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::SaintPetersburg;

# Object.
my $obj = Map::Tube::SaintPetersburg->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# Кировско-Выборгская линия
# Московско-Петроградская линия
# Невско-Василеостровская линия
# Правобережная линия
# Фрунзенско-Приморская линия