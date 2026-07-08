package Game::Cribbage::Board;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Player;
use Game::Cribbage::Deck;
use Game::Cribbage::Rounds;

has players => (
	is => 'rw',
	isa => ArrayRef,
	default => [],
);

has [qw/deck rounds/] => (
	is => 'rw',
	isa => Object,
);

sub add_player {
	my ($self, %player) = @_;
	push @{$self->players}, Game::Cribbage::Player->new(
		number => scalar @{$self->players} + 1,
		%player
	);
	return $self;
}

sub add_player_if_not_exists {
	my ($self, %player) = @_;
	my $exists = $self->get_player(%player);
	if (!$exists) {
		$self->add_player(%player); 
		$exists = $self->get_player(%player);
		return ($exists, 0);
	}
	return ($exists, 1);
}

sub get_player {
	my ($self, %player) = @_;
	my $exists = 0;
	for (@{$self->players}) {
		if ($_->name =~ m/^$player{name}$/) {
			return $_;
		}
	}
}

sub build_deck {
	$_[0]->deck(Game::Cribbage::Deck->new());
}

sub build_rounds {
	$_[0]->rounds(Game::Cribbage::Rounds->new(
		number => $_[1]
	));
}

sub start_game {
	my ($self, %args) = @_;
	$self->build_deck() if (!$self->deck);
	$self->build_rounds($args{rounds} || 1) if (!$self->rounds);
	$self->rounds->next_round($self, ($args{id} ? (id => $args{id}) : ())) if (!$self->rounds->current_round || $self->rounds->current_round->complete);
}

sub next_hands {
	my ($self, %args) = @_;
	$self->rounds->current_round->next_hands(%args);
}

sub force_to_crib {
	my ($self, $card) = @_;

	my $crib = $self->crib_player_identifier;

	my $round = $self->rounds->current_round;

	if ($self->deck->card_exists($card)) {
		$round->add_crib_card(
			$self->deck->force_draw($card)
		);
		return 1;
	}

	# confirm it exists in the players hand
	if ($round->card_exists($crib, $card)) {
		return 1;
	}

	$round->add_crib_card(
		$self->deck->generate_card($card)
	);

	return 1;
}

sub force_draw_card {
	my ($self, $player, $index, $card) = @_;

	my $round = $self->rounds->current_round;

	if ($self->deck->card_exists($card)) {
		$round->add_player_card(
			$player,
			$self->deck->force_draw($card)
		);
		return 1;
	}

	# confirm it exists in the players hand
	if ($round->card_exists($player, $card)) {
		return 1;
	}

	$round->add_player_card_by_index(
		$index,
		$player,
		$self->deck->generate_card($card)
	);

	return 1;
}

sub draw_hands {
	my ($self) = @_;

	my $round = $self->rounds->current_round;

	for (0 .. 5) {
		for (@{$self->players}) {
			$round->add_player_card(
				$_,
				$self->deck->draw
			);
		}
	}
}

sub add_starter_card {
	my ($self, $player, $card) = @_;
	$self->rounds->current_round->current_hands->add_starter_card($player, $card);
}

sub get_hands {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands;
}

sub identify_worst_cards {
	my ($self, $player) = @_;
	$self->rounds->current_round->identify_worst_cards($player);
}

sub validate_crib_cards {
	my ($self, $cards) = @_;
	$self->rounds->current_round->validate_crib_cards($cards);
}

sub crib_player_id {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_id($self);
}

sub crib_player_identifier {
	my ($self) = @_;
	$self->rounds->current_round->current_hands->crib_player;
}

sub crib_player_name {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_name($self);
}

sub crib_player_number {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_number($self);
}

sub crib_player_cards {
	my ($self, $player, $cards) = @_;
	$self->rounds->current_round->crib_player_cards($player, $cards);
}

sub cribbed_card {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->crib_player_card($player, $index);
}

sub cribbed_cards {
	my ($self, $player, @card_indexes) = @_;

	@card_indexes = sort { $b <=> $a } @card_indexes;
	$self->cribbed_card($player, $_) for @card_indexes;
	return 1;
}

