package Game::Cribbage::Play;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Play::Card;
use Game::Cribbage::Play::Score;
use Game::Cribbage::Error;
use ntheory qw/forcomb vecsum/;

has [qw/id next_to_play/] => (
	is => 'rw',
);

has total => (
	is => 'rw',
	isa => Int,
	default => 0,
);

has [qw/cards scored/] => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

sub test_card {
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
}

sub card {
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
}

sub force_card {
	my ($self, $player, $card) = @_;

	for (@{$self->cards}) {
		if ($_->card->match($card)) {
			return 0;
		}
	}
	
	return $self->card($player, $card);
}


sub end_play {
	my ($self) = @_;

	return unless $self->cards->[0];

	my $score = Game::Cribbage::Play::Score->new(
		player => $self->cards->[-1]->player,
		card => $self->cards->[-1],
		go => 1
	);

	push @{$self->scored}, $score;

	return $score;
}

sub calculate_pair {
	my ($self, $score, $card) = @_;

	if ($self->cards->[-1] && $self->cards->[-1]->symbol eq $card->symbol) {
		if ($self->cards->[-2] && $self->cards->[-2]->symbol eq $card->symbol) {
			if ($self->cards->[-3] && $self->cards->[-3]->symbol eq $card->symbol) {
				$score->pair(3);
			} else {
				$score->pair(2);
			}
		} else {
			$score->pair(1);
		}
	}

	return 1;
}

sub calculate_run {
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
			$score->run($match);
			last;
		}
	}

	return 1;
}

sub calculate_total {
	my ($self, $cards, $set) = @_;

	my $total = 0;
	for (@{ $cards }) {
		$total += $_->value;
	}
	if ($set) {
		$self->total($total);
	}

	return $total;
}

sub calculate_hits {
	my ($self, $score, $total) = @_;
	if ($total == 15) {
		$score->fifteen(1);
	} elsif ($total == 31) {
		$score->pegged(1);
		$score->go(1);
	}

	return 1;
}

1;

__END__

=head1 NAME

Game::Cribbage::Play - a single play sequence (cards up to 31)

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Play;

	my $play = Game::Cribbage::Play->new(next_to_play => 'player1');

	# play a card and get back a Play::Score object
	my $score = $play->card('player1', $card);
	print $score->score;   # points earned

	# test without committing
	my $points = $play->test_card('player2', $card);

	# end the sequence and award the go point
	my $go_score = $play->end_play();

=head1 DESCRIPTION

Manages one play sequence in cribbage - the consecutive playing of cards
until the running total reaches 31 or no player can play.  Cards from all
players are added in turn-order; scoring (pairs, runs, fifteen, 31) is
evaluated after each card.

=head1 PROPERTIES

=head2 id

Read/write scalar property for a database or external identifier.

	$play->id;
	$play->id($id);

=head2 next_to_play

Read/write string property holding the player key (e.g. C<'player1'>) whose
turn it is to play.

	$play->next_to_play;
	$play->next_to_play('player2');

=head2 total

Read/write integer property holding the current running total of pip values.
Defaults to 0.

	$play->total;

=head2 cards

Read/write arrayref of L<Game::Cribbage::Play::Card> objects representing
the cards played so far in this sequence.

	$play->cards;

=head2 scored

Read/write arrayref of L<Game::Cribbage::Play::Score> objects accumulated
during this play sequence.

	$play->scored;

=head1 FUNCTIONS

=head2 test_card

Tests whether playing C<$card> for C<$player> would be legal and, if so,
returns the numeric score the play would earn.  Returns a
L<Game::Cribbage::Error> with C<go> set if the card would take the total
over 31.  Does B<not> commit the card to the play.

	my $result = $play->test_card($player, $card);
	if (ref $result) {
		# Error - cannot play
	} else {
		# $result is the score (0 or more)
	}

=head2 card

Plays C<$card> for C<$player>, updating the running total and checking for
pairs, runs, fifteen, and 31.  Returns a L<Game::Cribbage::Play::Score>
object on success, or a L<Game::Cribbage::Error> if the total would exceed 31.

	my $score = $play->card($player, $card);

=head2 force_card

Plays C<$card> for C<$player> unconditionally unless an identical card is
already in the play sequence (duplicate guard).  Returns 0 if the card was
already played, otherwise delegates to C<card>.

	$play->force_card($player, $card);

=head2 end_play

Awards the go point to the last player who played a card and records it in
C<scored>.  Returns the resulting L<Game::Cribbage::Play::Score>, or
C<undef> if no cards have been played.

	my $score = $play->end_play();

=head2 calculate_pair

Internal method. Inspects the tail of C<cards> to detect pairs, three of a
kind, or four of a kind, and sets C<pair> on C<$score>.

	$play->calculate_pair($score, $card);

=head2 calculate_run

Internal method. Inspects the last N cards to detect runs of three or more
consecutive run-values, and sets C<run> on C<$score>.

	$play->calculate_run($score, $card);

=head2 calculate_total

Sums the pip values of C<$cards> and optionally stores the result in
C<total> when C<$set> is true.  Returns the computed total.

	my $total = $play->calculate_total(\@cards, 1);

=head2 calculate_hits

Sets C<fifteen> or C<pegged>/C<go> on C<$score> when C<$total> equals
15 or 31 respectively.

	$play->calculate_hits($score, $total);

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
