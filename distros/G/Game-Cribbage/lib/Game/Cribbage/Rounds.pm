package Game::Cribbage::Rounds;

use strict;
use warnings;

use Rope;
use Rope::Autoload;
use Game::Cribbage::Round;

property number => (
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1
);

property history => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => []
);

property current_round => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

function next_round => sub {
	my ($self, $game, %args) = @_;
	if (scalar @{$self->history} >= $self->number) {
		die 'DISPLAY THE RESULT FOR THE GAME';
	}
	my $round = Game::Cribbage::Round->new(
		_game => $game,
		number => scalar @{$self->history} + 1,	
		%args
	);
	push @{$self->history}, $round;
	$self->current_round = $round;
	return $self;
};

1;
