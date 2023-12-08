#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Kharkiv;

# Object.
my $obj = Map::Tube::Kharkiv->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Спортивна'), decode_utf8('Київська'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Спортивна (Холодногірсько-Заводська лінія), Проспект Гагаріна (Холодногірсько-Заводська лінія), Радянська (Холодногірсько-Заводська лінія), Історичний музей (Салтівська лінія), Університет (Салтівська лінія), Пушкінська (Салтівська лінія), Київська (Салтівська лінія)