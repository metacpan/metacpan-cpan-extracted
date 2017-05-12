#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Sofia;

# Object.
my $obj = Map::Tube::Sofia->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Люлин'), decode_utf8('Вардар'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Люлин (Първи метродиаметър), Западен парк (Първи метродиаметър), Вардар (Първи метродиаметър)