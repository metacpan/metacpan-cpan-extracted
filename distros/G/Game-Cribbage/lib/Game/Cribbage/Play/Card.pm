package Game::Cribbage::Play::Card;

use strict;
use warnings;

use Object::Proto::Sugar -types;

has [qw/player card/] => (
	is => 'ro',
	isa => Object
);

sub value {
	$_[0]->card->value;
}

sub symbol {
	$_[0]->card->symbol;
}

1;
