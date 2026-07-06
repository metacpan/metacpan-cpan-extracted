package Game::Cribbage::Round::Score;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Error;

has [qw/player1 player2 player3 player4/] => (
	is => 'rw',
	isa => HashRef
);

1;
