#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(encode_utf8);
use Map::Tube::Moscow;

# Object.
my $obj = Map::Tube::Moscow->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# Арбатско-Покровская линия
# Бутовская линия
# Замоскворецкая линия
# Калининско-Солнцевская линия
# Калужско-Рижская линия
# Каховская линия
# Кольцевая линия
# Люблинско-Дмитровская линия
# Серпуховско-Тимирязевская линия
# Сокольническая линия
# Таганско-Краснопресненская линия
# Филёвская линия