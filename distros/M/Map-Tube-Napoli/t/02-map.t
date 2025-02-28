#!perl
use 5.12.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Napoli;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Napoli' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Mergellina (A)|Piave|Mergellina (A), Piazza Amedeo, Montesanto, Piave
Route 2|materdei|PALAZZOLO|Materdei, Salvator Rosa, Quattro Giornate, Vanvitelli, Cimarosa, Palazzolo
