package Game::Cribbage::Round;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Cribbage::Round::Score;
use Game::Cribbage::Hands;

has id => (
	is => 'rw',
	isa => Int
);

has number => (
	is => 'ro',
	isa => Int
);

has [qw/score current_hands/] => (
	is => 'rw',
	isa => Object
);

has complete => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has history => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

sub init {
	my ($self, $game) = @_;
	my %score = ();
	for (@{$game->players}) {
		$score{$_->player} = {
			current =>  0,
			last => 0
		};
	}
	$self->score(Game::Cribbage::Round::Score->new(%score));
	$self->next_hands($game);
}

sub reset_hands {
	my ($self, $game) = @_;
	$self->history([]);
	my %score = ();
	for (@{$game->players}) {
		$score{$_->player} = {
			current => 0,
			last => 0
		};
	}
	$self->score(Game::Cribbage::Round::Score->new(%score));
	$self->next_hands($game);
}

sub next_hands {
	my ($self, $game, %args) = @_;
	$game->shuffle();
	my $hands = Game::Cribbage::Hands->new(%args)->init($game);
	$self->current_hands($hands);
	push @{$self->history}, $hands;
	return $self;
}

sub end_hands {
	my ($self, $game) = @_;
	my $scored = $self->current_hands->score_hands();
	for my $hand (keys %{$scored}) {
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $scored->{$hand};
	}
	$self->next_hands($game, crib_player => $self->next_crib_player($game));
}

sub add_player_card_by_index {
	my ($self, $index, $player, $card) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->current_hands->$hand->add_by_index($index, $card);
}

sub add_player_card {
	my ($self, $player, $card) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->current_hands->$hand->add($card);
}

