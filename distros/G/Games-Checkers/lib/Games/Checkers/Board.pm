# Games::Checkers, Copyright (C) 1996-2012 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

package Games::Checkers::Board;

use Games::Checkers::BoardConstants;
use Games::Checkers::Constants;
use Games::Checkers::IteratorConstants;

sub new ($;$) {
	my $class = shift;
	my $board = shift;

	my $self = {
		occup_map => 0xFFF00FFF,
		color_map => 0xFFFF0000,
		piece_map => 0x00000000,
	};
	bless $self, $class;
	$self->copy($board) if defined $board;
	return $self;
}

sub get_size ($) {
	return 8;
}

sub occup ($$) {
	my $self = shift;
	my $loc = shift;
	return $self->{occup_map} & (1 << $loc) ? 1 : 0;
}

sub color ($$) {
	my $self = shift;
	my $loc = shift;
	return $self->{color_map} & (1 << $loc) ? Black : White;
}

sub piece ($$) {
	my $self = shift;
	my $loc = shift;
	return $self->{piece_map} & (1 << $loc) ? King : Pawn;
}

sub white ($$) {
	my $self = shift;
	my $loc = shift;
	return $self->occup($loc) && $self->color($loc) == White;
}

sub black ($$) {
	my $self = shift;
	my $loc = shift;
	return $self->occup($loc) && $self->color($loc) == Black;
}

sub copy ($$) {
	my $self = shift;
	my $board = shift;

	$self->{$_} = $board->{$_} for qw(occup_map color_map piece_map);
	return $self;
}

sub clr_all ($) {
	my $self = shift;
	$self->{occup_map} = 0;
}

sub clr ($$) {
	my $self = shift;
	my $loc = shift;
	$self->{occup_map} &= ~(1 << $loc);
}

sub set ($$$$) {
	my $self = shift;
	my ($loc, $color, $type) = @_;
	$self->{occup_map} |= (1 << $loc);
	($self->{color_map} &= ~(1 << $loc)) |= ((1 << $loc) * $color);
	($self->{piece_map} &= ~(1 << $loc)) |= ((1 << $loc) * $type);
}


sub get_cost ($$) {
	my $self = shift;
	my $turn = shift;

	# Count white & black figures
	my ($white_pawns, $white_kings, $black_pawns, $black_kings) = (0) x 4;

	my $whites_iterator = new Games::Checkers::FigureIterator($self, White);
	while ($whites_iterator->left) {
		my $loc = $whites_iterator->next;
		$self->piece($loc) == Pawn ? $white_pawns++ : $white_kings++;
	}

	my $blacks_iterator = new Games::Checkers::FigureIterator($self, Black);
	while ($blacks_iterator->left) {
		my $loc = $blacks_iterator->next;
		$self->piece($loc) == Pawn ? $black_pawns++ : $black_kings++;
	}

	return -1e8 if $white_pawns + $white_kings == 0;
	return +1e8 if $black_pawns + $black_kings == 0;

	return
		+ $white_pawns * 100
		+ $white_kings * 600
		- $black_pawns * 100
		- $black_kings * 600
		+ ($turn == White ? 1 : -1);
}

sub transform ($) {
	my $self = shift;
	my $move = shift;

	my $src = $move->source;
	my $dst = $move->destin(0);
	my $beat = $move->is_beat;
	my $color = $self->color($src);
	my $piece = $self->piece($src);
	for (my $n = 0; $dst != NL; $src = $dst, $dst = $move->destin(++$n)) {
		$self->clr($src);
		$self->set($dst, $color, $piece);
		$self->clr($self->figure_between($src, $dst)) if $beat;
		# convert to king if needed
		if (convert_type->[$color][$piece] & (1 << $dst)) {
			$self->{piece_map} ^= (1 << $dst);
			$piece ^= 1;
		}
	}
}

sub can_piece_step ($$;$) {
	my $self = shift;
	my $loc = shift;
	my $locd = shift;
	$locd = NL unless defined $locd;

	if (!$self->occup($loc)) {
		warn("Internal error in can_piece_step, loc=$loc is not occupied");
		&DIE_WITH_STACK();
		return No;
	}
	my $color = $self->color($loc);
	my $step_dst = $self->piece($loc) == Pawn
		? pawn_step_iterator
		: king_step_iterator;
	$step_dst->init($loc, $color);
	while ($step_dst->left) {
		my $loc2 = $step_dst->next;
		next if $locd != NL && $locd != $loc2;
		next if $self->figure_between($loc, $loc2) != NL;
		return Yes unless $self->occup($loc2);
	}
	return No;
}

sub can_piece_beat ($$;$) {
	my $self = shift;
	my $loc = shift;
	my $locd = shift;
	$locd = NL unless defined $locd;

	if (!$self->occup($loc)) {
		warn("Internal error in can_piece_beat, loc=$loc is not occupied");
		&DIE_WITH_STACK();
		return No;
	}
	my $color = $self->color($loc);
	my $beat_dst = $self->piece($loc) == Pawn
		? pawn_beat_iterator
		: king_beat_iterator;
	$beat_dst->init($loc, $color);
	while ($beat_dst->left) {
		my $loc2 = $beat_dst->next;
		next if $locd != NL && $locd != $loc2;
		my $loc1 = $self->figure_between($loc, $loc2);
		next if $loc1 == NL || $loc1 == ML;
		return Yes unless $self->occup($loc2) ||
			!$self->occup($loc1) || $self->color($loc1) == $color;
	}
	return No;
}

