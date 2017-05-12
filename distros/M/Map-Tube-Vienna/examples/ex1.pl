#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Vienna;

# Object.
my $obj = Map::Tube::Vienna->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Taborstraße'), decode_utf8('Kaisermühlen'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Taborstraße (U-Bahn-Linie U2), Praterstern (U-Bahn-Linie U1,U-Bahn-Linie U2), Vorgartenstraße (U-Bahn-Linie U1), Donauinsel (U-Bahn-Linie U1), Kaisermühlen (U-Bahn-Linie U1)