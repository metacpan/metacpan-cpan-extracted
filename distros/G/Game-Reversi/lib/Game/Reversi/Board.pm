package Game::Reversi::Board;

use strict;
use warnings;

our $VERSION = '0.01';

use constant SIZE  => 8;
use constant CELLS => 64;

my @RAY = ([-1,-1], [-1,0], [-1,1],
           [ 0,-1],         [ 0,1],
           [ 1,-1], [ 1,0], [ 1,1]);

sub rays { return map { [ @$_ ] } @RAY }

sub empty { return [ (undef) x CELLS ] }

sub clone { my ($class, $board) = @_; return [ @$board ] }

sub other { my ($class, $colour) = @_; return $colour eq 'b' ? 'w' : 'b' }

sub square_of {
	my ($class, $file, $rank) = @_;
	return undef unless defined $file && defined $rank;
	return undef unless $file =~ /\A[a-h]\z/ && $rank =~ /\A[1-8]\z/;
	return (8 - $rank) * SIZE + (ord($file) - ord('a'));
}

sub name_of {
	my ($class, $square) = @_;
	return undef unless defined $square && $square =~ /\A\d+\z/
		&& $square >= 0 && $square < CELLS;
	my $row = int($square / SIZE);
	my $col = $square % SIZE;
	return chr(ord('a') + $col) . (8 - $row);
}

sub flips_for {
	my ($class, $board, $square, $colour) = @_;
	return () unless defined $square && $square >= 0 && $square < CELLS;
	return () if defined $board->[$square];

	my $them = $colour eq 'b' ? 'w' : 'b';
	my $row  = int($square / SIZE);
	my $col  = $square % SIZE;

	my @flips;
	for my $ray (@RAY) {
		my ($dr, $dc) = @$ray;
		my ($r, $c) = ($row + $dr, $col + $dc);
		my @run;

		while ($r >= 0 && $r < SIZE && $c >= 0 && $c < SIZE) {
			my $cell = $board->[ $r * SIZE + $c ];
			last unless defined $cell && $cell eq $them;
			push @run, $r * SIZE + $c;
			($r, $c) = ($r + $dr, $c + $dc);
		}

		next unless @run;
		next unless $r >= 0 && $r < SIZE && $c >= 0 && $c < SIZE;
		my $end = $board->[ $r * SIZE + $c ];
		next unless defined $end && $end eq $colour;

		push @flips, @run;
	}

	return @flips;
}

sub legal_moves {
	my ($class, $board, $colour) = @_;
	return grep { scalar $class->flips_for($board, $_, $colour) }
	       grep { !defined $board->[$_] } 0 .. CELLS - 1;
}

sub has_move {
	my ($class, $board, $colour) = @_;
	for my $square (0 .. CELLS - 1) {
		next if defined $board->[$square];
		return 1 if $class->flips_for($board, $square, $colour);
	}
	return 0;
}

sub apply {
	my ($class, $board, $square, $colour) = @_;
	my @flips = $class->flips_for($board, $square, $colour);
	die "Game::Reversi::Board: $colour cannot play "
		. ($class->name_of($square) // 'that square') . ", it outflanks nothing"
		unless @flips;

	my $after = [ @$board ];
	$after->[$square] = $colour;
	$after->[$_] = $colour for @flips;
	return $after;
}

sub count {
	my ($class, $board) = @_;
	my %n = (b => 0, w => 0);
	for my $cell (@$board) {
		$n{$cell}++ if defined $cell;
	}
	return \%n;
}

sub empties {
	my ($class, $board) = @_;
	return scalar grep { !defined } @$board;
}

1;

__END__

=head1 NAME

Game::Reversi::Board - the 64 squares, the eight rays, and what outflanks what

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Reversi::Board;

    my $board = Game::Reversi::Board->empty;
    $board->[ Game::Reversi::Board->square_of('d', 5) ] = 'b';

    my @flips = Game::Reversi::Board->flips_for($board, $square, 'b');
    my @moves = Game::Reversi::Board->legal_moves($board, 'b');
    my $after = Game::Reversi::Board->apply($board, $square, 'b');

=head1 DESCRIPTION

The position and nothing above it. Whose turn it is, when a turn is forfeited
and when the game ends are rules, and they live in L<Game::Reversi::Rules>.

=head2 A board is an arrayref, not an object

Sixty four cells, index C<< row * 8 + col >>, row 0 being rank 8 and column 0
being file C<a>. So C<a8> is 0, C<h1> is 63, and the index reads in the order
the board is drawn.

These are class methods taking a board rather than methods on a board object,
because the bot's search calls L</flips_for> millions of times and an object
allocation per node is the difference between a level that searches and a level
that gives up. A board holds no invariants, so there is nothing for an object to
protect.

=head2 A cell holds undef, 'b' or 'w'

Not 0, 1 and 2. Index 0 is a real square and 0 is a plausible spelling of a
colour, so a numeric encoding lets C<< if ($board->[$sq]) >> mean "not black" by
accident.

=head2 The rays are walked by row and column

Both bounds checked, never by adding a stride to a flat index. A strided walk
stays within 0 .. 63 while stepping off the right hand edge of one rank and onto
the left hand edge of the next, so a range check on the index cannot see it, and
the result is a move that flips discs along a line no player can see.

=head1 METHODS

=head2 empty

A new board with all 64 cells empty.

=head2 clone

A copy of a board.

=head2 rays

The eight directions as C<[drow, dcol]> pairs, in the order L</flips_for>
returns its squares.

=head2 other

The opposite colour.

=head2 square_of

An index from a file letter and a rank digit. C<undef> for anything off the
board.

=head2 name_of

The algebraic name of an index, C<d5> and so on.

=head2 flips_for

The squares a disc played at C<$square> by C<$colour> would turn, in ray order.
Empty for a square that is already occupied and for a move that outflanks
nothing.

=head2 legal_moves

Every square where L</flips_for> returns something.

=head2 has_move

True if C<legal_moves> would return anything, without building the list. The
forced pass asks this once per turn, so it is worth not paying for the list.

=head2 apply

A new board with the disc placed and every outflanked disc turned. Dies on a
move that outflanks nothing, which is a fault in the caller rather than a
player's mistake.

=head2 count

A hashref of C<b> and C<w> counts. B<This is not the final score>: a game that
ends with squares still empty awards them to the winner, which is
L<Game::Reversi::Scoring>.

=head2 empties

How many squares are still empty.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
