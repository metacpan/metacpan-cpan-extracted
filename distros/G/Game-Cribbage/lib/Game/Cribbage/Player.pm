package Game::Cribbage::Player;

use strict;
use warnings;

use Object::Proto::Sugar -types;

has [qw/id number/] => (
	is => 'ro',
	isa => Int
);

has name => (
	is => 'ro',
	isa => Str
);


sub player {
	return 'player' . $_[0]->number;
}

1;
