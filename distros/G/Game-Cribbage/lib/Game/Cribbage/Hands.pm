package Game::Cribbage::Hands;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Player::Hand;
use Game::Cribbage::Play;
use Game::Cribbage::Error;

has id => (
	is => 'rw',
	isa => Int
);

has number => (
	is => 'ro',
	isa => Int
);

has crib_player => (
	is => 'rw',
	isa => Str
);

has crib_complete => (
	is => 'rw',
	isa => Bool
);

has [qw/starter play player1 player2 player3 player4/] => (
	is => 'rw',
	isa => Object
);

has cannot_play => (
	is => 'rw',
	isa => HashRef,
	default => {}
);

has play_history => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);


sub BUILD {
	my ($self, $options) = @_;
	$self->crib_player('player1') if !$self->crib_player;
	return $self;
}

sub init {
	my ($self, $game) = @_;
	for (@{$game->players}) {
		my $player = $_->player;
		$self->$player(Game::Cribbage::Player::Hand->new(
			player => $player
		));
	}
	$self->new_play();
	$self;
}

sub add_starter_card {
	my ($self, $player, $card) = @_;
	$self->starter($card);
	
	my $scored = 0;
	if ($card->symbol =~ m/^J$/) {
		$scored = Game::Cribbage::Play::Score->new(
			player => $player,
			card => $card,
			flipped => 1
		);
		push @{$self->play->scored}, $scored;
	}

	for (qw/player1 player2 player3 player4/) {
		if ($self->$_) {
			$self->$_->starter($card);
		}
	}

	return $scored;
}

sub find_player_card {
	my ($self, $card) = @_;
	my $player;
	for my $p (qw/player1 player2 player3 player4/) {
		if ($self->$p) {
			for (@{$self->$p->cards}) {
				if ($_->match($card)) {
					$card = $_;
					$player = $p;			
					last;
				}
			}
		}
	}
	return ($card, $player);
}

sub force_play_card {
	my ($self, $card) = @_;
	my $player;
	($card, $player) = $self->find_player_card($card);
	$card->used(1);
	my $scored = $self->play->force_card($player, $card);
	$self->set_next_to_play();
	return ($scored, $player);
}

sub play_card {
	my ($self, $player, $card_index) = @_;
	my $hand = ref $player ? $player->player : $player;
	if ($self->play->next_to_play ne $hand) {
		return Game::Cribbage::Error->new( message => 'It is not the turn of ' . $hand );
	}
	my $card = ref $card_index ? $card_index : $self->$hand->get($card_index);
	if (!$card || $card->used) {
		die 'CARD HAS ALREADY BEEN PLAYED IN THIS ROUND';
	}

	my $total = $self->play->total;
	if ($card->value + $total > 31) {
		return Game::Cribbage::Error->new( over => 1, message => 'Playing this card will make the score greater than 31');
	}
	$card->used(1);
	my $scored = $self->play->card($player, $card);
	$self->set_next_to_play();
	return $scored;
}

sub cannot_play_a_card {
	my ($self, $player) = @_;
	
	my $hand = ref $player ? $player->player : $player;
	if ($self->play->next_to_play ne $hand) {
		return Game::Cribbage::Error->new( message => 'It is not the turn of ' . $hand );
	}

	my $current_total = $self->play->total;

	my @can_be_played;
	for (@{$self->$hand->cards}) {
		next if $_->used;
		if ( ($current_total + $_->value) < 31 ) {
			push @can_be_played, $_;
		}
	}

	return \@can_be_played if scalar @can_be_played;

	$self->set_next_to_play();

	$self->cannot_play->{$hand} = 1;

	return 1;
}

sub set_next_to_play {
	my ($self) = @_;
	my $next = $self->parse_next_to_play($self->play->next_to_play);
	$self->play->next_to_play($next);
}

sub parse_next_to_play {
	my ($self, $player_string) = @_;
	$player_string =~ m/player(\d)/;
	my $index = $1;
	$index++;
	my $next = 'player' . $index;
	if ($self->$next) {
		return $next;
	} else {
		return 'player1';
	}
}

sub set_player_hand_id {
	my ($self, $player, $id) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->$hand->id($id);
	return $id;
}

sub get_player_hand_id {
	my ($self, $player) = @_;
	my $hand = ref $player ? $player->player : $player;
	return $self->$hand->id;
}

sub get_crib_player_hand_id {
	my ($self) = @_;
	my $hand = $self->crib_player;
	return $self->$hand->id;
}

sub get_card {
	my ($self, $player, $card_index) = @_;
	my $hand = ref $player ? $player->player : $player;
	my $card = $self->$hand->get($card_index);
	return $card;
}

