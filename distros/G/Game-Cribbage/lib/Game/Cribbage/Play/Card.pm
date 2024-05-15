package Game::Cribbage::Play::Card;

use strict;
use warnings;

use Rope;
use Rope::Autoload;

property [qw/player card/] => (
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1
);

function value => sub {
	$_[0]->card->value;
};

function symbol => sub {
	$_[0]->card->symbol;
};

1;
