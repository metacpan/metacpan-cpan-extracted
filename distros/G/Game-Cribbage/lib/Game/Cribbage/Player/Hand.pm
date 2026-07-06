package Game::Cribbage::Player::Hand;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use List::Util qw/first/;
use Game::Cribbage::Score;
use Game::Cribbage::Deck::Card;
use Game::Cribbage::Error;
use ntheory qw/forcomb vecsum/;
use Array::Diff;

has [qw/id/] => (
	is => 'rw',
	isa => Int
);

has [qw/player score crib_score starter/] => (
	is => 'rw',
	isa => Object
);


has [qw/crib cards play_scored/] => (
	is => 'rw',
	isa => 'ArrayRef',
	default => [],
);

sub get {
	my ($self, $card_index) = @_;
	my $card = ref $card_index ? $self->match($card_index) : $self->cards->[$card_index];
	if (!$card) {
		die 'NO CARD FOUND FOR CARD_INDEX ' . $card_index;
	}
	return $card;
};

sub match {
	my ($self, $card) = @_;
	for (@{ $self->cards }) {
		my $found = $_->match($card);
		if ($found) {
			return $_;
		}
	}
	return 0;
};

sub add {
	my ($self, $card) = @_;
	push @{$self->cards}, $card;
};

sub add_by_index {
	my ($self, $index, $card) = @_;
	$self->cards->[$index] = $card;
	return 1;
};

sub discard_cards {
	my ($self, $cards, $crib) = @_;
	my $count = scalar @{$self->cards};
	if ($count <= 4) {
		die 'CANNOT DISCARD ANY MORE CARDS';
	}
	my %mapped = ();
	for (@{$cards}) {
		$mapped{$_->suit}{$_->symbol} = 1;
	}
	my @cribbed;
	$cards = $self->cards;
	for (my $i = 0; $i < scalar @{$cards}; $i++) {
		my $card = $cards->[$i];
		if (exists $mapped{$card->suit} && exists $mapped{$card->suit}{$card->symbol}) {
			push @{$crib->crib}, splice(@{$cards}, $i, 1);
			push @cribbed, $card;
			$i--;
		}
	}
	$self->cards($cards);
	return \@cribbed;
};

sub discard {
	my ($self, $card, $crib) = @_;
	my $count = scalar @{$self->cards};
	if ($count <= 4) {
		die 'CANNOT DISCARD ANY MORE CARDS';
	}
	$card = $self->cards->[$card] if (!ref $card);
	my $str = $card->stringify;
	my $ind = first { $self->cards->[$_]->stringify eq $str } 0 .. $count - 1;
	splice @{$self->cards}, $ind, 1;
	$crib->add_crib_card($card);
};

sub add_crib_card {
	my ($self, $card) = @_;
	push @{$self->crib}, $card;
};

sub calculate_score {
	my ($self) = @_;
	my $starter = $self->starter ? 1 : 0;
	my @cards = (@{$self->cards}, ($starter ? $self->starter : ()));
	$self->score(Game::Cribbage::Score->new(with_starter => $starter, cards => \@cards));
	if ($self->crib && scalar @{$self->crib}) {
		@cards = (@{$self->crib}, ($starter ? $self->starter : ()));
		$self->crib_score(Game::Cribbage::Score->new(with_starter => $starter, cards => \@cards));
	}
	return $self->score->total_score + ($self->crib_score ? $self->crib_score->total_score : 0);
}

sub card_exists {
	my ($self, $card) = @_;

	for (@{ $self->cards }) {
		my $found = $_->match($card);
		if ($found) {
			return 1;
		}
	}
	
	if ($self->crib) {
		for (@{ $self->crib }) {
			my $found = $_->match($card);
			if ($found) {
				return 1;
			}
		}
	}
	
	return 0;
};

sub identify_worst_cards {
	my ($self) = @_;

	if (!(scalar @{$self->cards} == 6)) {
		die 'cards do not exists or two have been moved to the crib already';
	}

	my @index = 0 .. 5;
	my @cards = @{$self->cards};
	my %best = (
		score => 0,
		cards => []
	);
	forcomb {
		my @test = @cards[@_];
		my $score = Game::Cribbage::Score->new(with_starter => 0, cards => \@test);
		if (($score->total_score + 0) > $best{score}) {
			$best{score} = $score->total_score;
			$best{cards} = [@_];
		}
	} @index, 4;

	my $diff = Array::Diff->diff( \@index, $best{cards} );
	@index = @{ $diff->deleted };
	@cards = map { $self->get($_) } @index;
	return (\@cards, @index);
};

sub validate_crib_cards {
	my ($self, $cards) = @_;

	my $find_all = 1;
	for my $card (@{$cards}) {
		my $found = 0;
		for (@{ $self->crib }) {
			if ( $_->match($card) ) {
				$found = 1;
			}
		}
		if (! $found) {
			$find_all = 0;
			last;
		}
	}

	if (!$find_all) {
		$self->crib([]);
		for (@{$cards}) {
			push @{$self->crib}, Game::Cribbage::Deck::Card->new(
				suit => $_->suit, symbol => $_->symbol
			);
		}
	}

	return 1;
};

sub best_run_play {
	my ($self, $play) = @_;

	my ($best, $card);

	my @available = grep { ! $_->used } @{$self->cards};

	for (@available) {
		my $test = $play->test_card($self->player, $_);
		if (! ref $test && (!$best || $best < $test)) {
			$best = $test;
			$card = $_;
		}
	}

	if (! defined $best) {
		return Game::Cribbage::Error->new(
			message => 'No valid cards left to play for this run',
			go => 1
		);
	}

	if ($best == 0) {
		my $total = $play->total;
		@available = grep { ($total + $_->value) <= 31 } @available;
		@available = grep { $_->value != 5 } @available if scalar @available > 1 && grep { $_->value != 5 } @available;
		if (! scalar @available) {
			return Game::Cribbage::Error->new(
				message => 'No valid cards left to play for this run',
				go => 1
			);
		}
		$card = $available[int(rand(scalar @available - 1))];
	}

	return $card;
}

1;
