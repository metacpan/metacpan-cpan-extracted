#
# Games::Chess::Referee
#
# A Perl Module for validating chess moves.
#
# Copyright (C) 1999-2006 Gregor N. Purdy. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl iteself.
#

package Games::Chess::Referee;

use base 'Exporter';
use strict;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.003';
@EXPORT = qw(&ply &move &new_game &show_board);
@EXPORT_OK = @EXPORT;

use Games::Chess qw(:constants :functions);
use Carp;

my $board;

my $occupy  = '-';
my $capture = 'x';


#
# new_game()
#

sub new_game ()
{
	$board = Games::Chess::Position->new();

#	print STDERR "Game: ", $board->to_FEN(), "\n";
}


#
# show_board()
#

sub show_board ()
	{ print $board->to_text(), "\n"; }


#
# ply()
#

sub ply ($)
{
	my ($ply) = @_;
	my ($piece, $ff, $fr, $act, $tf, $tr, $note);
	my $notation = undef;
	
	#
	# Translate castling notations:
	#

	if ($ply eq '0-0') {
		if ($board->player_to_move() eq &WHITE) { $ply = 'E1G1'; }
		else                                    { $ply = 'E8G8'; }
	}
	elsif ($ply eq '0-0-0') {
		if ($board->player_to_move() eq &WHITE) { $ply = 'E1C1'; }
		else                                    { $ply = 'E8C8'; }
	}

	#
	# Parse the ply notation:
	#

	if ($ply =~ m/^([prnbqkPRNBQK]|)([a-hA-H])([1-8])(x|-|)([a-hA-H])([1-8])(.*)$/) {
		($piece, $ff, $fr, $act, $tf, $tr, $note) = ($ply =~ m/^([prnbqkPRNBQK]|)([a-hA-H])([1-8])(x|-|)([a-hA-H])([1-8])(.*)$/);
		$piece = uc($piece);
		$ff    = uc($ff);
		$tf    = uc($tf);
	}
	else {
		carp "Unsupported notation: `$ply'!";
		return 0;
	}

	my $from = lc("$ff$fr");
	my $to   = lc("$tf$tr");

	my @from = algebraic_to_xy($from);
	my @to   = algebraic_to_xy($to);

	my $from_piece = $board->at(@from);
	my $to_piece   = $board->at(@to);

	my $from_kind  = uc($from_piece->code());
	my $to_kind    = uc($to_piece->code());

	#
	# Check for attempts to castle:
	#
	# 1. Ensure castling is permitted (neither King nor Rook has moved prior).
	# 2. Ensure the way is clear between the King and Rook.
	# 3. Move the Rook to its final location (the King's move will be
	#    effected by the later code.
	#
	# TODO: Ensure that the King is not in check, and that none of the
	# relevant squares are under attack.
	#

	my $castling;

	if	($ff eq 'E' and $fr == 1 and $tf eq 'G' and $tr == 1) {
#		print STDERR "ATTEMPT BY WHITE TO CASTLE SHORT...\n";

		if (!$board->can_castle(&WHITE, &KING)) {
			carp "Castling short by white not permitted!";
#			print STDERR "Game = ", $board->to_FEN(), "\n";
			return 0;
		} elsif (!$board->at(5, 0)->code() eq ' ') {
			carp "Way not clear (space `f1') for castling short!";
			return 0;
		} elsif (!$board->at(6, 0)->code() eq ' ') {
			carp "Way not clear (space `g1') for castling short!";
			return 0;
		} else {
			$board->at(5, 0, $board->at(7, 0));
			$board->at(7, 0, Games::Chess::Piece->new);

			$notation = '0-0';
			$castling = 'SHORT';
		}
	}
	elsif	($ff eq 'E' and $fr == 8 and $tf eq 'G' and $tr == 8) {
#		print STDERR "ATTEMPT BY BLACK TO CASTLE SHORT...\n";

		if (!$board->can_castle(&BLACK, &KING)) {
			carp "Castling short by black not permitted!";
			return 0;
		} elsif (!$board->at(5, 7)->code() eq ' ') {
			carp "Way not clear (space `f8') for castling short!";
			return 0;
		} elsif (!$board->at(6, 7)->code() eq ' ') {
			carp "Way not clear (space `g8') for castling short!";
			return 0;
		} else {
			$board->at(5, 7, $board->at(7, 7));
			$board->at(7, 7, Games::Chess::Piece->new);

			$notation = '0-0';
			$castling = 'SHORT';
		}
	}
	elsif	($ff eq 'E' and $fr == 1 and $tf eq 'C' and $tr == 1) {
#		print STDERR "ATTEMPT BY WHITE TO CASTLE LONG...\n";

		if (!$board->can_castle(&WHITE, &QUEEN)) {
			carp "Castling long by white not permitted!";
			return 0;
		} elsif (!$board->at(1, 0)->code() eq ' ') {
			carp "Way not clear (space `b1') for castling long!";
			return 0;
		} elsif (!$board->at(2, 0)->code() eq ' ') {
			carp "Way not clear (space `c1') for castling long!";
			return 0;
		} elsif (!$board->at(3, 0)->code() eq ' ') {
			carp "Way not clear (space `d1') for castling long!";
			return 0;
		} else {
			$board->at(3, 0, $board->at(0, 0));
			$board->at(0, 0, Games::Chess::Piece->new);

			$notation = '0-0-0';
			$castling = 'LONG';
		}
	}
	elsif	($ff eq 'E' and $fr == 8 and $tf eq 'C' and $tr == 8) {
#		print STDERR "ATTEMPT BY BLACK TO CASTLE LONG...\n";

		if (!$board->can_castle(&BLACK, &QUEEN)) {
			carp "Castling long by black not permitted!";
			return 0;
		} elsif (!$board->at(1, 0)->code() eq ' ') {
			carp "Way not clear (space `b8') for castling long!";
			return 0;
		} elsif (!$board->at(2, 0)->code() eq ' ') {
			carp "Way not clear (space `c8') for castling long!";
			return 0;
		} elsif (!$board->at(3, 0)->code() eq ' ') {
			carp "Way not clear (space `d8') for castling long!";
			return 0;
		} else {
			$board->at(3, 7, $board->at(0, 7));
			$board->at(0, 7, Games::Chess::Piece->new);

			$notation = '0-0-0';
			$castling = 'LONG';
		}
	}
	else {
		# Not castling.
	}

	#
	# Record new castling permissions:
	#
	# TODO: Write tests that exercise this code! The warnings weren't printing
	# when they should.
	#

	if      ($from eq 'A1') {
		$board->can_castle(&WHITE, &QUEEN, 0);
#		print STDERR "Warning: Castling long by white no longer permitted.\n";
	} elsif ($from eq 'A8') {
		$board->can_castle(&BLACK, &QUEEN, 0);
#		print STDERR "Warning: Castling long by black no longer permitted.\n";
	} elsif ($from eq 'H1') {
		$board->can_castle(&WHITE, &KING,  0);
#		print STDERR "Warning: Castling short by white no longer permitted.\n";
	} elsif ($from eq 'H8') {
		$board->can_castle(&BLACK, &KING,  0);
#		print STDERR "Warning: Castling short by black no longer permitted.\n";
	} elsif ($from eq 'E1') {
		$board->can_castle(&WHITE, &QUEEN, 0);
		$board->can_castle(&WHITE, &KING,  0);
#		print STDERR "Warning: Castling short by white no longer permitted.\n";
#		print STDERR "Warning: Castling long by white no longer permitted.\n";
	} elsif ($from eq 'E8') {
		$board->can_castle(&BLACK, &QUEEN, 0);
		$board->can_castle(&BLACK, &KING,  0);
#		print STDERR "Warning: Castling short by black no longer permitted.\n";
#		print STDERR "Warning: Castling long by black no longer permitted.\n";
	} else {
		# No change to castling status.
	}

	#
	# Detect the piece: 
	#

	if (!$piece) { $piece = $from_kind; };

	if ($piece ne $from_kind) {
#		print STDERR "\n";
#		print STDERR "Piece: $piece\n";
#		print STDERR "Ply:   $ply\n";
#		print STDERR "From Space: $from\n";
#		print STDERR "From Kind: $from_kind\n";
		carp "Piece (`$piece') from ply (`$ply') does not match board piece (`$from_kind') at space `$from'!";
		return 0;
	}

	#
	# Detect the action:
	#
	# TODO: Make sure we only permit capture of other color's pieces.
	#

	my $board_act;

	if ($to_kind eq ' ') { $board_act = $occupy; }
	else                 { $board_act = $capture; }

	if (!$act) { $act = $board_act; }

	if ($act ne $board_act) {
		carp "Action (`$act') from ply (`$ply') does not match board (space `$to' contains `$to_kind')!";
		return 0;
	}

	#
	# Effect the move:
	#
	# TODO: Deal with en passant target.
	# TODO: Detect check and checkmate for notes (and validate against those
	# passed in, if any).
	# TODO: Detect en passant capture for notes.
	# TODO: Detect en passant capture for notes.
	# TODO: Detect illegal moves based on move pattern of piece, or intervening
	# pieces, etc.
	# TODO: Detect forced for notes.
	#

	$board->at(@to, $from_piece);
	$board->at(@from, Games::Chess::Piece->new);

	#
	# Print the move:
	#

	if (!defined $notation) {
		if ($from_kind eq 'P') { $piece = ' '; }
		$notation = $piece . lc($from) . $act . lc($to) . $note;
		$notation = $notation . (' ' x (8 - length($notation)));
	}

	if ($board->player_to_move() == &WHITE) {
		print $board->move_number(), ". $notation ";

		$board->player_to_move(&BLACK);
		$board->halfmove_clock($board->halfmove_clock() + 1);
	}
	else {
		print "$notation\n";

		$board->player_to_move(&WHITE);
		$board->halfmove_clock($board->halfmove_clock() + 1);
		$board->move_number($board->move_number() + 1);
	}

	return 1;
}


#
# move()
#

sub move ($$)
{
	if (!&ply($_[0])) {
		carp "First ply (`$_[0]') of move failed.";
		return 0;
	}

	if (!&ply($_[1])) {
		carp "Second ply (`$_[1]') of move failed.";
		return 0;
	}

	return 1;
}


#
# Return success:
#

1;

#
# End of file.
#
