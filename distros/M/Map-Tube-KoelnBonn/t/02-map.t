#!perl
use 5.12.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::KoelnBonn;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::KoelnBonn' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes($map, \@routes);

__DATA__
Route 1|Neumarkt|Trimbornstr.|Neumarkt, Appellhofplatz / Breite Str., Dom / Hbf, Köln Hbf, Köln Messe / Deutz, Trimbornstr.
Route 2|wurzerstr.|RAMERSDORF|Wurzerstr., Hochkreuz / Deutsches Museum Bonn, Max-Löbner-Str. / Friesdorf, Olof-Palme-Allee, Robert-Schuman-Platz, Rheinaue, Ramersdorf
