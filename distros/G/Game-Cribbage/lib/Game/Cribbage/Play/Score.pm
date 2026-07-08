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

__END__

=head1 NAME

Game::Cribbage::Play::Score - score object for a single card play

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Play::Score;

	my $score = Game::Cribbage::Play::Score->new(
		player => 'player1',
		card   => $card,
	);

	# after calculate_pair / calculate_run / calculate_hits are called:
	print $score->score;        # total points earned by this play
	print $score->pair;         # 1=pair, 2=three-of-a-kind, 3=four-of-a-kind
	print $score->run;          # 1=run-of-3, 2=run-of-4, 3=run-of-5 ...
	print $score->fifteen;      # 1 if running total is exactly 15
	print $score->pegged;       # 1 if running total is exactly 31

=head1 PROPERTIES

=head2 scores

Readonly hashref holding the point values for each scoring category.
Built automatically; do not set manually.

	$score->scores;
	# {
	#   run     => [3, 4, 5, 6, 7],   # indexed by (run_length - 3)
	#   pair    => [2, 6, 12],         # indexed by (matches - 1)
	#   fifteen => 2,
	#   go      => 1,
	#   pegged  => 1,
	#   flipped => 1,
	# }

=head2 total_score

Read/write integer property caching the last computed total score.
Populated by C<score()>.

	$score->total_score;

=head2 pair

Read/write integer encoding the pair/prials result: 1 = one pair,
2 = three of a kind, 3 = four of a kind.  C<undef>/0 means no pair.

	$score->pair;

=head2 run

Read/write integer encoding a run: 1 = run of three, 2 = run of four,
3 = run of five, etc.  C<undef>/0 means no run.

	$score->run;

=head2 fifteen

Read/write integer flag; set to 1 when the running total equals exactly 15.

	$score->fifteen;

=head2 pegged

Read/write integer flag; set to 1 when the running total equals exactly 31.

	$score->pegged;

=head2 go

Read/write integer flag; set to 1 on a go (31 reached or last card played).

	$score->go;

=head2 flipped

Read/write integer flag; set to 1 when the starter card is a Jack (nobs).

	$score->flipped;

=head2 player

Readonly property holding the player string or object that earned this score.

	$score->player;

=head2 card

Readonly property holding the L<Game::Cribbage::Deck::Card> that triggered
this score.

	$score->card;

=head1 FUNCTIONS

=head2 score

Computes and returns the total points earned by this play action, summing all
active scoring categories according to the C<scores> table.  Also stores the
result in C<total_score>.

	my $points = $score->score;

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