sub add_starter_card {
	my ($self, $player, $card) = @_;
	my $score = $self->current_hands->add_starter_card($player, $card);
	if (ref $score && $score->score) {
		my $hand = ref $player ? $player->player : $player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $score;
}

sub validate_crib_cards {
	my ($self, $cards) = @_;
	my $crib = $self->current_hands->crib_player;
	$self->current_hands->$crib->validate_crib_cards($cards);
}

sub next_to_play {
	my ($self, $game) = @_;
	my $next = $self->current_hands->play->next_to_play;
	my $player;
	for (@{$game->players}) {
		if ($next eq $_->player) {
			$player = $_;
			last;
		}
	}
	return $player;
}

sub next_to_play_id {
	my ($self, $game) = @_;
	my $next = $self->next_to_play($game);
	return $next->id;
}

sub get_crib_player {
	my ($self, $game) = @_;
	my $player;
	for (@{$game->players}) {
		if ($self->current_hands->crib_player eq $_->player) {
			$player = $_;
			last;
		}
	}
	return $player;
}

sub next_crib_player {
	my ($self, $game) = @_;
	my $current = $self->get_crib_player($game);
	my $next;
	if (scalar @{$game->players} == $current->number) {
		$next = 'player1';
	} else {
		$next = 'player' . ($current->number + 1);
	}
	return $next;
}

sub crib_player_id {
	my ($self, $game) = @_;
	my $player = $self->get_crib_player($game);
	return $player ? $player->id : $player;
}

sub crib_player_name {
	my ($self, $game) = @_;
	my $player = $self->get_crib_player($game);
	return $player ? $player->name : $player;
}

sub crib_player_number {
	my ($self, $game) = @_;
	my $player = $self->get_crib_player($game);
	return $player ? $player->number : $player;
}

sub crib_player_cards {
	my ($self, $player, $cards) = @_;
	my $hand = ref $player ? $player->player : $player;
	my $crib = $self->current_hands->crib_player;
	return $self->current_hands->$hand->discard_cards($cards, $self->current_hands->$crib);
}

sub crib_player_card {
	my ($self, $player, $card_index) = @_;
	my $hand = $player->player;
	my $crib = $self->current_hands->crib_player;
	$self->current_hands->$hand->discard($card_index, $self->current_hands->$crib);
}

sub force_play_card {
	my ($self, $card) = @_;
	my ($score, $player) = $self->current_hands->force_play_card($card);
	if (ref $score && $score->score) {
		my $hand = ref $player ? $player->player : $player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $score;
}

sub play_player_card {
	my ($self, $player, $card_index) = @_;
	my $score = $self->current_hands->play_card($player, $card_index);
	if (ref $score && $score->score) {
		my $hand = ref $player ? $player->player : $player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $score;
}

sub card_exists {
	my ($self, $player, $card) = @_;
	return $self->current_hands->card_exists($player, $card);
}

sub get_player_card {
	my ($self, $player, $card_index) = @_;
	$self->current_hands->get_card($player, $card_index);
}

sub current_play_score {
	my ($self) = @_;
	$self->current_hands->play_score();
}

sub last_play_score {
	my ($self) = @_;
	$self->current_hands->last_play_score();
}

sub cannot_play_a_card {
	my ($self, $player) = @_;
	$self->current_hands->cannot_play_a_card($player);
}

sub next_play {
	my ($self, $game) = @_;
	my $score = $self->current_hands->next_play($game);
	if (ref $score && $score->score) {
		my $hand = ref $score->player ? $score->player->player : $score->player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $self->current_hands->play;
}

sub end_play {
	my ($self) = @_;
	my $score = $self->current_hands->end_play();
	if (ref $score && $score->score) {
		my $hand = ref $score->player ? $score->player->player : $score->player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return 1;
}

sub identify_worst_cards {
	my ($self, $player) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->current_hands->$hand->identify_worst_cards();
}

sub best_run_play {
	my ($self, $player) = @_;
	$self->current_hands->best_run_play($player);
}

sub hand_play_history {
	my ($self, $player) = @_;
	my @history = @{$self->current_hands->play_history};
	my $current = pop @history;
	my $count_cards = 0;
	for (@history) {
		$count_cards += scalar @{$_->cards};
	}
	return {
		used_count => $count_cards,
		current_play => $current
	};
}

1;

__END__

=head1 NAME

Game::Cribbage::Round - a full scoring round of cribbage

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Round;

	my $round = Game::Cribbage::Round->new(number => 1)->init($game);

	# deal cards
	$round->add_player_card($player, $card);

	# discard to crib
	$round->crib_player_cards($player, \@discard);

	# play phase
	$round->play_player_card($player, 0);

	# score
	$round->add_starter_card($player, $starter);
	$round->end_hands($game);

=head1 DESCRIPTION

Orchestrates one complete round of cribbage: dealing, crib discarding, play
phase, and hand scoring.  Wraps a L<Game::Cribbage::Hands> object (the
current hands cycle) and a L<Game::Cribbage::Round::Score> tracker, and
maintains a history of all hands cycles played within the round.

=head1 PROPERTIES

=head2 id

Read/write integer property for a database or external identifier.

	$round->id;
	$round->id(42);

=head2 number

Readonly integer property holding the round number within the game (1-based).

	$round->number;

=head2 score

Read/write object property holding the L<Game::Cribbage::Round::Score>
tracking cumulative per-player scores within this round.

	$round->score;

=head2 current_hands

Read/write object property holding the active L<Game::Cribbage::Hands>
cycle.

	$round->current_hands;

=head2 complete

Read/write boolean property; set to 1 when the round is finished.

	$round->complete;

=head2 history

Read/write arrayref of all L<Game::Cribbage::Hands> objects created in this
round, in order.

	$round->history;

=head1 FUNCTIONS

=head2 init

Initialises the round: builds the per-player score structure and calls
C<next_hands>.  Returns C<$self>.

	my $round = Game::Cribbage::Round->new(number => 1)->init($game);

=head2 reset_hands

Resets scores and history and begins a fresh hands cycle.  Used when
replaying or restoring game state.

	$round->reset_hands($game);

=head2 next_hands

Shuffles the deck, creates a new L<Game::Cribbage::Hands>, appends it to
C<history>, and sets it as C<current_hands>.  Returns C<$self>.  Accepts
optional named args forwarded to the Hands constructor (e.g. C<crib_player>).

	$round->next_hands($game, crib_player => 'player2');

=head2 end_hands

Scores all hands for the current cycle, updates C<score>, then starts the
next hands cycle with the crib rotating to the next player.

	$round->end_hands($game);

=head2 add_player_card_by_index

Adds C<$card> to C<$player>'s hand at the given array index.

	$round->add_player_card_by_index($index, $player, $card);

=head2 add_player_card

Appends C<$card> to C<$player>'s hand.

	$round->add_player_card($player, $card);

=head2 add_starter_card

Sets the starter card for the current hands cycle, scores nobs if applicable,
and updates round scores.  Returns the score object (or 0).

	$round->add_starter_card($player, $card);

=head2 validate_crib_cards

Delegates to the crib player's hand to validate (and if necessary replace)
their crib cards.

	$round->validate_crib_cards(\@cards);

=head2 next_to_play

Returns the L<Game::Cribbage::Player> object whose turn it is to play next.

	my $player = $round->next_to_play($game);

=head2 next_to_play_id

Returns the C<id> of the player whose turn it is to play next.

	my $id = $round->next_to_play_id($game);

=head2 get_crib_player

Returns the L<Game::Cribbage::Player> object who currently holds the crib.

	my $player = $round->get_crib_player($game);

=head2 next_crib_player

Returns the player key string (e.g. C<'player2'>) for the next crib holder,
wrapping from last player back to C<'player1'>.

	my $next = $round->next_crib_player($game);

=head2 crib_player_id

Returns the C<id> of the crib player, or C<undef> if not set.

	my $id = $round->crib_player_id($game);

=head2 crib_player_name

Returns the name of the crib player.

	my $name = $round->crib_player_name($game);

=head2 crib_player_number

Returns the seat number of the crib player.

	my $num = $round->crib_player_number($game);

=head2 crib_player_cards

Discards multiple cards from C<$player>'s hand into the crib.

	$round->crib_player_cards($player, \@cards);

=head2 crib_player_card

Discards a single card (by index) from C<$player>'s hand into the crib.

	$round->crib_player_card($player, 0);

=head2 force_play_card

Plays a card bypassing turn-order checks, updating round scores.  Returns
the L<Game::Cribbage::Play::Score> object.

	my $score = $round->force_play_card($card);

=head2 play_player_card

Plays C<$card_index> for C<$player> with full turn-order and 31-point
validation.  Updates round scores on success.  Returns the score or an error.

	my $score = $round->play_player_card($player, 0);

=head2 card_exists

Returns 1 if C<$card> exists in C<$player>'s current hand.

	$round->card_exists($player, $card);

=head2 get_player_card

Returns the card at C<$card_index> in C<$player>'s hand.

	my $card = $round->get_player_card($player, 0);

=head2 current_play_score

Returns the running total of the current play sequence.

	my $total = $round->current_play_score();

=head2 last_play_score

Returns the running total of the previous completed play sequence.

	my $total = $round->last_play_score();

=head2 cannot_play_a_card

Declares that C<$player> cannot play.  Delegates to the current hands cycle.

	$round->cannot_play_a_card($player);

=head2 next_play

Advances to the next play sequence (or ends hands if all cards exhausted).
Returns the new active play object.

	my $play = $round->next_play($game);

=head2 end_play

Ends the current play sequence, awarding the go point.  Returns 1.

	$round->end_play();

=head2 identify_worst_cards

Returns the worst two cards to discard from C<$player>'s 6-card hand.

	my ($cards, @indexes) = $round->identify_worst_cards($player);

=head2 best_run_play

Returns the best card for C<$player> to play, delegating to the hands cycle.

	my $card = $round->best_run_play($player);

=head2 hand_play_history

Returns a hashref summarising play history:

=over 4

=item * C<used_count> - total cards played in all completed play sequences

=item * C<current_play> - the active L<Game::Cribbage::Play> object

=back

	my $hist = $round->hand_play_history();

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
