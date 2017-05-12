#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Warsaw;

# Object.
my $obj = Map::Tube::Warsaw->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Imielin'), decode_utf8('Świętokrzyska'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Imielin (Linia M1), Stokłosy (Linia M1), Ursynów (Linia M1), Służew (Linia M1), Wilanowska (Linia M1), Wierzbno (Linia M1), Racławicka (Linia M1), Pole Mokotowskie (Linia M1), Politechnika (Linia M1), Centrum (Linia M1), Świętokrzyska (Linia M1)