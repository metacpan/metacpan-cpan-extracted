package Game::Cribbage::Play;

use strict;
use warnings;

use Rope;
use Rope::Autoload;

use Game::Cribbage::Play::Card;
use Game::Cribbage::Play::Score;
use Game::Cribbage::Error;
use ntheory qw/forcomb vecsum/;


property [qw/id next_to_play/] => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

property total => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => 0
);

property [qw/cards scored/] => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => []
);

function test_card => sub {
	my ($self, $player, $card) = @_;

	my $total = $self->calculate_total([@{$self->cards}, $card], 0);
	
	if ($total > 31) {
		return Game::Cribbage::Error->new(
			message => 'Total count would be greater than 31 if ' . $card->stringify . ' was to be played',
			go => 1
		);
	}

	my $score = Game::Cribbage::Play::Score->new(
		player => $player,
		card => $card
	);

	$self->calculate_pair($score, $card);

	$self->calculate_run($score, $card);

	$total = $self->calculate_total([@{$self->cards}, $card], 0);

	$self->calculate_hits($score, $total);

	return $score->score;
};

function card => sub {
	my ($self, $player, $card) = @_;

	my $total = $self->calculate_total([@{$self->cards}, $card], 0);

	if ($total > 31) {
		return Game::Cribbage::Error->new(
			message => 'Total count would be greater than 31 if ' . $card->stringify . ' was to be played',
			go => 1
		);
	}

	my $score = Game::Cribbage::Play::Score->new(
		player => $player,
		card => $card
	);

	$self->calculate_pair($score, $card);

	$self->calculate_run($score, $card);

	push @{$self->cards}, Game::Cribbage::Play::Card->new(
		player => $player,
		card => $card
	);

	$total = $self->calculate_total($self->cards, 1);

	$self->calculate_hits($score, $total);

	if ($score->score) {
		push @{$self->scored}, $score;
	}
	return $score;
};

function force_card => sub {
	my ($self, $player, $card) = @_;

	for (@{$self->cards}) {
		if ($_->card->match($card)) {
			return 0;
		}
	}
	
	return $self->card($player, $card);
};


function end_play => sub {
	my ($self) = @_;

	return unless $self->cards->[0];

	my $score = Game::Cribbage::Play::Score->new(
		player => $self->cards->[-1]->player,
		card => $self->cards->[-1],
		go => 1
	);

	push @{$self->scored}, $score;

	return $score;
};

function calculate_pair => sub {
	my ($self, $score, $card) = @_;

	if ($self->cards->[-1] && $self->cards->[-1]->symbol eq $card->symbol) {
		if ($self->cards->[-2] && $self->cards->[-2]->symbol eq $card->symbol) {
			if ($self->cards->[-3] && $self->cards->[-3]->symbol eq $card->symbol) {
				$score->pair = 3;
			} else {
				$score->pair = 2;
			}
		} else {
			$score->pair = 1;
		}
	}

	return 1;
};

function calculate_run => sub {
	my ($self, $score, $card) = @_; 
	my @cards = map { $_->card } @{$self->cards};
	my @values = map { $_->run_value } (@cards, $card);
	my $length = scalar @values - 1;
	my $set = 5;
	for my $n (qw/6 5 4 3 2/) {
		my $match = $set--;
		next unless $n <= $length;
		my @new = sort { $a <=> $b } @values[$length - $n .. $length];
		my $first = $new[0];
		for (my $i = 1; $i <= $n; $i++) {
			$first = $first + 1;
			if ($first != $new[$i]) {
				$match = 0;
				$i = $n + 1;
			}
		}
		if ($match) {
			$score->run = $match;
			last;
		}
	}

	return 1;
};

function calculate_total => sub {
	my ($self, $cards, $set) = @_;

	my $total = 0;
	for (@{ $cards }) {
		$total += $_->value;
	}
	if ($set) {
		$self->total = $total;
	}

	return $total;
};

function calculate_hits => sub {
	my ($self, $score, $total) = @_;
	if ($total == 15) {
		$score->fifteen = 1;
	} elsif ($total == 31) {
		$score->pegged = 1;
		$score->go = 1;
	}

	return 1;
};

1;