sub force_play_card {
	my ($self, $card) = @_;
	$self->rounds->current_round->force_play_card($card);
}

sub play_card {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->play_player_card($player, $index);
}

sub get_card {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->get_player_card($player, $index);
}

sub current_play {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->play;
}

sub current_play_cards {
	my ($self) = @_;
	return [map { $_->card } @{$self->rounds->current_round->current_hands->play->cards}];
}

sub current_play_score {
	my ($self) = @_;
	$self->rounds->current_round->current_play_score();
}

sub last_play_score {
	my ($self) = @_;
	$self->rounds->current_round->last_play_score();
}

sub score {
	my ($self) = @_;
	$self->rounds->current_round->score;
}

sub cannot_play {
	my ($self, $player) = @_;
	$self->rounds->current_round->cannot_play_a_card($player);
}

sub player_cannot_play {
	my ($self, $player) = @_;
	return exists $self->rounds->current_round->current_hands->cannot_play->{$player};
}

sub no_player_can_play {
	my ($self) = @_;
	return scalar(keys(%{$self->rounds->current_round->current_hands->cannot_play})) == scalar(@{$self->players});
}

sub next_play {
	my ($self) = @_;
	$self->rounds->current_round->next_play($self);
}

sub end_play {
	my ($self) = @_;
	$self->rounds->current_round->end_play();
}

sub end_hands {
	my ($self) = @_;
	$self->rounds->current_round->end_hands($self);
}

sub shuffle {
	my ($self) = @_;
	$self->deck->shuffle();
}

sub get_round_id {
	my ($self) = @_;
	return $self->rounds->current_round->id;
}

sub set_round_id {
	my ($self, $id) = @_;
	$self->rounds->current_round->id($id);
	return $id;
}

sub get_hands_id {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->id;
}

sub set_hands_id {
	my ($self, $id) = @_;
	$self->rounds->current_round->current_hands->id($id);
	return $id;
}

sub get_play_id {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->play->id;
}

sub set_play_id {
	my ($self, $id) = @_;
	$self->rounds->current_round->current_hands->play->id($id);
	return $id;
}

sub get_crib_player_hand_id {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->get_crib_player_hand_id();
}

sub set_player_hand_id {
	my ($self, $player, $id) = @_;
	return $self->rounds->current_round->current_hands->set_player_hand_id($player, $id);
}

sub get_player_hand_id {
	my ($self, $player) = @_;
	return $self->rounds->current_round->current_hands->get_player_hand_id($player);
}

sub set_crib_complete {
	my ($self, $player, $id) = @_;
	return $self->rounds->current_round->current_hands->set_crib_complete($player, $id);
}

sub crib_complete {
	my ($self, $player) = @_;
	return $self->rounds->current_round->current_hands->crib_complete;
}

sub best_run_play {
	my ($self, $player) = @_;
	return $self->rounds->current_round->best_run_play($player);
}

sub total_player_score {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->rounds->current_round->score->$player;
}

sub set_crib_player {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	$self->rounds->current_round->current_hands->crib_player($player);
	if ($self->rounds->current_round->current_hands->play) {
		$self->rounds->current_round->current_hands->play->next_to_play($player);
	}
}

sub next_to_play_id {
	my ($self) = @_;
	$self->rounds->current_round->next_to_play_id($self);
}

sub next_to_play {
	my ($self) = @_;
	$self->rounds->current_round->next_to_play($self);
}

sub set_next_to_play {
	my ($self, $player) = @_;
	$self->rounds->current_round->current_hands->play->next_to_play($player);
}

sub hand_play_history {
	my ($self) = @_;
	$self->rounds->current_round->hand_play_history();
}

sub reset_hands {
	my ($self) = @_;
	$self->rounds->current_round->reset_hands();
}

sub last_round_hands {
	my ($self) = @_;
	return $self->rounds->current_round->history->[-2];
}

1;

__END__

=head1 NAME

