package Game::Reversi::Notation;

use strict;
use warnings;

use Game::Reversi::Board;

our $VERSION = '0.01';

my $PASS = '--';

sub square_to_text {
	my ($class, $square) = @_;
	return Game::Reversi::Board->name_of($square);
}

sub text_to_square {
	my ($class, $text) = @_;
	return undef unless defined $text;
	my ($file, $rank) = lc($text) =~ /\A\s*([a-h])([1-8])\s*\z/;
	return undef unless defined $file;
	return Game::Reversi::Board->square_of($file, $rank);
}

sub parse {
	my ($class, $text) = @_;
	return [] unless defined $text && length $text;

	my @squares;
	my $rest = lc $text;
	while (length $rest) {
		if ($rest =~ s/\A[\s,;.\-]+//) {
			next;
		}
		if ($rest =~ s/\A(pass|pa)\b//) {
			next;
		}
		if ($rest =~ s/\A([a-h])([1-8])//) {
			push @squares, Game::Reversi::Board->square_of($1, $2);
			next;
		}
		die "Game::Reversi::Notation: cannot read '$rest' as a transcript";
	}
	return \@squares;
}

sub render {
	my ($class, $squares) = @_;
	return join '', map { Game::Reversi::Board->name_of($_) } @$squares;
}

sub render_with_passes {
	my ($class, $steps) = @_;
	return join '', map {
		($PASS x $_->{passes}) . Game::Reversi::Board->name_of($_->{square})
	} @$steps;
}

sub walk {
	my ($class, $board, $colour, $squares) = @_;
	my $B = 'Game::Reversi::Board';
	my @steps;
	my $now = [ @$board ];

	for my $square (@$squares) {
		my $passes = 0;
		while (!$B->has_move($now, $colour)) {
			my $them = $B->other($colour);
			die 'Game::Reversi::Notation: the transcript continues past the end '
				. 'of the game, where neither side can move'
				unless $B->has_move($now, $them);
			$colour = $them;
			$passes++;
		}

		my @flips = $B->flips_for($now, $square, $colour);
		die "Game::Reversi::Notation: $colour cannot play "
			. ($B->name_of($square) // '?') . ' in this position'
			unless @flips;

		$now = $B->apply($now, $square, $colour);
		push @steps, {
			colour => $colour,
			square => $square,
			flips  => [ @flips ],
			passes => $passes,
			board  => $now,
		};
		$colour = $B->other($colour);
	}

	return \@steps;
}

sub board_to_text {
	my ($class, $board) = @_;
	my @lines;
	for my $row (0 .. 7) {
		push @lines, join '', map { $board->[ $row * 8 + $_ ] // '.' } 0 .. 7;
	}
	return join "\n", @lines;
}

sub text_to_board {
	my ($class, $text) = @_;
	my @lines = grep { length } map { my $l = $_; $l =~ s/\s+//g; $l }
	            split /\n/, ($text // '');
	die 'Game::Reversi::Notation: a board is eight lines of eight squares'
		unless @lines == 8;

	my $board = Game::Reversi::Board->empty;
	for my $row (0 .. 7) {
		my @cells = split //, $lines[$row];
		die 'Game::Reversi::Notation: a board is eight lines of eight squares'
			unless @cells == 8;
		for my $col (0 .. 7) {
			my $c = $cells[$col];
			next if $c eq '.';
			die "Game::Reversi::Notation: '$c' is not a disc"
				unless $c eq 'b' || $c eq 'w';
			$board->[ $row * 8 + $col ] = $c;
		}
	}
	return $board;
}

1;

__END__

=head1 NAME

Game::Reversi::Notation - squares, boards and transcripts as text

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    Game::Reversi::Notation->text_to_square('f5');       # 29
    Game::Reversi::Notation->square_to_text(29);         # 'f5'

    my $squares = Game::Reversi::Notation->parse('f5d6c3d3c4');
    my $steps   = Game::Reversi::Notation->walk($board, 'b', $squares);

=head1 DESCRIPTION

=head2 What is standard and what is ours

B<Standard.> The square. Files C<a> to C<h>, ranks C<1> to C<8>, so C<f5>. And
the transcript: those squares concatenated with no separator, C<f5d6c3d3c4>,
which is the form published games and WTHOR records use. This distribution
adopts both rather than inventing its own, so that a transcript from anywhere
can be read here.

B<Ours.> How a pass is written, C<-->, and only because something has to be
written when a pass must be shown. Sources differ and most transcripts omit
passes entirely, since a pass is forced and can be recovered from the position.

=head2 Passes are recomputed, never trusted

L</parse> discards any pass written into a transcript and L</walk> puts the
passes back by asking the position. A written pass that disagreed with the rules
would otherwise be believed.

This matters more than it sounds. A transcript carries squares and no colours,
so which player made each move depends entirely on how many turns were forfeited
earlier. A reader that assumes the colours alternate will misattribute every
move after the first pass, and will do it silently: the moves stay legal-looking
and the game still replays, but to the wrong position and the wrong score.

=head1 METHODS

=head2 square_to_text, text_to_square

One square, both ways. C<text_to_square> returns C<undef> for anything that is
not a square, so a caller can tell a bad square from square 0.

=head2 parse

The squares of a transcript, in order. Accepts the concatenated standard form
and tolerates separators. Written passes are accepted and discarded. Dies on
anything it cannot read.

=head2 render

Squares back to a concatenated transcript.

=head2 render_with_passes

Steps from L</walk> rendered with their passes shown.

=head2 walk

Replays squares over a board, inserting the forced passes, and returns a step
per move: C<colour>, C<square>, C<flips>, C<passes> and the resulting C<board>.
Dies on a square that is not legal for whoever is to move, and on a transcript
that runs past the end of the game.

=head2 board_to_text, text_to_board

A board as eight lines of eight characters, C<.> for empty, and back. The grid
only, with no coordinates, so that the two are exact inverses.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
