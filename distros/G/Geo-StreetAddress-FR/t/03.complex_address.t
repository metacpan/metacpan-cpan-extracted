#!/usr/bin/perl -w

use strict;
use Test::More tests => 61;
use Geo::StreetAddress::FR;

my $address = Geo::StreetAddress::FR->new;
ok ($address, "Geo::StreetAddress::FR object created");

$address->adresse("residence ste marie 90B rue de la poste");

my $res = $address->parse;

is ($res->numero_voie, 90, "Street number (90)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, "B", "Street complement (B)");
is ($res->nom_voie, 'de la poste', "Street name (de la poste)");
is ($res->extension, 'residence ste marie', 'Street extension (residence ste marie)');

$address->adresse("res ste marie 9 rue de la poste");

$res = $address->parse;

is ($res->numero_voie, 9, "Street number (9)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'de la poste', "Street name (de la poste)");
is ($res->extension, 'res ste marie', 'Street extension (res ste marie)');


$address->adresse("bat C 13 rte Bordeaux");

$res = $address->parse;

is ($res->numero_voie, 13, "Street number (13)");
is ($res->type_voie, 'rte', "Street type (rte)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Bordeaux', "Street name (Bordeaux)");
is ($res->extension, "bat C", "Street extension (bat C)");

$address->adresse("resid Club Cameyrac 27 all Grand Bois");

$res = $address->parse;

is ($res->numero_voie, 27, "Street number (27)");
is ($res->type_voie, 'all', "Street type (all)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Grand Bois', "Street name (Grand Bois)");
is ($res->extension, "resid Club Cameyrac", "Street extension (resid Club Cameyrac)");

$address->adresse("Etg 4 Esc 6 Ent 59 resid Bleuets");

$res = $address->parse;

is ($res->numero_voie, '', "Street number (undef)");
is ($res->type_voie, 'resid', "Street type (undef)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Bleuets', "Street name (undef)");
is ($res->extension, "Etg 4 Esc 6 Ent 59", "Street extension (Etg 4 Esc 6 Ent 59)");

$address->adresse("resid les bleuets bat 1 resid Bleuets");

$res = $address->parse;

is ($res->numero_voie, '', "Street number (undef)");
is ($res->type_voie, 'resid', "Street type (undef)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Bleuets', "Street name (undef)");
is ($res->extension, "resid les bleuets bat 1", "Street extension (résid les bleuets bat 1)");

$address->adresse("Et 4 Porte Milieu 1 r Jean Jaures");

$res = $address->parse;

is ($res->numero_voie, 1, "Street number (undef)");
is ($res->type_voie, 'r', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Jean Jaures', "Street name (Jean Jaurès)");
is ($res->extension, "Et 4 Porte Milieu", "Street extension (Et 4 Porte Milieu 1)");

$address->adresse("3 allee Chenes lotissement Heurte Biche");

$res = $address->parse;

is ($res->numero_voie, 3, "Street number (3)");
is ($res->type_voie, 'allee', "Street type (allee)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Chenes lotissement Heurte Biche', "Street name (Chenes lotissement Heurte Biche)");
is ($res->extension, undef, "Street extension (undef)");

$address->adresse("Residence la Roseraie 3 rue Garenne");

$res = $address->parse;

is ($res->numero_voie, 3, "Street number (3)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Garenne', "Street name (Jean Jaurès)");
is ($res->extension, "Residence la Roseraie", "Street extension (Residence la Roseraie)");

$address->adresse("Maison de Retraite 3 rue Garenne");

$res = $address->parse;

is ($res->numero_voie, 3, "Street number (3)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'Garenne', "Street name (Garenne)");
is ($res->extension, "Maison de Retraite", "Street extension (Maison de Retraite)");

$address->adresse("78 rue nationale maison de retraite");

$res = $address->parse;

is ($res->numero_voie, 78, "Street number (78)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'nationale', "Street name (nationale)");
is ($res->extension, "maison de retraite", "Street extension (maison de retraite)");

    
$address->adresse("residence les rivieres rue nationale");
    
$res = $address->parse;
    
is ($res->numero_voie, '', "Street number (undef)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'nationale', "Street name (nationale)");
TODO: {
    local $TODO = "still fail on this case";
    is ($res->extension, "residence les rivieres", "Street extension (residences les rivieres)");
}