Game::Cribbage::Board - top-level game orchestration object

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Board;

	my $board = Game::Cribbage::Board->new();
	$board->add_player(name => 'Alice');
	$board->add_player(name => 'Bob');
	$board->start_game();

	$board->set_crib_player('player1');
	$board->draw_hands();           # deal 6 cards each

	$board->cribbed_cards($player, 4, 5);  # discard indexes 4 and 5 to crib

	$board->play_card($player, 0);
	$board->cannot_play($player);
	$board->next_play($board);

	$board->end_hands();

=head1 DESCRIPTION

Provides the high-level API for a game of cribbage, delegating to
L<Game::Cribbage::Rounds>, L<Game::Cribbage::Round>,
L<Game::Cribbage::Hands>, and L<Game::Cribbage::Deck>.  The board object
is the primary interface used by the game UI layer (L<Game::Cribbage>) and
by external persistence layers via the id getter/setter methods.

=head1 PROPERTIES

=head2 players

Read/write arrayref of L<Game::Cribbage::Player> objects.

	$board->players;

=head2 deck

Read/write object property holding the active L<Game::Cribbage::Deck>.

	$board->deck;

=head2 rounds

Read/write object property holding the L<Game::Cribbage::Rounds> manager.

	$board->rounds;

=head1 FUNCTIONS

=head2 add_player

Creates a new L<Game::Cribbage::Player> from C<%player> args (must include
C<name>) and appends it to C<players>.  Returns C<$self>.

	$board->add_player(name => 'Alice');

=head2 add_player_if_not_exists

Finds an existing player by name; if not found, adds them.  Returns
C<($player, $existed)> where C<$existed> is 1 if already present or 0 if
newly created.

	my ($player, $existed) = $board->add_player_if_not_exists(name => 'Bob');

=head2 get_player

Returns the first L<Game::Cribbage::Player> whose name matches C<$name>,
or C<undef> if not found.

	my $player = $board->get_player(name => 'Alice');

=head2 build_deck

Constructs a new L<Game::Cribbage::Deck> and assigns it to C<deck>.

	$board->build_deck();

=head2 build_rounds

Constructs a new L<Game::Cribbage::Rounds> with the given round count.

	$board->build_rounds(1);

=head2 start_game

Initialises the deck and rounds if not already done, then advances to the
first (or next) round.  Accepts optional C<rounds> and C<id> args.

	$board->start_game();
	$board->start_game(rounds => 2, id => 99);

=head2 next_hands

Advances the current round to the next hands cycle with the given args.

	$board->next_hands(crib_player => 'player2');

=head2 force_to_crib

Forces a specific card (hashref C<{ suit =E<gt> ..., symbol =E<gt> ... }>) into the
crib player's crib, drawing it from the deck if available or generating it.

	$board->force_to_crib({ suit => 'H', symbol => '5' });

=head2 force_draw_card

Forces a specific card into C<$player>'s hand, drawing from the deck or
inserting at C<$index> if not in the deck.

	$board->force_draw_card($player, 0, { suit => 'H', symbol => '7' });

=head2 draw_hands

Deals 6 cards to each player from the deck.

	$board->draw_hands();

=head2 add_starter_card

Sets the starter card on the current hands cycle.

	$board->add_starter_card($player, $card);

=head2 get_hands

Returns the current L<Game::Cribbage::Hands> object.

	my $hands = $board->get_hands();

=head2 identify_worst_cards

Returns the two worst cards to discard from C<$player>'s hand.

	my ($cards, @indexes) = $board->identify_worst_cards($player);

=head2 validate_crib_cards

Validates (and if necessary replaces) the crib player's crib cards.

	$board->validate_crib_cards(\@cards);

=head2 crib_player_id

Returns the C<id> of the current crib player.

	my $id = $board->crib_player_id();

=head2 crib_player_identifier

Returns the player key string (e.g. C<'player1'>) of the crib holder.

	my $key = $board->crib_player_identifier();

=head2 crib_player_name

Returns the display name of the crib player.

	my $name = $board->crib_player_name();

=head2 crib_player_number

Returns the seat number of the crib player.

	my $num = $board->crib_player_number();

=head2 crib_player_cards

Discards multiple cards from C<$player>'s hand into the crib.

	$board->crib_player_cards($player, \@cards);

=head2 cribbed_card

