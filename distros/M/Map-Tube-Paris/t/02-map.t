#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Paris;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Paris' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Rambuteau|Miromesnil|Rambuteau, Hôtel de Ville, Châtelet, Auber, Haussmann - Saint-Lazare, Saint-Lazare, Miromesnil
Route 2|PASSY|invalides|Passy, Bir-Hakeim, Champ de Mars - Tour Eiffel, Pont de l'Alma, Invalides
