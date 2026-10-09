package Game::Merrills::Points;

use strict;
use warnings;

our $VERSION = '0.01';

use constant {
	POINTS => 24,
	SIZE => 7,
};

our (@NAME, %POINT, @ROW, @COL, @ADJACENT, @MILLS, @MILLS_OF);

BEGIN {
	@NAME = qw/
		a7 d7 g7
		b6 d6 f6
		c5 d5 e5
		a4 b4 c4 e4 f4 g4
		c3 d3 e3
		b2 d2 f2
		a1 d1 g1
	/;

	@ADJACENT = (
		[1, 9], [0, 2, 4], [1, 14],
		[4, 10], [1, 3, 5, 7], [4, 13],
		[7, 11], [4, 6, 8], [7, 12],
		[0, 10, 21], [3, 9, 11, 18], [6, 10, 15],
		[8, 13, 17], [5, 12, 14, 20], [2, 13, 23],
		[11, 16], [15, 17, 19], [12, 16],
		[10, 19], [16, 18, 20, 22], [13, 19],
		[9, 22], [19, 21, 23], [14, 22],
	);

	@MILLS = (
		[0, 1, 2], [3, 4, 5], [6, 7, 8],
		[9, 10, 11], [12, 13, 14],
		[15, 16, 17], [18, 19, 20], [21, 22, 23],
		[0, 9, 21], [3, 10, 18], [6, 11, 15],
		[1, 4, 7], [16, 19, 22],
		[8, 12, 17], [5, 13, 20], [2, 14, 23],
	);

	for my $n (0 .. $#NAME) {
		my ($file, $rank) = $NAME[$n] =~ m/^([a-g])([1-7])$/;
		$POINT{$NAME[$n]} = $n;
		$ROW[$n] = SIZE - $rank;
		$COL[$n] = ord($file) - ord('a');
		$MILLS_OF[$n] = [];
	}

	for my $mill (@MILLS) {
		push @{$MILLS_OF[$_]}, $mill for @{$mill};
	}
}

sub _check {
	my ($n) = @_;
	die 'point must be 0 .. 23, got ' . (defined $n ? "'$n'" : 'undef')
		unless defined $n && $n =~ m/^[0-9]+$/ && $n < POINTS;
	return $n;
}

sub all_points {
	return (0 .. POINTS - 1);
}

sub point {
	my ($name) = @_;
	return undef unless defined $name;
	return $POINT{lc $name};
}

sub name {
	my ($n) = @_;
	_check($n);
	return $NAME[$n];
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

sub adjacent {
	my ($n) = @_;
	_check($n);
	return @{$ADJACENT[$n]};
}

sub is_adjacent {
	my ($from, $to) = @_;
	_check($from);
	_check($to);
	return scalar(grep { $_ == $to } @{$ADJACENT[$from]}) ? 1 : 0;
}

sub mills {
	return map { [@{$_}] } @MILLS;
}

sub mills_of {
	my ($n) = @_;
	_check($n);
	return map { [@{$_}] } @{$MILLS_OF[$n]};
}

1;

__END__

=head1 NAME

Game::Merrills::Points - the 24 points, the lines between them and the 16 mills

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Merrills::Points;

	my $d2 = Game::Merrills::Points::point('d2');      # 19
	Game::Merrills::Points::name(19);                  # 'd2'
	Game::Merrills::Points::adjacent($d2);             # 16, 18, 20, 22
	Game::Merrills::Points::mills_of($d2);             # [18, 19, 20], [16, 19, 22]

=head1 DESCRIPTION

The board of Nine Men's Morris is three squares, one inside the next, joined
at the middle of each side. Men stand where lines meet or turn, which gives 24
points, 32 lines between neighbouring points, and 16 rows of three that can
become a mill.

A point has a number and a name. The numbers run 0 to 23 in reading order from
the top of the board, and the names are the usual coordinates, files C<a> to
C<g> from the left and ranks C<1> to C<7> from the bottom:

	a7 . . d7 . . g7        0        1        2
	.  b6 . d6 . f6 .          3     4     5
	.  .  c5 d5 e5 . .            6  7  8
	a4 b4 c4 .  e4 f4 g4    9  10 11    12 13 14
	.  .  c3 d3 e3 . .            15 16 17
	.  b2 . d2 . f2 .          18    19    20
	a1 . . d1 . . g1        21       22       23

The centre, C<d4>, is not a point. That is why C<a4 b4 c4> and C<e4 f4 g4> are
two mills and C<b4 c4 e4> is none, and the same down the C<d> file.

Every point is in exactly two mills, one across and one down. The twelve
corners have two neighbours, the midpoints of the outer and inner squares have
three, and the four midpoints of the middle square, C<d6>, C<b4>, C<f4> and
C<d2>, have four.

Nothing here knows whose man is where. See L<Game::Merrills::Board>.

=head1 PACKAGE VARIABLES

The tables the functions read are package variables, for code that asks often
and would sooner index than call. Treat them as read only.

=over 4

=item C<@NAME>

The coordinate of each point.

=item C<%POINT>

The number of each coordinate, in lower case.

=item C<@ROW>, C<@COL>

Where each point sits on a seven by seven grid, row 0 at the top and column 0
on the left.

=item C<@ADJACENT>

For each point, an arrayref of its neighbours in ascending order.

=item C<@MILLS>

The sixteen mills, each an arrayref of three points. The eight across come
first.

=item C<@MILLS_OF>

For each point, an arrayref of the two mills it belongs to.

=back

=head1 FUNCTIONS

None is exported. Every function that takes a point number dies when handed
anything that is not one.

=head2 all_points

The 24 point numbers, in order.

	for my $n (Game::Merrills::Points::all_points()) { ... }

=head2 point

The number of a coordinate, or undef when the name is not a point. Case does
not matter.

	Game::Merrills::Points::point('A7');     # 0
	Game::Merrills::Points::point('d4');     # undef

=head2 name

The coordinate of a point.

	Game::Merrills::Points::name(0);         # 'a7'

=head2 row_of

The row of a point, 0 at the top to 6 at the bottom.

	Game::Merrills::Points::row_of(0);       # 0

=head2 col_of

The column of a point, 0 on the left to 6 on the right.

	Game::Merrills::Points::col_of(2);       # 6

=head2 adjacent

The neighbours of a point, the points a man standing on it can move to along
a line.

	Game::Merrills::Points::adjacent(0);     # 1, 9

=head2 is_adjacent

True when a line joins the two points.

	Game::Merrills::Points::is_adjacent(0, 1);     # 1
	Game::Merrills::Points::is_adjacent(0, 2);     # 0

=head2 mills

All sixteen mills, each a fresh arrayref of three points.

	my @mills = Game::Merrills::Points::mills();

=head2 mills_of

The two mills a point belongs to, each a fresh arrayref of three points.

	my ($across, $down) = Game::Merrills::Points::mills_of(0);

=head1 CONSTANTS

=over 4

=item POINTS

24, the number of points.

=item SIZE

7, the number of files and of ranks.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
