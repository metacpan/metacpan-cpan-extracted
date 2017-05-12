#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Kazan;

# Object.
my $obj = Map::Tube::Kazan->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Яшьлек'), decode_utf8('Горки'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Яшьлек (Центральная линия), Козья слобода (Центральная линия), Кремлёвская (Центральная линия), Площадь Габдуллы Тукая (Центральная линия), Суконная слобода (Центральная линия), Аметьево (Центральная линия), Горки (Центральная линия)