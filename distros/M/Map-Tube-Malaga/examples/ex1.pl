#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Map::Tube::Malaga;

# Object.
my $obj = Map::Tube::Malaga->new;

# Get route.
my $route = $obj->get_shortest_route('Princesa-Huelin', 'Barbarela');

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Princesa-Huelin (Línea 2), La Isla (Línea 2), El Perchel (Línea 2), El Perchel (Línea 1), La Unión (Línea 1), Barbarela (Línea 1)