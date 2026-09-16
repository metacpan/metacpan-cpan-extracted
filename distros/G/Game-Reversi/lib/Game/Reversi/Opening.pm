package Game::Reversi::Opening;

use strict;
use warnings;

use Game::Reversi::Board;
use Game::Reversi::Move;
use Game::Reversi::Error;

our $VERSION = '0.01';

our @CENTRE;
BEGIN {
	@CENTRE = map { Game::Reversi::Board->square_of(@$_) }
	          ([ 'd', 5 ], [ 'e', 5 ], [ 'd', 4 ], [ 'e', 4 ]);
}

use constant PLIES => 4;

our %VARIANT = (
	historic => 'the players place the first four discs themselves',
	othello  => 'the four centre discs are already placed, on the diagonals',
);

sub variants  { return sort keys %VARIANT }
sub describes { my ($class, $v) = @_; return $VARIANT{ $v // '' } }
sub centre    { return @CENTRE }

sub is_centre {
	my ($class, $square) = @_;
	return 0 unless defined $square;
	return scalar grep { $_ == $square } @CENTRE;
}

sub board_for {
	my ($class, $variant) = @_;
	$variant = 'historic' unless defined $variant;
	die "Game::Reversi::Opening: there is no variant '$variant'"
		unless exists $VARIANT{$variant};

	my $board = Game::Reversi::Board->empty;
	return $board if $variant eq 'historic';

	my $at = sub { Game::Reversi::Board->square_of(@_) };
	$board->[ $at->('e', 4) ] = 'b';
	$board->[ $at->('d', 5) ] = 'b';
	$board->[ $at->('d', 4) ] = 'w';
	$board->[ $at->('e', 5) ] = 'w';
	return $board;
}

sub first { return 'b' }

sub in_opening {
	my ($class, $board) = @_;
	return (grep { !defined $board->[$_] } @CENTRE) ? 1 : 0;
}

sub plies_left {
	my ($class, $board) = @_;
	return scalar grep { !defined $board->[$_] } @CENTRE;
}

sub legal {
	my ($class, $board, $colour) = @_;
	return () unless $class->in_opening($board);
	return map { Game::Reversi::Move->place($_, $colour) }
	       grep { !defined $board->[$_] } @CENTRE;
}

sub check {
	my ($class, $board, $square) = @_;
	return Game::Reversi::Error->throw('not_centre',
		legal => [ grep { !defined $board->[$_] } @CENTRE ])
		unless $class->is_centre($square);
	return Game::Reversi::Error->throw('square_taken',
		legal => [ grep { !defined $board->[$_] } @CENTRE ])
		if defined $board->[$square];
	return undef;
}

sub apply {
	my ($class, $board, $square, $colour) = @_;
	my $error = $class->check($board, $square);
	die 'Game::Reversi::Opening: ' . $error->stringify if $error;

	my $after = [ @$board ];
	$after->[$square] = $colour;
	return $after;
}

1;

__END__

=head1 NAME

Game::Reversi::Opening - the four discs the players place themselves

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $board = Game::Reversi::Opening->board_for('historic');   # empty

    while (Game::Reversi::Opening->in_opening($board)) {
        my @places = Game::Reversi::Opening->legal($board, $colour);
        $board = Game::Reversi::Opening->apply($board, $square, $colour);
        $colour = Game::Reversi::Board->other($colour);
    }

=head1 DESCRIPTION

Reversi starts with an empty board. The players place the first four discs
themselves, alternately, on the four centre squares, capturing nothing. Othello
starts with those four discs already down. That is the whole difference between
the two games, and it is why this distribution can be called Reversi.

Wikipedia:

=over 4

The historical version of reversi starts with an empty board, and the first two
moves made by each player are in the four central squares of the board. The
players place their disks alternately with their colors facing up and no
captures are made. A player may choose to not play both pieces on the same
diagonal, different from the standard I<Othello> opening.

=back

=head2 Twenty four sequences, six positions, two games

Every order of the four squares is legal, so there are C<4! = 24> placement
sequences. A position is fixed by which pair Black ends up with, and each pair
is reachable four ways, so there are six distinct positions. Up to rotation and
reflection there are two: the B<diagonal> opening, of which the Othello position
is one case, and the B<parallel> opening.

Opening theory covers exactly one of those six. The parallel openings break the
symmetry from the first move and have never had a book written about them.

=head2 The opening restriction does real work

After only two placements the board can already hold a legal capture by the
ordinary rules. Black on C<d5> and White on C<e5> means a disc at C<f5> would
outflank C<e5> and turn it.

The rule says no captures are made during the opening, so that play must be
refused even though L<Game::Reversi::Board> would call it legal. An
implementation that asked the board for its legal moves during the opening would
offer it, and would be wrong in a way that still looks like a working game.

=head2 Variants

C<historic> is the default and is the game above. C<othello> is the 1971 fixed
start, dark on C<e4> and C<d5>. It exists for two reasons, and neither is
demand: it is one of the six positions the historic opening reaches anyway, and
it is the position every published transcript and every published move count
starts from, so it is the only external oracle this distribution has.

=head1 METHODS

=head2 centre

The four centre squares.

=head2 is_centre

Whether a square is one of them.

=head2 variants, describes

The variant names, and a sentence about one.

=head2 board_for

The starting board for a variant. Dies on a name it does not know.

=head2 first

The colour that moves first, which is always Black.

=head2 in_opening

Whether discs are still being placed. Since the centre fills up and never
empties, this is the same question as whether a centre square is free, and it
answers itself correctly for the C<othello> variant.

=head2 plies_left

How many placements remain.

=head2 legal

The placements open to a colour, as L<Game::Reversi::Move> objects with a
C<phase> of C<place>. The empty centre squares and nothing else.

=head2 check

The L<Game::Reversi::Error> a placement would be refused with, or C<undef>.

=head2 apply

A new board with the disc placed and nothing turned. Dies on a placement that
L</check> would refuse, because by then it is programmer error.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
