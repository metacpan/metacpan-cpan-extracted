package Game::Go::Rules;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use constant {
	EMPTY  => 0,
	BLACK  => 1,
	WHITE  => 2,
	BORDER => 3,
};

use constant {
	MIN_SIZE => 2,
	MAX_SIZE => 19,
};

use constant {
	OK          => 0,
	ILL_OFF     => 1,
	ILL_TAKEN   => 2,
	ILL_KO      => 3,
	ILL_SUICIDE => 4,
	ILL_REPEAT  => 5,
	ILL_COLOUR  => 6,
};

our @SIZES;
BEGIN { @SIZES = (9, 13, 19) }

use constant DEFAULT_KOMI => 6.5;

use constant HANDICAP_KOMI => 0.5;

use constant MAX_HANDICAP => 9;

our %STARS;
BEGIN {
	%STARS = (
		19 => { A => [15,3], B => [3,15], C => [15,15], D => [3,3], E => [9,9],
		        F => [3,9],  G => [15,9], H => [9,3],   I => [9,15] },
		13 => { A => [9,3],  B => [3,9],  C => [9,9],   D => [3,3], E => [6,6] },
		9  => { A => [6,2],  B => [2,6],  C => [6,6],   D => [2,2], E => [4,4] },
	);
}

our %HANDICAP;
BEGIN {
	my @big = (
		undef, [],
		[qw(A B)],
		[qw(A B C)],
		[qw(A B C D)],
		[qw(A B C D E)],
		[qw(A B C D F G)],
		[qw(A B C D E F G)],
		[qw(A B C D F G H I)],
		[qw(A B C D E F G H I)],
	);
	%HANDICAP = (
		19 => [@big],
		13 => [ @big[0 .. 5] ],
		9  => [ @big[0 .. 5] ],
	);
}

sub max_handicap {
	my $size = $_[-1];
	return 0 unless $HANDICAP{$size};
	return $#{ $HANDICAP{$size} };
}

sub handicap_points {
	my ($size, $n) = @_[-2, -1];
	return [] unless $HANDICAP{$size} && $n && $n <= max_handicap($size);
	my $labels = $HANDICAP{$size}[$n] || [];
	return [ map { $STARS{$size}{$_} } @$labels ];
}

sub star_points {
	my $size = $_[-1];
	return [] unless $STARS{$size};
	return [ map { $STARS{$size}{$_} } sort keys %{ $STARS{$size} } ];
}

our %REFUSAL;
BEGIN {
	%REFUSAL = (
		0 => 'that move is legal',
		1 => 'that point is not on the board',
		2 => 'there is already a stone there',
		3 => 'the ko rule forbids retaking that point immediately',
		4 => 'that move would leave your own stones with no liberty',
		5 => 'that move would repeat a position the game has already had',
		6 => 'that is not a colour',
	);
}

sub sizes    { @SIZES }
sub refusal  { $REFUSAL{ $_[-1] } }
sub refusals { return { %REFUSAL } }

sub other { $_[-1] == BLACK ? WHITE : BLACK }

sub is_colour { defined $_[-1] && ($_[-1] == BLACK || $_[-1] == WHITE) }

sub colour_name { $_[-1] == BLACK ? 'black' : $_[-1] == WHITE ? 'white' : 'nobody' }

sub letter { !defined $_[-1] ? undef : $_[-1] == BLACK ? 'b' : $_[-1] == WHITE ? 'w' : undef }

