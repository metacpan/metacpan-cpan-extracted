package Game::Cribbage::Round::Score;

use strict;
use warnings;

use Rope;
use Rope::Autoload;
use Game::Cribbage::Error;

property player1 => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

property player2 => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

property player3 => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

property player4 => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

1;
