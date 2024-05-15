package Game::Cribbage::Deck;

use strict;
use warnings;

use Rope;
use Rope::Autoload;
use List::Util qw//;
use Game::Cribbage::Deck::Card;

property deck => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

function cards => sub {
	return $_[0]->deck;
};

function INITIALISED => sub {
	return $_[0]->reset();
};

function reset => sub {
	$_[0]->shuffle();
	$_[0];
};

function shuffle => sub {
	my $i = 0;
	my @DECK;
	for my $suit (qw/H S D C/) {
		for ('A', 2 .. 10, 'J', 'Q', 'K') {
			$i++;
			push @DECK,
				Game::Cribbage::Deck::Card->new(
					suit => $suit,
					symbol => $_,
					id => $i	
				);
		}
	}
	$_[0]->deck = [List::Util::shuffle @DECK];
	$_[0];
};

function draw => sub {
	shift @{$_[0]->deck}
};

function force_draw => sub {
	my ($self, $card) = @_;
	
	my $i = 0;
	for (@{$self->deck}) {
		if ($_->suit eq $card->{suit} && $_->symbol =~ m/^$card->{symbol}$/) {
			last;
		} else {
			$i++;
		}
	}

	return splice @{$self->deck}, $i, 1;
};

function get => sub {
	$_[0]->deck->[$_[1]];
};

function card_exists => sub {
	my ($self, $card) = @_;

	for (@{$self->deck}) {
		if ($_->suit eq $card->{suit} && $_->symbol =~ m/^$card->{symbol}$/) {
			return 1;
		}
	}

	return 0;
};

function generate_card => sub {
	return Game::Cribbage::Deck::Card->new(
		%{ $_[1] }
	);
};

1;

