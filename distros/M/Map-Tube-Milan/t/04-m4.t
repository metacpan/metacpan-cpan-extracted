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
    'Tricolore (M4)',
    'San Babila (M1, M4, M5)',
    'Duomo (M1, M3)',
    ;
is($route, $correct_route, 'routes match');

# Full route
$route = $tube->get_shortest_route('Linate Aeroporto', 'San Cristoforo');
$correct_route = join ', ',
    'Linate Aeroporto (M4)',
    'Repetti (M4)',
    'Stazione Forlanini (M4)',
    'Argonne (M4)',
    'Susa (M4)',
    'Dateo (M4)',
    'Tricolore (M4)',
    'San Babila (M1, M4, M5)',
    'Sforza Policlinico (M4)',
    'S. Sofia (M4)',
    'Vetra (M4)',
    'De Amicis (M4)',
    'S. Ambrogio (M2, M4)',
    'Coni Zugna (M4)',
    'California (M4)',
    'Bolivar (M4)',
    'Tolstoj (M4)',
    'Frattini (M4)',
    'Gelsomini (M4)',
    'Segneri (M4)',
    'San Cristoforo (M4)',
    ;
is($route, $correct_route, 'full routes match');

done_testing;
