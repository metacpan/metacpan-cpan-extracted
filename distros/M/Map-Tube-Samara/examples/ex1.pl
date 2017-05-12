#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Samara;

# Object.
my $obj = Map::Tube::Samara->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Гагаринская'), decode_utf8('Безымянка'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Гагаринская (Первая линия), Спортивная (Первая линия), Советская (Первая линия), Победа (Первая линия), Безымянка (Первая линия)