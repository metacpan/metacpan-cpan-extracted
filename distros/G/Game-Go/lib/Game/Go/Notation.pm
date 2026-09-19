package Game::Go::Notation;

use 5.010;
use strict;
use warnings;

use Game::Go::Rules;

our $VERSION = '0.01';

our @HUMAN_COLS;
BEGIN {
	@HUMAN_COLS = grep { $_ ne 'I' } ('A' .. 'Z');
}

our %HUMAN_INDEX;
BEGIN {
	$HUMAN_INDEX{ $HUMAN_COLS[$_] } = $_ for 0 .. $#HUMAN_COLS;
}

sub col_letter { $HUMAN_COLS[ $_[-1] ] }

sub letter_col {
	my $letter = uc($_[-1] // '');
	return exists $HUMAN_INDEX{$letter} ? $HUMAN_INDEX{$letter} : undef;
}

sub to_human {
	my ($size, $col, $row) = @_[-3, -2, -1];
	return undef unless defined $col && defined $row;
	return undef if $col < 0 || $row < 0 || $col >= $size || $row >= $size;
	return $HUMAN_COLS[$col] . ($size - $row);
}

sub from_human {
	my ($size, $name) = @_[-2, -1];
	return () unless defined $name;
	my ($letter, $number) = $name =~ /\A\s*([A-Za-z])\s*([0-9]+)\s*\z/;
	return () unless defined $letter;

	my $col = letter_col($letter);
	return () unless defined $col;
	return () if $col >= $size;
	return () if $number < 1 || $number > $size;

	return ($col, $size - $number);
}

sub to_sgf {
	my ($size, $col, $row) = @_[-3, -2, -1];
	return undef unless defined $col && defined $row;
	return undef if $col < 0 || $row < 0 || $col >= $size || $row >= $size;
	return chr(ord('a') + $col) . chr(ord('a') + $row);
}

sub from_sgf {
	my ($size, $text) = @_[-2, -1];
	return () unless defined $text;
	return () unless $text =~ /\A([a-z])([a-z])\z/;

	my ($col, $row) = (ord($1) - ord('a'), ord($2) - ord('a'));
	return () if $col >= $size || $row >= $size;
	return ($col, $row);
}

sub transcript {
	my ($game) = @_;
	my @out;
	for my $e (@{ $game->log }) {
		my $who = Game::Go::Rules::from_letter($e->{actor}) or next;
		my $name = Game::Go::Rules::colour_name($who);
		if ($e->{kind} eq 'pass') { push @out, "$name pass"; next }
		next unless $e->{kind} eq 'play' || $e->{kind} eq 'handicap';
		my ($col, $row) = $game->col_row($e->{payload}{pt});
		push @out, "$name " . to_human($game->size, $col, $row);
	}
	return \@out;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Notation - the two coordinate alphabets, and the gap between them

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Go::Notation;

    Game::Go::Notation::to_human(19, 3, 15);    # 'D4'
    Game::Go::Notation::from_human(19, 'D4');   # (3, 15)

    Game::Go::Notation::to_sgf(19, 3, 15);      # 'dp'
    Game::Go::Notation::from_sgf(19, 'dp');     # (3, 15)

=head1 DESCRIPTION

B<Two alphabets for one board, and they are not the same alphabet.>

=head2 Human notation

What a board edge, a book, a tournament sheet and this distribution's terminal
print. Columns are C<A> to C<T> with B<I omitted>:

    A B C D E F G H J K L M N O P Q R S T

and rows are numbered B<from the bottom>, so C<D4> is four up from the bottom
edge.

C<I> is skipped because on a printed board it is indistinguishable from C<J> and
from the digit 1, and every source in the game skips it.

=head2 SGF notation

Two lowercase letters, skipping B<nothing>, with the row counted from the
B<top>. From the SGF FF[4] Go specification:

    In Go the Stone becomes Point and the Move and Point type are the same: two
    lowercase letters.

    The first letter designates the column (left to right), the second the row
    (top to bottom). The upper left part of the board is used for smaller
    boards, e.g. letters "a"-"m" for 13*13.

=head2 The trap

On a 19x19 board:

                   human    SGF     column index
     top left       A19      aa          0
     bottom left    A1       as          0
     the trap       J10      --          8
     the trap       --       jj          9

C<J10> and C<jj> are B<one column apart>. Both read as "the tenth column, row
ten" to somebody not paying attention, and they are different points. That is a
silent off-by-one over a third of the board.

So B<there is no function here that converts between the two alphabets>.
Everything goes through a column and row pair, where the difference has to be
dealt with rather than assumed away.

=head1 FUNCTIONS

Every one takes the board size first, because neither alphabet means anything
without it: the row origin depends on it in human notation, and the bounds
depend on it in both.

=head2 to_human, from_human

    to_human($size, $col, $row)     # 'D4', or undef off the board
    from_human($size, 'D4')         # ($col, $row), or the empty list

=head2 to_sgf, from_sgf

    to_sgf($size, $col, $row)       # 'dp', or undef off the board
    from_sgf($size, 'dp')           # ($col, $row), or the empty list

C<from_sgf> refuses the empty string and C<tt>, which are B<passes> rather than
points. L<Game::Go::SGF> is the thing that knows a pass is a move.

=head2 col_letter, letter_col

One human column letter to and from its index, C<I> skipped.

=head2 transcript

A game's moves as human coordinates, one per move, passes included.

For a log page and for a person reading a diff, B<never for a replay>: a replay
hands each event back to the method that made it, and that takes a point.

=head1 SEE ALSO

L<Game::Go::SGF>, L<Game::Go>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