Discards a single card at C<$index> from C<$player>'s hand into the crib.

	$board->cribbed_card($player, 2);

=head2 cribbed_cards

Discards multiple cards (by index) from C<$player>'s hand into the crib.
Indexes are processed in descending order to avoid splice shifting.

	$board->cribbed_cards($player, 4, 5);

=head2 force_play_card

Forces a card into play bypassing turn-order checks.

	$board->force_play_card($card);

=head2 play_card

Plays C<$index> for C<$player> with full validation.

	$board->play_card($player, 0);

=head2 get_card

Returns the card at C<$index> in C<$player>'s hand.

	my $card = $board->get_card($player, 0);

=head2 current_play

Returns the active L<Game::Cribbage::Play> object.

	my $play = $board->current_play();

=head2 current_play_cards

Returns an arrayref of the L<Game::Cribbage::Deck::Card> objects played so
far in the current play sequence.

	my $cards = $board->current_play_cards();

=head2 current_play_score

Returns the running total of the current play sequence.

	my $total = $board->current_play_score();

=head2 last_play_score

Returns the running total of the previous completed play sequence.

	my $total = $board->last_play_score();

=head2 score

Returns the L<Game::Cribbage::Round::Score> for the current round.

	my $score = $board->score();

=head2 cannot_play

Declares that C<$player> cannot play in the current sequence.

	$board->cannot_play($player);

=head2 player_cannot_play

Returns true if C<$player> has already declared cannot-play this sequence.

	$board->player_cannot_play('player1');

=head2 no_player_can_play

Returns true when all players have declared cannot-play.

	$board->no_player_can_play();

=head2 next_play

Advances to the next play sequence.

	$board->next_play($board);

=head2 end_play

Ends the current play sequence, awarding the go point.

	$board->end_play();

=head2 end_hands

Scores all hands, rotates the crib, and starts the next hands cycle.

	$board->end_hands();

=head2 shuffle

Shuffles the deck.

	$board->shuffle();

=head2 get_round_id / set_round_id

Get or set the current round's database identifier.

	$board->set_round_id(42);
	my $id = $board->get_round_id();

=head2 get_hands_id / set_hands_id

Get or set the current hands cycle's database identifier.

	$board->set_hands_id(7);
	my $id = $board->get_hands_id();

=head2 get_play_id / set_play_id

Get or set the current play sequence's database identifier.

	$board->set_play_id(3);
	my $id = $board->get_play_id();

=head2 get_crib_player_hand_id

Returns the database identifier of the crib player's hand.

	my $id = $board->get_crib_player_hand_id();

=head2 set_player_hand_id / get_player_hand_id

Set or get the database identifier for a specific player's hand.

	$board->set_player_hand_id('player1', 55);
	my $id = $board->get_player_hand_id('player1');

=head2 set_crib_complete

Marks the crib as complete.

	$board->set_crib_complete();

=head2 crib_complete

Returns the crib-complete flag.

	$board->crib_complete();

=head2 best_run_play

Returns the best card for C<$player> to play.

	my $card = $board->best_run_play('player2');

=head2 total_player_score

Returns the cumulative score for C<$player> in the current round.

	my $score = $board->total_player_score('player1');

=head2 set_crib_player

Sets the crib holder to C<$player> and aligns the play's next-to-play.

	$board->set_crib_player('player2');

=head2 next_to_play_id

Returns the id of the player whose turn it is to play.

	my $id = $board->next_to_play_id();

=head2 next_to_play

Returns the L<Game::Cribbage::Player> object whose turn it is.

	my $player = $board->next_to_play();

=head2 set_next_to_play

Sets the next-to-play player key on the active play.

	$board->set_next_to_play('player2');

=head2 hand_play_history

Returns a hashref with C<current_play> and C<used_count> keys summarising
the play history.

	my $hist = $board->hand_play_history();

=head2 reset_hands

Resets the current round's hands history and scores.

	$board->reset_hands();

=head2 last_round_hands

Returns the penultimate L<Game::Cribbage::Hands> object from the current
round's history (i.e. the hands cycle that preceded the current one).

	my $hands = $board->last_round_hands();

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
