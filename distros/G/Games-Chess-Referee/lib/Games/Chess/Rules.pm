#
# Rules.pm
#
# Games::Chess::Rules Perl module.
#
# This module is an attempt to codify the rules of chess in a fairly general
# way so that a general mechanism can be used to generate possible plies and
# to check plies for validity.
#
# Copyright (C) 1999-2006 Gregor N. Purdy. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Games::Chess::Rules;

use strict;
use Games::Chess qw(:constants);
use Games::Chess::Piece::General;


#
# ::new()
#

sub new
{
	my $class = shift;

	my $this = { };

	return bless($this, $class);
}


#
# TODO: Rework how this stuff functions.
#
# Validate: Board + Ply -> Board
# Generate: Board + Space -> Plies
#           Board -> Plies
#

#
# ::color()
#

sub color
{
	my $this = shift;

	if (@_) { $this->{COLOR} = shift; }
	else    { return $this->{COLOR}; }
}


#
# ::piece()
#

sub piece
{
	my $this = shift;

	if (@_) {
		$this->{PIECE} = shift;
		$this->from(undef);
		$this->to(undef);
		$this->color(undef);
	} else {
		my $piece = $this->{PIECE};
		if !defined($piece) {
			my $space = $this->from();
			return undef unless defined($space);
			$this->board()->piece($space);
		}

		return $this->{PIECE};
	}
}



#
# ::from()
#

sub from
{
	my $this = shift;

	if (@_) { $this->{FROM} = shift; }
	else    { return $this->{FROM}; }
}


#
# ::to()
#

sub to
{
	my $this = shift;

	if (@_) { $this->{TO} = shift; }
	else    { return $this->{TO}; }
}



#########################################################################################3
#
# Predicates:
#
#########################################################################################3


#
# white(<piece>)
# white(<space>)
#

sub white ($)
{
	my $thing = shift;

	return 0 unless defined($thing);

	return white($thing->piece)      if $thing->isa('Games::Chess::Space');
	return ($thing->color == &WHITE) if $thing->isa('Games::Chess::Piece');

	croak 'white() requires a piece or a space';
}


#
# black(<piece>)
# black(<space>)
#

sub black ($)
{
	my $thing = shift;

	return 0 unless defined($thing);

	return black($thing->piece)      if $thing->isa('Games::Chess::Space');
	return ($thing->color == &BLACK) if $thing->isa('Games::Chess::Piece');

	croak 'black() requires a piece or a space';
}


#
# home(<piece>)
# home(<space>)
#

sub home ($)
{
	my $thing = shift;

	return 0 unless defined($thing);

	return home($thing->piece)               if $thing->isa('Games::Chess::Space');
	return (scalar($thing->trajectory) == 0) if $thing->isa('Games::Chess::Piece');

	croak 'home() requires a piece or a space';
}


#
# empty(<space>)
# 

sub empty ($)
{
	my $thing = shift;

	return 0 unless defined($thing);

	return !defined($thing->piece) if $thing->isa('Games::Chess::Space');

	croak 'empty() requires a space';
}


#
# open(<space>, <space>)
#
# The spaces between the starting and resulting square are empty.
#

sub open ($$)
{
	my $start;
	my $end;

	# TODO
}


#
# clear(<space>, <space>)
#
# The intervening spaces are open and not guarded, and the starting and ending spaces
# are not guarded. This is used in the description of castling.
#

sub clear ($$)
{
	my ($from, $to) = @_;

	# TODO
}


#
# enemy(<color>, <piece>)
# enemy(<color>, <space>)
#

sub enemy ($$)
{
	my ($color, $thing) = @_;

	# TODO
}


#
# friend(<color>, <piece>)
# friend(<color>, <space>)
#

sub friend ($$)
{
	my ($color, $thing) = @_;

	# TODO
}


#
# pawn(<piece>)
# pawn(<space>)
#

sub pawn ($)
{
	# TODO
}


#
# guarded(<piece>)
# guarded(<space>)
#

sub guarded ($)
{
	# TODO
}


#
# last_from(<space>)
#
# True if the square given is the `from' from the last ply.
#

sub last_from ($)
{
	# TODO
}


#
# last_to(<space>)
#
# True if the square given is the `to' from the last ply.
#