sub play_score {
	my ($self) = @_;
	return $self->play->total || 0;
}

sub last_play_score {
	my ($self) = @_;
	my $prev = $self->play_history->[-2];
	return $prev ? $prev->total : 'This is the first play';
}

sub new_play {
	my ($self) = @_;
	my $next_to_play = $self->crib_player;
	if ($self->play) {
		$next_to_play = $self->parse_next_to_play(ref $self->play->cards->[-1]->player ? $self->play->cards->[-1]->player->player : $self->play->cards->[-1]->player);
	}
	$self->play(Game::Cribbage::Play->new(
		next_to_play => $next_to_play
	));
	push @{$self->play_history}, $self->play;
}

sub next_play {
	my ($self, $game) = @_;

	# first check whether any players can play on the current 'play'
	# if they can they must use those cards first.
	my $current_total = $self->play->total;

	my $available_cards = 0;
	for my $hand (qw/player1 player2 player3 player4/) {
		if ($self->$hand) {
			my @can_be_played;
			for (@{$self->$hand->cards}) {
				next if $_->used;
				$available_cards = 1;
				if ( $current_total + $_->value < 31 ) {
					push @can_be_played, $_;
				}
			}
			if (scalar @can_be_played) {
				return Game::Cribbage::Error->new(
					message => 'Cards can be played',
					player => $hand,
					cards => \@can_be_played
				);
			}
		}
	}

	$self->cannot_play({});
	# now we know cards can't be played confirm we have cards left to Play another 'play'.
	if (!$available_cards) { 
		$game->end_hands(); 
		return undef;
	}
	
	my $scored;
	if (!$self->play->scored->[-1] || !$self->play->scored->[-1]->go) {
		$scored = $self->play->end_play();
	}

	$self->new_play();

	return $scored;
}

sub end_play {
	my ($self) = @_;

	my $scored;

	if (!$self->play->scored->[-1] || !$self->play->scored->[-1]->go) {
		$scored = $self->play->end_play();
	}

	$self->play(undef);

	return $scored;
}

sub score_hands {
	my ($self) = @_;
	my %scored;
	for (qw/player1 player2 player3 player4/) {
		$scored{$_} = $self->$_->calculate_score()
			if ($self->$_);
	}
	return \%scored;
}

sub card_exists {
	my ($self, $player, $card) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->$player->card_exists($card);
}

sub set_crib_complete {
	my ($self) = @_;
	$self->crib_complete(1);
}

sub best_run_play {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->$player->best_run_play($self->play);
}

sub next_to_play_id {
	my ($self, $game) = @_;
	my $hand = $self->play->next_to_play;
	return $hand;
}

1;

__END__

=head1 NAME

Game::Cribbage::Hands - a single hands cycle within a round

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Hands;

	my $hands = Game::Cribbage::Hands->new(
		crib_player => 'player1',
		number      => 1,
	)->init($game);

	# deal, then discard to crib
	$hands->player1->add($card);
	$hands->player1->discard(0, $hands->player1);

	# play phase
	my $score = $hands->play_card('player1', 0);
	$hands->cannot_play_a_card('player2');
	$hands->next_play($game);

	# scoring phase
	$hands->add_starter_card('player1', $starter);
	my $scored = $hands->score_hands();

=head1 DESCRIPTION

Represents one complete hands cycle (deal, crib discard, play phase, hand
scoring) within a L<Game::Cribbage::Round>.  Created via C<next_hands> on
the Round and initialised with C<init>, which creates per-player
L<Game::Cribbage::Player::Hand> slots and the first
L<Game::Cribbage::Play>.

=head1 PROPERTIES

=head2 id

Read/write integer property for a database or external identifier.

	$hands->id;
	$hands->id($id);

=head2 number

Readonly integer property indicating which hands cycle this is within the
round.

	$hands->number;

=head2 crib_player

Read/write string property holding the player key for the current crib
holder (e.g. C<'player1'>).

	$hands->crib_player;
	$hands->crib_player('player2');

=head2 crib_complete

Read/write boolean property; set to 1 when both players have discarded their
crib cards.

	$hands->crib_complete;

=head2 starter

Read/write object property holding the starter L<Game::Cribbage::Deck::Card>.

	$hands->starter;

=head2 play

Read/write object property holding the current L<Game::Cribbage::Play>
sequence.

	$hands->play;

=head2 player1 / player2 / player3 / player4

Read/write object properties each holding a
L<Game::Cribbage::Player::Hand> for the corresponding player slot.

	$hands->player1;
	$hands->player2;

=head2 cannot_play

