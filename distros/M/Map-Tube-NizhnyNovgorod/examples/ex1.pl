#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::NizhnyNovgorod;

# Object.
my $obj = Map::Tube::NizhnyNovgorod->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('Буревестник'), decode_utf8('Кировская'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: Буревестник (Сормовская линия), Бурнаковская (Сормовская линия), Канавинская (Сормовская линия), Московская (Автозаводская линия,Сормовская линия), Чкаловская (Автозаводская линия), Ленинская (Автозаводская линия), Заречная (Автозаводская линия), Двигатель Революции (Автозаводская линия), Пролетарская (Автозаводская линия), Автозаводская (Автозаводская линия), Комсомольская (Автозаводская линия), Кировская (Автозаводская линия)