#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Budapest;

# Object.
my $obj = Map::Tube::Budapest->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Fővám tér'), decode_utf8('Opera'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Fővám tér (Linia M4), Kálvin tér (Linia M3,Linia M4), Ferenciek tere (Linia M3), Deák Ferenc tér (Linia M1,Linia M2,Linia M3), Bajcsy-Zsilinszky út (Linia M1), Opera (Linia M1)