Read/write hashref recording which players have declared they cannot play
a card in the current play sequence.  Keys are player strings
(C<'player1'> etc.), values are 1.  Reset to C<{}> at the start of each
new play.

	$hands->cannot_play;

=head2 play_history

Read/write arrayref of all L<Game::Cribbage::Play> objects created during
this hands cycle, in order.  The last element is always the current play.

	$hands->play_history;

=head1 FUNCTIONS

=head2 init

Initialises the hands cycle for C<$game>: creates a
L<Game::Cribbage::Player::Hand> for each player and starts the first play.
Returns C<$self>.

	my $hands = Game::Cribbage::Hands->new(...)->init($game);

=head2 add_starter_card

Sets the starter card, distributes it to all player hands, and awards 1
point for nobs if the starter is a Jack.  Returns a
L<Game::Cribbage::Play::Score> if nobs scored, otherwise 0.

	my $score = $hands->add_starter_card($player, $card);

=head2 find_player_card

Searches all player hands for a card matching C<$card> and returns
C<($card, $player_string)>.

	my ($card, $player) = $hands->find_player_card($lookup_card);

=head2 force_play_card

Marks the matching card as used and plays it via the current play, bypassing
turn-order checks.  Returns C<($score, $player_string)>.

	my ($score, $player) = $hands->force_play_card($card);

=head2 play_card

Plays C<$card_index> (integer or card object) for C<$player>, enforcing
turn order and the 31-point limit.  Returns a
L<Game::Cribbage::Play::Score> on success or a L<Game::Cribbage::Error>.

	my $score = $hands->play_card($player, $card_index);

=head2 cannot_play_a_card

Declares that C<$player> cannot play without exceeding 31.  If cards
remain that could be played without exceeding 31, returns an arrayref of
those cards instead.  On success returns 1 and advances the turn.

	my $result = $hands->cannot_play_a_card('player1');

=head2 set_next_to_play

Advances C<next_to_play> on the current play to the next player, wrapping
around.

	$hands->set_next_to_play();

=head2 parse_next_to_play

Returns the player key that follows C<$player_string> in turn order,
wrapping from the last player back to C<'player1'>.

	my $next = $hands->parse_next_to_play('player2');

=head2 set_player_hand_id

Sets the C<id> on the named player's hand.

	$hands->set_player_hand_id('player1', 42);

=head2 get_player_hand_id

Returns the C<id> of the named player's hand.

	my $id = $hands->get_player_hand_id('player1');

=head2 get_crib_player_hand_id

Returns the C<id> of the crib player's hand.

	my $id = $hands->get_crib_player_hand_id();

=head2 get_card

Returns the card at C<$card_index> in the named player's hand.

	my $card = $hands->get_card($player, $card_index);

=head2 play_score

Returns the current play's running total, or 0 if no play is active.

	my $total = $hands->play_score();

=head2 last_play_score

Returns the running total of the previous completed play, or the string
C<'This is the first play'> if only one play has occurred.

	my $score = $hands->last_play_score();

=head2 new_play

Creates a new L<Game::Cribbage::Play> and appends it to C<play_history>.
The next-to-play is inferred from the last card played in the previous play.

	$hands->new_play();

=head2 next_play

Determines whether a new play can start or all hands are exhausted.  If any
player still has a playable card, returns a L<Game::Cribbage::Error>
listing those cards.  If no cards remain at all, calls C<end_hands> on
C<$game> and returns C<undef>.  Otherwise, ends the current play (awarding
the go point) and starts a new one.

	my $result = $hands->next_play($game);

=head2 end_play

Ends the current play (awarding the go point unless already awarded) and
sets C<play> to C<undef>.  Returns the L<Game::Cribbage::Play::Score> for
the go, or C<undef>.

	my $score = $hands->end_play();

=head2 score_hands

Calculates the score for every player hand (and crib) by calling
C<calculate_score> on each.  Returns a hashref keyed by player string.

	my $scored = $hands->score_hands();
	# { player1 => 12, player2 => 8 }

=head2 card_exists

Returns 1 if C<$card> exists in C<$player>'s hand (cards or crib).

	$hands->card_exists($player, $card);

=head2 set_crib_complete

Marks the crib as complete by setting C<crib_complete> to 1.

	$hands->set_crib_complete();

=head2 best_run_play

Returns the best card for C<$player> to play next, or a
L<Game::Cribbage::Error> with C<go> set if no valid card exists.

	my $card = $hands->best_run_play('player2');

=head2 next_to_play_id

Returns the player key string currently set as C<next_to_play> on the
active play.

	my $player_key = $hands->next_to_play_id();

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