sub from_letter {
	my $l = $_[-1];
	return undef unless defined $l;
	return BLACK if $l eq 'b';
	return WHITE if $l eq 'w';
	return undef;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Rules - the constants, the codes and the pinned values

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Go::Rules;

    Game::Go::Rules::BLACK;          # 1
    Game::Go::Rules::other(BLACK);   # WHITE
    Game::Go::Rules::refusal(3);     # the sentence for a ko refusal

=head1 DESCRIPTION

A leaf module that depends on nothing, so that L<Game::Go> and
L<Game::Go::Engine> can both use it without loading each other.

Everything here is either a value pinned from a source, with the source named,
or a house choice labelled as one.

=head1 CONSTANTS

=head2 EMPTY, BLACK, WHITE, BORDER

The four values a point can hold. C<EMPTY> is 0, so a fresh board is a zeroed
board. C<BORDER> is the engine's sentinel ring and is never a point a caller can
name.

=head2 MIN_SIZE, MAX_SIZE

2 and 19.

=head2 OK, ILL_OFF, ILL_TAKEN, ILL_KO, ILL_SUICIDE, ILL_REPEAT, ILL_COLOUR

Why a move was refused. C<OK> is 0 and every other value names one rule.
C<ILL_COLOUR> is programmer error rather than a refused move.

=head2 DEFAULT_KOMI

6.5, on every size, and B<a house choice rather than a pinned rule>. Komi is not
in the Japanese rules of 1989 at all. The fractional part is the device that
makes a draw impossible, which Article 10.2 would otherwise permit; the
particular value is conventional for 19x19 and has no standard at all for 9x9.

=head2 HANDICAP_KOMI

0.5 in a handicap game, on Sensei's Library: "there is no komi (or it is just
0.5, to prevent a draw)".

=head2 MAX_HANDICAP

9. Beyond nine stones the difference in strength is usually taken to make the
game a lesson rather than a contest.

=head1 FUNCTIONS

=head2 sizes

The three sizes the distribution offers: 9, 13 and 19.

=head2 refusal, refusals

The sentence for a refusal code, and the whole table as a hashref. The table is
copied, so a caller cannot edit it by editing what it got back.

=head2 other

The other colour.

=head2 is_colour

Whether a value is C<BLACK> or C<WHITE>. C<EMPTY> and C<BORDER> are not colours
a player can be.

=head2 colour_name

C<black>, C<white>, or C<nobody>.

=head2 star_points

    Game::Go::Rules::star_points(19)     # nine [col, row] pairs

The star points of a board, as C<[$col, $row]> pairs.

Cited for 19x19, Sensei's Library: "Star points (J. hoshi) are the nine points
on a 19x19 go board marked by small dots, where handicap stones are placed ...
there are 3 named star points: the 4-4 point (corner star), the 10-4 point (side
star) and the 10-10 point (tengen)."

For the small boards the same source says only B<how many>: "A 13x13 board has
only five star points", and "A 9x9 board also has only five star points. However,
some leave out that in the center, some those in the corners." So their
coordinates here are ours, on the obvious reading, and the 9x9 set is one the
source says is not settled.

=head2 max_handicap

How many stones a board can take: nine on 19x19, five on the others. It is a
property of the B<board> rather than one number, because only 19x19 has nine
star points to put them on.

=head2 handicap_points

    Game::Go::Rules::handicap_points(19, 4)

The points a handicap places, as C<[$col, $row]> pairs, in the traditional
order. Empty for a handicap of 0 or 1, which place none.

Cited for 19x19 from Wikipedia's "Handicapping in Go", whose table references
Iwamoto Kaoru, I<Go for Beginners>, Pantheon, 1977 (originally 1972), pages
109-114. Two rows of it are what a reader is most likely to get wrong: at three
stones it is the B<upper left> that is left out, and six and seven use the
B<left and right> side stars rather than the top and bottom.

For 9x9 and 13x13 there is no cited convention and there cannot be a nine-stone
one. Those follow the same order as far as their five points go, which is ours.

=head2 letter, from_letter

A colour as C<b> or C<w>, and back again. Undef for anything that is not a
colour.

The log writes colours as letters because a log is read by people and
transported as JSON, and a bare 1 or 2 in an event payload is a number nobody
can check by eye. The engine keeps them numeric, because the C does.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
