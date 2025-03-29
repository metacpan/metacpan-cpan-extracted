#!perl
use 5.12.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::SanFrancisco;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::SanFrancisco' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Church|Embarcadero|Church, Van Ness, Civic Center, Powell, Montgomery, Embarcadero
Route 2|MASON & GREEN|rockridge|Mason & Green, Mason & Vallejo, Mason & Broadway, Mason & Pacific, Jackson & Mason, Washington & Mason, Washington & Powell, Powell & Clay, Chinatown - Rose Pak, Union Square/Market St, Market & 4th St, Powell, Montgomery, Embarcadero, West Oakland, 12th St/Oakland City Center, 19th St/Oakland, MacArthur, Rockridge
