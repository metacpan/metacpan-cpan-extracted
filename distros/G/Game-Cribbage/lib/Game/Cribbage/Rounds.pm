package Game::Cribbage::Rounds;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Round;

has number => (
	is => 'ro',
	isa => Int
);

has history => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has current_round => (
	is => 'rw',
	isa => Object,
);

sub next_round {
	my ($self, $game, %args) = @_;
	if (scalar @{$self->history} >= $self->number) {
		die 'DISPLAY THE RESULT FOR THE GAME';
	}
	my $round = Game::Cribbage::Round->new(
		number => scalar @{$self->history} + 1,	
		%args
	)->init($game);
	push @{$self->history}, $round;
	$self->current_round($round);
	return $self;
}

1;
