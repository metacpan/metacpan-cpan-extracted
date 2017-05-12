#!perl

use strict; use warnings;
use Games::Domino::Tile;
use Games::Domino::Player;
use Test::More tests => 7;

my ($player, $tile);

eval { Games::Domino::Player->new() };
like($@, qr/Missing required arguments: nam/);

eval { Games::Domino::Player->new({ name => 'A' }) };
like($@, qr/Only H or C allowed/);

$player = Games::Domino::Player->new({ name => 'H', show => 1 });

eval { $player->save() };
like($@, qr/ERROR: Undefined tile found/);

$player->save(Games::Domino::Tile->new({ left => 0, right => 1 }));
$player->save(Games::Domino::Tile->new({ left => 1, right => 1 }));
is($player->value, 3);

is($player->as_string, "[0 | 1]==[1 | 1]");

$tile = $player->pick();
is($tile->as_string, "[1 | 1]");

$player->save(Games::Domino::Tile->new({ left => 4, right => 5 }));
$tile = $player->pick([6,5]);
is($tile->as_string, "[4 | 5]");
