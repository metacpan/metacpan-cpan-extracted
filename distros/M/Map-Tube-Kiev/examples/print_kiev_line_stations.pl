#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Kiev;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 line\n";
        exit 1;
}
my $line = decode_utf8($ARGV[0]);

# Object.
my $obj = Map::Tube::Kiev->new;

# Get stations for line.
my $stations_ar = $obj->get_stations($line);

# Print out.
map { print encode_utf8($_->name)."\n"; } @{$stations_ar};

# Output:
# Usage: __PROG__ line

# Output with 'foo' argument.
# Map::Tube::get_stations(): ERROR: Invalid Line Name [foo]. (status: 105) file __PROG__ on line __LINE__

# Output with 'Сирецько-Печерська лінія' argument.
# Сирець
# Дорогожичі
# Лук'янівська
# Золоті ворота
# Палац спорту
# Кловська
# Печерська
# Дружби народів
# Видубичі
# Славутич
# Осокорки
# Позняки
# Харківська
# Вирлиця
# Бориспільська
# Червоний хутір