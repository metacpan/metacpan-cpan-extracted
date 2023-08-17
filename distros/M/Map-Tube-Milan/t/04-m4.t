#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 0.82;
use Map::Tube::Milan;
 
my $tube = Map::Tube::Milan->new();
my $route = $tube->get_shortest_route('Linate Aeroporto', 'Duomo');
my $correct_route = join ', ',
    'Linate Aeroporto (M4)',
    'Repetti (M4)',
    'Stazione Forlanini (M4)',
    'Argonne (M4)',
    'Susa (M4)',
    'Dateo (M4)',
    'San Babila (M1, M5)',
    'Duomo (M1, M3)',
    ;
is($route, $correct_route, 'routes match');

done_testing;
