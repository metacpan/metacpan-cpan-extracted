#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Dnipropetrovsk;

# Object.
my $obj = Map::Tube::Dnipropetrovsk->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Комунарівська'), decode_utf8('Металургів'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Комунарівська (Центрально-Заводська лінія), Проспект Свободи (Центрально-Заводська лінія), Заводська (Центрально-Заводська лінія), Металургів (Центрально-Заводська лінія)