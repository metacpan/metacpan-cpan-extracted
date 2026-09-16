package Game::Checkers::Squares;

use strict;
use warnings;

our $VERSION = '0.01';

use constant {
	NE => 0,
	NW => 1,
	SE => 2,
	SW => 3,
};

our (@DIRS, @DIR_NAME, %DIR_INDEX, @STEP, @JUMP_OVER, @JUMP_TO, @ROW, @COL, @DELTA, %FORWARD);

BEGIN {
	@DIRS = (NE, NW, SE, SW);
	@DIR_NAME = qw/NE NW SE SW/;
	%DIR_INDEX = (NE => NE, NW => NW, SE => SE, SW => SW);

	@DELTA = ([-1, 1], [-1, -1], [1, 1], [1, -1]);

	%FORWARD = (
		black => [SE, SW],
		white => [NE, NW],
	);
}

sub _check {
	my ($n) = @_;
	die "square must be 1 .. 32, got " . (defined $n ? "'$n'" : 'undef')
		unless defined $n && $n =~ m/^[0-9]+$/ && $n >= 1 && $n <= 32;
	return $n;
}

sub _coords {
	my ($n) = @_;
	my $row = int(($n - 1) / 4);
	my $i = ($n - 1) % 4;
	return ($row, $row % 2 == 0 ? ($i * 2) + 1 : $i * 2);
}

sub _square {
	my ($row, $col) = @_;
	return 0 if $row < 0 || $row > 7 || $col < 0 || $col > 7;
	return 0 unless ($row + $col) % 2;
	return ($row * 4) + ($col >> 1) + 1;
}

for my $n (1 .. 32) {
	my ($row, $col) = _coords($n);
	$ROW[$n] = $row;
	$COL[$n] = $col;
	for my $dir (@DIRS) {
		my ($dr, $dc) = @{$DELTA[$dir]};
		my $i = ($n * 4) + $dir;
		my $step = _square($row + $dr, $col + $dc);
		$STEP[$i] = $step;
		my $landing = $step ? _square($row + ($dr * 2), $col + ($dc * 2)) : 0;
		$JUMP_OVER[$i] = $landing ? $step : 0;
		$JUMP_TO[$i] = $landing;
	}
}

sub coords {
	my ($n) = @_;
	_check($n);
	return ($ROW[$n], $COL[$n]);
}

sub square {
	my ($row, $col) = @_;
	return undef unless defined $row && defined $col;
	return _square($row, $col) || undef;
}

sub row_of {
	my ($n) = @_;
	_check($n);
	return $ROW[$n];
}

sub col_of {
	my ($n) = @_;
	_check($n);
	return $COL[$n];
}

sub coord_name {
	my ($n) = @_;
	_check($n);
	return sprintf '%s%d', chr(ord('a') + $COL[$n]), 8 - $ROW[$n];
}

sub coord_square {
	my ($name) = @_;
	return undef unless defined $name && $name =~ m/^([a-h])([1-8])$/i;
	return _square(8 - $2, ord(lc $1) - ord('a')) || undef;
}

sub steps {
	my ($n) = @_;
	_check($n);
	my %step;
	for my $dir (@DIRS) {
		$step{$DIR_NAME[$dir]} = $STEP[($n * 4) + $dir] || undef;
	}
	return \%step;
}

sub jump {
	my ($n, $dir) = @_;
	_check($n);
	$dir = dir_index($dir);
	my $i = ($n * 4) + $dir;
	return () unless $JUMP_TO[$i];
	return ($JUMP_OVER[$i], $JUMP_TO[$i]);
}

sub dir_index {
	my ($dir) = @_;
	return $dir if defined $dir && $dir =~ m/^[0-3]$/;
	die "direction must be NE, NW, SE, SW or 0 .. 3, got " . (defined $dir ? "'$dir'" : 'undef')
		unless defined $dir && exists $DIR_INDEX{uc $dir};
	return $DIR_INDEX{uc $dir};
}

sub dir_name {
	my ($dir) = @_;
	return $DIR_NAME[dir_index($dir)];
}

sub forward_dirs {
	my ($side) = @_;
	die "side must be black or white, got " . (defined $side ? "'$side'" : 'undef')
		unless defined $side && $FORWARD{$side};
	return @{$FORWARD{$side}};
}

sub crowning {
	my ($n, $side) = @_;
	_check($n);
	die "side must be black or white, got " . (defined $side ? "'$side'" : 'undef')
		unless defined $side && $FORWARD{$side};
	return $side eq 'black' ? ($n >= 29 ? 1 : 0) : ($n <= 4 ? 1 : 0);
}

