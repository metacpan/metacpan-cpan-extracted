use v5.10;
use strict;
use warnings;

use Test::More;
use Game::TileMap;

my $legend = Game::TileMap->new_legend;

$legend
	->add_wall('#')
	->add_void('.')
	;

my $map_str = <<MAP;
...
...
...
MAP

my $map = Game::TileMap->new(legend => $legend, map => $map_str);

subtest 'check_within_map should not autovivify' => sub {
	ok !$map->check_within_map(100, 0), 'check_within_map with big x argument ok';
	is scalar @{$map->coordinates}, 3, 'size x unchanged';

	ok !$map->check_within_map(0, 100), 'check_within_map with big y argument ok';
	is scalar @{$map->coordinates->[0]}, 3, 'size y unchanged';
};

subtest 'get_tile should return undef on bad tile' => sub {
	ok !defined $map->get_tile(-3, 0), 'negative coord ok';
	ok !defined $map->get_tile(100, 0), 'huge x coord ok';
	ok !defined $map->get_tile(0, 100), 'huge y coord ok';
};

done_testing;

