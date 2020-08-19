#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Prague;

# Object.
my $obj = Map::Tube::Prague->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Dejvická'), decode_utf8('Ládví'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Dejvická (Linka A), Hradčanská (Linka A), Malostranská (Linka A), Staroměstská (Linka A), Můstek (Linka A, Tunnel), Můstek (Linka B, Tunnel), Náměstí Republiky (Linka B), Florenc (Linka B, Tunnel), Florenc (Linka C, Tunnel), Vltavská (Linka C), Nádraží Holešovice (Linka C), Kobylisy (Linka C), Ládví (Linka C)