1;

__END__

=head1 NAME

Game::Checkers::Squares - the board numbering, and the step and jump tables built from it

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers::Squares;

	my ($row, $col) = Game::Checkers::Squares::coords(15);
	my $steps = Game::Checkers::Squares::steps(15);      # { NE => 11, NW => 10, SE => 19, SW => 18 }
	my ($over, $landing) = Game::Checkers::Squares::jump(15, 'SE');   # (19, 24)

=head1 DESCRIPTION

The standard draughts numbering, with Black's back rank at the top of the board.
Rows run 1 to 8 from the top and files a to h from the left. Only the 32 dark
squares play, numbered 1 to 32 from left to right and top to bottom: squares 1 to
4 are the top row and 29 to 32 the bottom row.

Black starts on squares 1 to 12 and moves toward higher numbers. White starts on
squares 21 to 32 and moves toward lower numbers. Black moves first.

Directions are board absolute, with north at the top, so C<SE> means one row down
and one column right whichever colour is moving. Forward is a per colour lookup
through L</forward_dirs> and never a sign in the caller.

Every function dies on a square outside 1 to 32 or a side that is not C<black> or
C<white>: those are programmer errors, not player mistakes, and a player's mistake
is a L<Game::Checkers::Error> instead.

=head1 PACKAGE VARIABLES

The tables are built once when the module is loaded and are the fast path the
search uses. They are documented because L<Game::Checkers::Bot> reads them
directly rather than calling an accessor several million times a move.

=head2 @STEP

C<< $STEP[($n * 4) + $dir] >> is the square one step from C<$n> in C<$dir>, or 0
when that step leaves the board.

=head2 @JUMP_OVER and @JUMP_TO

C<< $JUMP_TO[($n * 4) + $dir] >> is the square a jump from C<$n> in C<$dir> lands
on and C<< $JUMP_OVER[...] >> is the square it passes over, or 0 in both when no
jump in that direction fits on the board. A direction with a step but no landing
square has 0 in both, so testing C<@JUMP_TO> alone is enough.

=head2 @ROW and @COL

C<< $ROW[$n] >> and C<< $COL[$n] >> are the zero based row and column of square
C<$n>. Row 0 is Black's back rank.

=head1 CONSTANTS

C<NE>, C<NW>, C<SE> and C<SW> are the direction indices 0, 1, 2 and 3. C<@DIRS>
is all four in that order and C<@DIR_NAME> maps an index back to its name.

=head1 FUNCTIONS

=head2 coords

Returns the zero based row and column of a square.

	my ($row, $col) = Game::Checkers::Squares::coords(9);   # (2, 1)

=head2 square

Returns the square number at a row and column, or undef when the coordinates are
off the board or name a light square. Unlike the rest of this module it does not
die, because it is the function used to walk off the edge on purpose.

	Game::Checkers::Squares::square(2, 1);   # 9
	Game::Checkers::Squares::square(2, 2);   # undef, a light square

=head2 row_of

The zero based row of a square, 0 for Black's back rank and 7 for White's.

=head2 col_of

The zero based column of a square.

=head2 coord_name

The algebraic name of a square for display, with file a on the left and rank 8 on
Black's back rank.

	Game::Checkers::Squares::coord_name(1);   # 'b8'

=head2 coord_square

The square an algebraic name stands for, or undef when the name is not one of the
32 playing squares. The file may be upper case. Like L</square> it does not die,
because it is given what somebody typed.

	Game::Checkers::Squares::coord_square('b8');   # 1
	Game::Checkers::Squares::coord_square('a8');   # undef, a light square

=head2 steps

Returns a hashref of the four neighbouring squares by direction name, with undef
for a direction that leaves the board.

	Game::Checkers::Squares::steps(5);   # { NE => 1, NW => undef, SE => 9, SW => undef }

=head2 jump

Returns the jumped square and the landing square for a jump from C<$n> in
C<$dir>, or the empty list when no such jump fits on the board. The direction may
be a name or an index.

	my ($over, $landing) = Game::Checkers::Squares::jump(9, 'SE');   # (14, 18)

=head2 dir_index

Turns a direction name into its index, passing an index through unchanged.

=head2 dir_name

Turns a direction index into its name.

=head2 forward_dirs

The two directions a man of the given side moves in.

	my @dirs = Game::Checkers::Squares::forward_dirs('black');   # (SE, SW)

=head2 crowning

True when the square is the given side's promotion row: 29 to 32 for Black and 1
to 4 for White.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-checkers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Checkers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Checkers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Checkers>

=item * Search CPAN

L<https://metacpan.org/release/Game-Checkers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
