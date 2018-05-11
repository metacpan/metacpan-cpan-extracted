#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = 0.44;
eval "use Test::Map::Tube $min_ver tests => 3";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Barcelona;
my $map = Map::Tube::Barcelona->new;

SKIP: {
    ok_map($map) or skip "Skip map function and routes test.", 2;

    ok_map_functions($map);

    my @routes = <DATA>;
    ok_map_routes($map, \@routes);
}

__DATA__
L1 Route 1|Santa Coloma|Bon Pastor|Santa Coloma,Fondo,Can Peixauet,Bon Pastor
L2 Route 1|La Salut|Sant Roc|La Salut,Gorg,Sant Roc
L2 Route 2|Gorg|La Pau|Gorg,Sant Roc,Artigues Sant Adria,Verneda,La Pau
L3 Route 1|Can Cuiàs|Casa de l'Aigua|Can Cuiàs,Ciutat Meridiana,Torre Baró-Vallbona,Casa de l'Aigua
L4 Route 1|Roquetes|Maragall|Roquetes,Trinitat Nova,Via Júlia,Llucmajor,Maragall
L4 Route 2|roquetes|maragall|Roquetes,Trinitat Nova,Via Júlia,Llucmajor,Maragall
L5 Route 1|Virrei Amat|Congres|Virrei Amat,Maragall,Congres
L6 Route 1|St Gervasi|Diagonal|St Gervasi,Gracia,Diagonal
L6 Route 2|St Gervasi|Pl Molina|St Gervasi,Gracia,Pl Molina
L7 Route 1|Pl Molina|Diagonal|Pl Molina,Gracia,Diagonal
L7 Route 2|Pl Molina|St Gervasi|Pl Molina,Gracia,St Gervasi
L8 Route 1|Ildefons Cerda|Tarragona|Ildefons Cerda,Magoria La Campana,Espanya,Tarragona
L9 Route 1|Can Zam|Fondo|Can Zam,Singuerlin,Esglesia Major,Fondo
L9 Route 2|Can Peixauet|Llefia|Can Peixauet,Bon Pastor,Llefia
L10 Route 1|Gorg|Bon Pastor|Gorg,La Salut,Llefia,Bon Pastor
