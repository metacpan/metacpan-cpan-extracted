use v5.10;
use strict;
use warnings;

use Test::More;
use Game::TileMap;

my $legend = Game::TileMap->new_legend;

$legend
	->add_wall('#')
	->add_wall('X', 'other wall')
	->add_void('.')
	->add_void('O', 'other void')
	;

my $map_str = <<MAP;
#X
.O
MAP

my $map = Game::TileMap->new(legend => $legend, map => $map_str);

subtest 'testing check_within_map' => sub {
	ok $map->check_within_map(0, 0), '0:0 ok';
	ok $map->check_within_map(1, 0), '1:0 ok';
	ok !$map->check_within_map(0, 1), '0:1 ok';
	ok !$map->check_within_map(1, 1), '1:1 ok';
};

subtest 'testing check_can_be_accessed' => sub {
	ok !$map->check_can_be_accessed(0, 0), '0:0 ok';
	ok !$map->check_can_be_accessed(1, 0), '1:0 ok';
	ok !$map->check_can_be_accessed(0, 1), '0:1 ok';
	ok !$map->check_can_be_accessed(1, 1), '1:1 ok';
};

done_testing;

