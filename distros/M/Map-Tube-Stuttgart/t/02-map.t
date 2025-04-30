#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Stuttgart;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Stuttgart' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Börsenplatz|Bopser|Börsenplatz, Hauptbahnhof, Schlossplatz, Charlottenplatz, Olgaeck, Dobelstr., Bopser
Route 2|BIHLPLATZ|peregrinastr.|Bihlplatz, Erwin-Schoettle-Platz, Marienplatz, Liststr., Pfaffenweg, Wielandshöhe, Haigst, Nägelestr., Zahnradbahnhof, Degerloch, Degerloch Albstr., Peregrinastr.