sub last_to ($)
{
	# TODO
}


#
# last(<space>, <space>)
#

sub last ($$)
{
	# TODO
}


#
# delta(<space>, <files>, <ranks>)
#

sub delta ($$$)
{
	my ($space, $files, $ranks) = @_;

	my $file = $space->file_num;
	my $rank = $space->rank_num;

	return $space->board->space($file_num + $files, $rank_num + $ranks);
}


#
# queenward(<space>)
#

sub queenward ($)
{ 
	my $space = shift;

	return delta($space, -1, 0);
}


#
# kingward(<space>)
#

sub kingward ($)
{ 
	my $space = shift;

	return delta($space, +1, 0);
} 


#
# whiteward(<space>)
#

sub whiteward ($)
{ 
	my $space = shift;

	return delta($space, 0, -1);
}


#
# blackward(<space>)
#

sub blackward ($)
{ 
	my $space = shift;

	return delta($space, 0, +1);
}


#
# forward(<color>, <space>)
#

sub forward ($$)
{
	my ($color, $space) = @_;

	if ($color == &WHITE) {
		return blackward($space);
	} elsif ($color == &BLACK) {
		return whiteward($space);
	} else {
		croak 'Invalid color';
	}
}


#
# backward(<color>, <space>)
#

sub backward ($$)
{
	my ($color, $space) = @_;

	if ($color == &BLACK) {
		return blackward($space);
	} elsif ($color == &WHITE) {
		return whiteward($space);
	} else {
		croak 'Invalid color';
	}
}


#
# TODO: Stuff to incorporate.
#

=pod

=item C<kings_rook>

The rook home position on the king's side.

=item C<queens_rook>

The rook home position on the queen's side.

=back


=head2 Vectors

vectors may be added, subtracted, and multiplied by a constant.

=over 4

=item C<ahead>

The space immediately `ahead', meaning away from the home row of the color.


=head2 Compound predicates

=over 4

=item C<white_passant>

C<
(enemy(left) and pawn(left) and last(left + [0, 2], left))
or
(enemy(right) and pawn(right) and last(right + [0, 2], right))
>

=item C<black_passant>

C<
(enemy(left) and pawn(left) and last(left - [0, 2], left))
or
(enemy(right) and pawn(right) and last(right - [0, 2], right))
>

=item C<passant>

C<
(white and white_passant) or (black and black_passant)
>

=back

The default action is for the piece to move to the destination and the enemy piece at that
location to be removed. For specialty moves, these can be overridden.

It is assumed that any moves generated by these rules that produce off-board result
positions are rejected.


=head2 Actions

=over 4

=item C<mutate>

After the move, mutat to the designated piece (used for pawn promotion in standard chess).

=back


=head2 Formalized Plies

Pawns:

    [ahead]         if empty;
    [ahead * 2]     if empty and clear and home;
    [ahead + left]  if enemy or passant;
    [ahead + right] if enemy or passant.

Rooks:

    [0, ?]   if clear and not friend;
    [?, 0]   if clear and not friend.

Knights:

    [+1, +2] if not friend;
    [+1, -2] if not friend;
    [-1, +2] if not friend;
    [-1, -2] if not friend;
    [+2, +1] if not friend;
    [+2, -1] if not friend;
    [-2, +1] if not friend;
    [-2, -1] if not friend.

Bishops:

    [?,  ?]  if clear and not friend;
    [?, -?]  if clear and not friend.

Queens:

    [0, ?]   if clear and not friend;
    [?, 0]   if clear and not friend.
    [?, ?]   if clear and not friend;
    [?, -?]  if clear and not friend.

Kings:

    [-1, -1] if not friend and not threat;
    [-1,  0] if not friend and not threat;
    [-1, +1] if not friend and not threat;
    [ 0, -1] if not friend and not threat;
    [ 0, +1] if not friend and not threat;
    [+1, -1] if not friend and not threat;
    [+1,  0] if not friend and not threat;
    [+1, +1] if not friend and not threat;
    [king * 2]  if home and home[kings_rook] and clear[king, kings_rook];
    [queen * 3] if home and home[queens_rook] and clear[king, queens_rook];


We still need notations for the rook movements during castling.

Globally: C<not threat[king]>;


=cut


#
# End of file.
#

