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

__END__

=head1 NAME

Game::Cribbage::Player::Hand - a player's hand of cards within a hands cycle

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Player::Hand;
	use Game::Cribbage::Deck::Card;

	my $hand = Game::Cribbage::Player::Hand->new(player => 'player1');

	$hand->add(Game::Cribbage::Deck::Card->new(suit => 'H', symbol => 'K'));

	my $card = $hand->get(0);
	my $card = $hand->get($other_card);  # match by card object

	$hand->discard(0, $crib_hand);

	my $score = $hand->calculate_score();

=head1 PROPERTIES

=head2 id

Read/write integer property for a database or external identifier.

	$hand->id;
	$hand->id($id);

=head2 player

Read/write string or object property identifying which player owns this hand
(e.g. C<'player1'>).

	$hand->player;

=head2 score

Read/write object property holding the L<Game::Cribbage::Score> result for
the main hand, populated by C<calculate_score>.

	$hand->score;

=head2 crib_score

Read/write object property holding the L<Game::Cribbage::Score> result for
the crib cards, populated by C<calculate_score> when crib cards are present.

	$hand->crib_score;

=head2 starter

Read/write object property holding the starter L<Game::Cribbage::Deck::Card>,
used when scoring the hand.

	$hand->starter;
	$hand->starter($card);

=head2 cards

Read/write arrayref of L<Game::Cribbage::Deck::Card> objects forming the
player's main hand.

	$hand->cards;

=head2 crib

Read/write arrayref of L<Game::Cribbage::Deck::Card> objects in the crib
(cards discarded by this player or assigned to them as crib holder).

	$hand->crib;

=head2 play_scored

Read/write arrayref of L<Game::Cribbage::Play::Score> objects recording
points earned during the play phase.

	$hand->play_scored;

=head1 FUNCTIONS

=head2 get

Returns the card at position C<$card_index> in C<cards> when given an
integer, or performs a C<match> lookup when given a card object.  Dies with
C<'NO CARD FOUND'> if no matching card exists.

	my $card = $hand->get(0);
	my $card = $hand->get($other_card);

=head2 match

Searches C<cards> for a card matching C<$card> (by suit and symbol) and
returns it, or returns 0 if not found.

	my $found = $hand->match($card);

=head2 add

Appends C<$card> to the C<cards> arrayref.

	$hand->add($card);

=head2 add_by_index

Places C<$card> at the specified index in C<cards>, replacing whatever was
there.

	$hand->add_by_index(2, $card);

=head2 discard_cards

Discards all cards in C<$cards> (arrayref of card objects to identify by
suit/symbol) from this hand into C<$crib> hand's crib.  Dies with
C<'CANNOT DISCARD'> if the hand has four or fewer cards.  Returns an
arrayref of the discarded cards.

	my $discarded = $hand->discard_cards(\@cards, $crib_hand);

=head2 discard

Discards a single card (by index or card object) from this hand into
C<$crib> hand's crib.  Dies with C<'CANNOT DISCARD'> if the hand has four
or fewer cards.

	$hand->discard(0, $crib_hand);
	$hand->discard($card, $crib_hand);

=head2 add_crib_card

Appends C<$card> to the C<crib> arrayref.

	$hand->add_crib_card($card);

=head2 calculate_score

Scores the main hand (and crib if present) using L<Game::Cribbage::Score>,
setting C<score> and optionally C<crib_score>.  Returns the combined numeric
score.

	my $total = $hand->calculate_score();

=head2 card_exists

Returns 1 if C<$card> is found in either C<cards> or C<crib>; otherwise 0.

	$hand->card_exists($card);

=head2 identify_worst_cards

Finds the best 4-card subset of the 6-card hand by brute-force combination
scoring, then returns a list C<(\@worst_cards, @worst_indexes)> identifying
the two cards to discard.  Dies if the hand does not have exactly 6 cards.

	my ($cards, @indexes) = $hand->identify_worst_cards();

=head2 validate_crib_cards

Checks that all cards in C<$cards> exist in the current C<crib>.  If not,
replaces the entire crib with the supplied cards.  Always returns 1.

	$hand->validate_crib_cards(\@cards);

=head2 best_run_play

Selects the best card to play from the unused cards in this hand, preferring
cards that score points.  Returns the chosen L<Game::Cribbage::Deck::Card>,
or a L<Game::Cribbage::Error> with C<go> set when no valid card remains.

	my $card = $hand->best_run_play($play);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-cribbage at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Cribbage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Cribbage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Cribbage>

=item * Search CPAN

L<https://metacpan.org/release/Game-Cribbage>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
