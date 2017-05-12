#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Bucharest;

# Object.
my $obj = Map::Tube::Bucharest->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Iancului'), decode_utf8('Aviatorilor'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Iancului (Linia M1), Obor (Linia M1), Ștefan cel Mare (Linia M1), Piața Victoriei (Linia M1,Linia M2), Aviatorilor (Linia M2)