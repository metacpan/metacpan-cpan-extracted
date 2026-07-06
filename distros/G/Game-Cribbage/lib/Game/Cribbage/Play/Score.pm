package Game::Cribbage::Play::Score;

use strict;
use warnings;

use Object::Proto::Sugar -types;

has scores => (
	is => 'ro',
	isa => HashRef,
	builder => sub {
		{
			run => [3, 4, 5, 6, 7],
			pair => [2, 6, 12],
			fifteen => 2,
			go => 1,
			pegged => 1,
			flipped => 1
		}
	}
);

has [qw/total_score pair run fifteen pegged go flipped/] => (
	is => 'rw',
	isa => Int
);

has [qw/player card/] => (
	is => 'ro',
	isa => Object
);

sub score {
	my ($self) = @_;
	my $score = 0;
	for (qw/fifteen go pegged flipped/) {
		if ( $self->$_ ) {
			$score += $self->scores->{$_};
		}
	}
	for (qw/pair run/) {
		if ($self->$_) {
			$score += $self->scores->{$_}->[$self->$_ - 1];
		}
	}
	$self->total_score($score);
	return $score;
}

1;
