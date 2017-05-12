#!/usr/bin/perl -w

use strict;
use Test::More tests => 21;
use Geo::StreetAddress::FR;

my $address = Geo::StreetAddress::FR->new;
ok ($address, "Geo::StreetAddress::FR object created");

$address->adresse("15B rue des champs elysee");

my $res = $address->parse;

is ($res->numero_voie, 15, "Street number (15)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, 'B', "Street complement (B)");
is ($res->nom_voie, 'des champs elysee', "Street name (des champs elysee)");
is ($res->extension, undef, "Street extension (undef)");

$address->adresse("avenue des champs elysee");

$res = $address->parse;
is ($res->numero_voie, undef, "Street number (undef)");
is ($res->type_voie, 'avenue', "Street type (avenue)");
is ($res->complement, undef, "Street complement (undef)");
is ($res->nom_voie, 'des champs elysee', "Street name (des champs elysee)");
is ($res->extension, undef, "Street extension (undef)");

$address->adresse("15 rue des champs elysee");

$res = $address->parse;

is ($res->numero_voie, 15, "Street number (15)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'des champs elysee', "Street name (des champs elysee)");
is ($res->extension, undef, "Street extension (undef)");

$address->adresse("5 rue des champs elysee");

$res = $address->parse;

is ($res->numero_voie, 5, "Street number (5)");
is ($res->type_voie, 'rue', "Street type (rue)");
is ($res->complement, '', "Street complement (undef)");
is ($res->nom_voie, 'des champs elysee', "Street name (des champs elysee)");
is ($res->extension, undef, "Street extension (undef)");