#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Map::Tube::Milan;

my $tube = Map::Tube::Milan->new();
my $route = $tube->get_shortest_route('Romolo', 'Lambrate F.S.');
my $correct_route = join ', ',
    'Romolo (M2)',
    'Porta Genova F.S. (M2)',
    'S. Agostino (M2)',
    'S. Ambrogio (M2, M4)',
    'Cadorna F.N. (M1, M2)',
    'Lanza (M2)',
    'Moscova (M2)',
    'Garibaldi F.S. (M2, M5)',
    'Gioia (M2)',
    'Centrale F.S. (M2, M3)',
    'Caiazzo (M2)',
    'Loreto (M1, M2)',
    'Piola (M2)',
    'Lambrate F.S. (M2)',
    ;
is($route, $correct_route, 'routes match');

done_testing;
