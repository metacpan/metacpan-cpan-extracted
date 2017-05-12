#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Novosibirsk;

# Object.
my $obj = Map::Tube::Novosibirsk->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Сибирская'), decode_utf8('Гагаринская'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Сибирская (Дзержинская линия), Гагаринская (Ленинская линия)