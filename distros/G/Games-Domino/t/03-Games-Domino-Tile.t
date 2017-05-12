#!perl

use strict; use warnings;
use Games::Domino::Tile;
use Test::More tests => 10;

my ($tile);

$tile = Games::Domino::Tile->new({ left => 1, right => 5 });
ok($tile);

is($tile->value, 6);
is($tile->as_string, "[1 | 5]");

eval { Games::Domino::Tile->new({ left => 1 }) };
like($@, qr/Missing required arguments: right/);

eval { Games::Domino::Tile->new({ right => 1 }) };
like($@, qr/Missing required arguments: left/);

eval { Games::Domino::Tile->new({ left => 1, right => 7 }); };
like($@, qr/Only 0 to 6 allowed/);

eval { Games::Domino::Tile->new({ left => 7, right => 1 }); };
like($@, qr/Only 0 to 6 allowed/);

eval { Games::Domino::Tile->new({ left => 1, right => 1, double => 0 }); };
like($@, qr/ERROR: Invalid double attribute for the tile/);

eval { Games::Domino::Tile->new({ left => 1, right => 0, double => 2 }); };
like($@, qr/ERROR: Invalid double attribute for the tile/);

eval { Games::Domino::Tile->new({ left => 1, right => 0, double => 1 }); };
like($@, qr/ERROR: Invalid double attribute for the tile/);