sub can_color_step ($$) {
	my $self = shift;
	my $color = shift;
	my $iterator = Games::Checkers::FigureIterator->new($self, $color);
	while ($iterator->left) {
		return Yes if $self->can_piece_step($iterator->next);
	}
	return No;
}

sub can_color_beat ($$) {
	my $self = shift;
	my $color = shift;
	my $iterator = Games::Checkers::FigureIterator->new($self, $color);
	while ($iterator->left) {
		return Yes if $self->can_piece_beat($iterator->next);
	}
	return No;
}

sub can_color_move ($$) {
	my $self = shift;
	my $color = shift;
	return $self->can_color_beat($color) || $self->can_color_step($color);
}

sub figure_between ($$$) {
	my $self = shift;
	my $src = shift;
	my $dst = shift;

	for (my $drc = 0; $drc < DIRECTION_NUM; $drc++) {
		my $figures = 0;
		my $figure = NL;
		for (my $loc = loc_directions->[$src][$drc]; $loc != NL; $loc = loc_directions->[$loc][$drc]) {
			if ($loc == $dst) {
				return $figures > 1 ? ML : $figures == 1 ? $figure : NL;
			}
			if ($self->occup($loc)) {
				$figure = $loc;
				$figures++;
			}
		}
	}
	return NL;
}

#
#   +-------------------------------+
# 8 |###| @ |###| @ |###| @ |###| @ |
#   |---+---+---+---+---+---+---+---|
# 7 | @ |###| @ |###| @ |###| @ |###|
#   |---+---+---+---+---+---+---+---|
# 6 |###| @ |###| @ |###| @ |###| @ |
#   |---+---+---+---+---+---+---+---|
# 5 |   |###|   |###|   |###|   |###|
#   |---+---+---+---+---+---+---+---|
# 4 |###|   |###|   |###|   |###|   |
#   |---+---+---+---+---+---+---+---|
# 3 | O |###| O |###| O |###| O |###|
#   |---+---+---+---+---+---+---+---|
# 2 |###| O |###| O |###| O |###| O |
#   |---+---+---+---+---+---+---+---|
# 1 | O |###| O |###| O |###| O |###|
#   +-------------------------------+
#     a   b   c   d   e   f   g   h  
#

sub dump ($;$) {
	my $self = shift;
	my $prefix = shift || "";
	$prefix = "    " x $prefix if $prefix =~ /^\d+$/;

	my $char_sets = [
		{
			tlc => "+",
			trc => "+",
			blc => "+",
			brc => "+",
			vcl => "|",
			vll => "|",
			vrl => "|",
			hcl => "-",
			htl => "-",
			hbl => "-",
			ccl => "+",
			bcs => "",
			bce => "",
			bcf => " ",
			wcs => "",
			wce => "",
			wcf => "#",
		},
		{
			tlc => "\e)0\016l\017",
			trc => "\016k\017",
			blc => "\016m\017",
			brc => "\016j\017",
			vcl => "\016x\017",
			vll => "\016t\017",
			vrl => "\016u\017",
			hcl => "\016q\017",
			htl => "\016w\017",
			hbl => "\016v\017",
			ccl => "\016n\017",
			bcs => "\e[0;7m",
			bce => "\e[0m",
			bcs => "",
			bce => "",
			bcf => " ",
			wcs => "",
			wce => "",
			wcs => "\e[0;7m",
			wce => "\e[0m",
			wcf => " ",
		},
	];
	my %ch = %{$char_sets->[$ENV{DUMB_CHARS} ? 0 : 1]};

	my $size = $self->get_size;
	my $size_1 = $size - 1;
	my $size_2 = $size / 2;

	my $str = "";
	$str .= "\n";
	$str .= "  " . $ch{tlc} . ("$ch{hcl}$ch{hcl}$ch{hcl}$ch{htl}" x $size_1) . "$ch{hcl}$ch{hcl}$ch{hcl}$ch{trc}\n";
	for (my $i = 0; $i < $size; $i++) {
		$str .= ($size - $i) . " $ch{vcl}";
		for (my $j = 0; $j < $size; $j++) {
			my $is_used = ($i + $j) % 2;
			if (($i + $j) % 2) {
				my $loc = ($size_1 - $i) * $size_2 + int($j / 2);
				my $ch0 = $ch{bcf};
				my $is_king = $self->piece($loc) == King;
				$ch0 = $self->white($loc) ? $is_king ? "8" : "O" : $is_king ? "&" : "@"
					if $self->occup($loc);
				$ch0 = $self->white($loc) ? "\e[1m$ch0\e[0m" : "\e[4m$ch0\e[0m"
					if $self->occup($loc);
				$str .= "$ch{bcs}$ch{bcf}$ch0$ch{bcs}$ch{bcf}$ch{bce}";
			} else {
				$str .= "$ch{wcs}$ch{wcf}$ch{wcf}$ch{wcf}$ch{wce}";
			}
			$str .= $ch{vcl};
		}
		$str .= "\n";
		$str .= "  " . $ch{vll} . ("$ch{hcl}$ch{hcl}$ch{hcl}$ch{ccl}" x $size_1) . "$ch{hcl}$ch{hcl}$ch{hcl}$ch{vrl}\n" if $i != $size_1;
	}
	$str .= "  " . $ch{blc} . ("$ch{hcl}$ch{hcl}$ch{hcl}$ch{hbl}" x $size_1) . "$ch{hcl}$ch{hcl}$ch{hcl}$ch{brc}\n";
	$str .= "    a   b   c   d   e   f   g   h  \n";
	$str .= "\n";

	$str =~ s/^/$prefix/gm;

	return $str;
}

1;
