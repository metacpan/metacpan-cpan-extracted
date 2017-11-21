#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = 0.35;
eval "use Test::Map::Tube $min_ver tests => 3";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::NYC;

my $map = Map::Tube::NYC->new;
ok_map($map);
ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes($map, \@routes);

__DATA__
BMT Canarsie|Sixth Avenue|First Avenue|Sixth Avenue,Union Square,Third Avenue,First Avenue
BMT Nassau Street|Bowery|Fulton Street|Bowery,Canal Street,Chambers Street,Fulton Street
IND Crosstown|Broadway|Classon Avenue|Broadway,Flushing Avenue,Myrtle-Willoughby Avenues,Bedford-Nostrand Avenues,Classon Avenue
IND Eighth Avenue|Canal Street|High Street|Canal Street,Chambers Street,Fulton Street,High Street
IND Sixth Avenue|Grand Street-INDSixthAvenue|14th Street|Grand Street-INDSixthAvenue,Lafayette Street,West Fourth Street,14th Street
IRT Flushing|33rd Street|Hunters Point Avenue|33rd Street,Queensboro Plaza,Court Square,Hunters Point Avenue
IRT Lexington Avenue|14th Street|Spring Street|14th Street,West Fourth Street,Spring Street
