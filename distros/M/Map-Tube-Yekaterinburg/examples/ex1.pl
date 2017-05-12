#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Yekaterinburg;

# Object.
my $obj = Map::Tube::Yekaterinburg->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Геологическая'), decode_utf8('Уралмаш'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Геологическая (Первая линия), Площадь 1905 года (Первая линия), Динамо (Первая линия), Уральская (Первая линия), Машиностроителей (Первая линия), Уралмаш (Первая линия)