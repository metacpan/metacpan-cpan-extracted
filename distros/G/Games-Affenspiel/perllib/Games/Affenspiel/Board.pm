# Games::Affenspiel library, Copyright (C) 2006 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

package Games::Affenspiel::Board;

use strict;
use warnings;

my $is_pipe = !-t STDOUT;

use constant {
	GAP     => 0,
	SQUARE1 => 1,
	VER_BAR => 2,
	HOR_BAR => 3,
	SQUARE2 => 4,
};

use constant {
	UN => 'O',
	V1 => 'A',
	V2 => 'V',
	H1 => '<',
	H2 => '>',
	S1 => '/',
	S2 => '\\',
	S3 => '[',
	S4 => ']',
	GP => ' ',
	IN => '?',
};

my $policy = 0;

sub set_policy ($) {
	$policy = shift || 0;
}

sub new ($;$) {
	my $class = shift;
	my $num = shift;

	return bless([], $class)->reset($num);
}

sub clone ($) {
	my $self = shift;

	my $new_board = ref($self)->new;
	$new_board->[$_] = [ @{$self->[$_]} ] for 0 .. 4;

	return $new_board;
}

sub reset ($;$) {
	my $self = shift;
	my $num = shift || 0;

	if ($num == 1) {
		$self->[0] = [ GP, S1, S2, GP, ];
		$self->[1] = [ GP, S3, S4, GP, ];
		$self->[2] = [ GP, GP, GP, GP, ];
		$self->[3] = [ GP, GP, GP, GP, ];
		$self->[4] = [ GP, GP, GP, GP, ];
	}
	elsif ($num == 2) {
		$self->[0] = [ V1, S1, S2, V1, ];
		$self->[1] = [ V2, S3, S4, V2, ];
		$self->[2] = [ GP, H1, H2, GP, ];
		$self->[3] = [ UN, H1, H2, UN, ];
		$self->[4] = [ UN, H1, H2, UN, ];
	}
	else {
		$self->[0] = [ V1, S1, S2, V1, ];
		$self->[1] = [ V2, S3, S4, V2, ];
		$self->[2] = [ GP, H1, H2, GP, ];
		$self->[3] = [ V1, UN, UN, V1, ];
		$self->[4] = [ V2, UN, UN, V2, ];
	}

	return $self;
}

sub is_final ($) {
	my $self = shift;

	return
		$self->get_cell_at([4, 1]) eq S3 &&
		$self->get_cell_at([4, 2]) eq S4;
}

sub show ($) {
	my $self = shift;

	my $plain_ascii = $is_pipe || $ENV{DUMB_CHARS} || !$ENV{TERM};

	my $v  = $plain_ascii ? '|' : "\cNx\cO";
	my $h  = $plain_ascii ? '-' : "\cNq\cO";
	my $ul = $plain_ascii ? '+' : "\cNl\cO";
	my $ur = $plain_ascii ? '+' : "\cNk\cO";
	my $dl = $plain_ascii ? '+' : "\cNm\cO";
	my $dr = $plain_ascii ? '+' : "\cNj\cO";

	print "$ul$h$h$h$h$ur\n";
	foreach my $row (@$self) {
		print "$v";
		print $_ for @$row;
		print "$v\n";
	}
	print "$dl$h$h$h$h$dr\n";

	return $self;
}

sub hash ($) {
	my $self = shift;

	return join('', map { map { my $v = $self->get_bar_by_first_cell($_); defined $v ? $v : '' } @$_ } @$self);
}

sub hash2 ($) {
	my $self = shift;

	return join('', map { map { $self->get_bar_by_cell($_) } @$_ } @$self);
}

sub stringify_position ($) {
	my $self = shift;
	my $position = shift;

	return '[' . join(', ', @$position) . ']';
}

sub get_cell_at ($$) {
	my $self = shift;
	my $position = shift;

	return IN
		if $position->[0] < 0 || $position->[1] < 0
		|| !$self->[$position->[0]];
	return $self->[$position->[0]]->[$position->[1]] || IN;
}

sub set_cell_at ($$$) {
	my $self = shift;
	my $position = shift;
	my $value = shift;

	die "Incorrect setting out of board at position "
		. $self->stringify_position($position) . "\n"
		unless $self->[$position->[0]]->[$position->[1]];

	return $self->[$position->[0]]->[$position->[1]] = $value;
}

sub get_gap_positions ($) {
	my $self = shift;

	my @gap_positions;
	for my $y (0 .. 4) {
		for my $x (0 .. 3) {
			push @gap_positions, [ $y, $x ] if $self->[$y][$x] eq GP;
		}
	}

	return @gap_positions;
}

sub is_adjacent_positions ($$$) {
	my $self = shift;
	my $position1 = shift;
	my $position2 = shift;

	my ($y1, $x1) = @$position1;
	my ($y2, $x2) = @$position2;

	return
		$x1 == $x2 && abs($y1 - $y2) == 1 ? 'v' :
		$y1 == $y2 && abs($x1 - $x2) == 1 ? 'h' :
		undef;
}

sub is_ver ($) {
	my $self = shift;
	my $direction = shift;

	return $direction eq 'u' || $direction eq 'd';
}

sub is_hor ($) {
	my $self = shift;
	my $direction = shift;

	return $direction eq 'l' || $direction eq 'r';
}

sub apply_direction ($$$;$) {
	my $self = shift;
	my $position = shift;
	my $direction = shift;
	my $reverse = shift || 0;

	my $position2 = [ @$position ];

	$position2->[0]-- if $direction eq ($reverse ? 'd' : 'u');
	$position2->[0]++ if $direction eq ($reverse ? 'u' : 'd');
	$position2->[1]-- if $direction eq ($reverse ? 'r' : 'l');
	$position2->[1]++ if $direction eq ($reverse ? 'l' : 'r');

	return $position2;
}

sub get_bar_by_cell ($$) {
	my $self = shift;
	my $cell = shift;

	return SQUARE1 if $cell eq UN;
	return VER_BAR if $cell eq V1 || $cell eq V2;
	return HOR_BAR if $cell eq H1 || $cell eq H2;
	return SQUARE2 if $cell eq S1 || $cell eq S2 || $cell eq S3 || $cell eq S4;
	return GAP     if $cell eq GP;
	return undef;
}

sub get_bar_by_first_cell ($$) {
	my $self = shift;
	my $cell = shift;

	return SQUARE1 if $cell eq UN;
	return VER_BAR if $cell eq V1;
	return HOR_BAR if $cell eq H1;
	return SQUARE2 if $cell eq S1;
	return GAP     if $cell eq GP;
	return undef;
}

sub move ($$$) {
	my $self = shift;
	my $gap1_position = shift;
	my $direction = shift;

	return undef unless $self->get_cell_at($gap1_position) eq GP;

	my $bar1_position = $self->apply_direction($gap1_position, $direction, 1);
	my $bar1_cell = $self->get_cell_at($bar1_position);
	my $bar = $self->get_bar_by_cell($bar1_cell);
	return undef unless $bar;

	if ($bar == SQUARE1) {
		$self->set_cell_at($gap1_position, UN);
		$self->set_cell_at($bar1_position, GP);
	}
	elsif ($bar == VER_BAR) {
		if ($self->is_hor($direction)) {
			my $alt_direction = $bar1_cell eq V1 ? 'd' : 'u';
			my $gap2_position = $self->apply_direction($gap1_position, $alt_direction);
			my $bar2_position = $self->apply_direction($bar1_position, $alt_direction);
			return undef unless $self->get_cell_at($gap2_position) eq GP;
			my $bar2_cell = $self->get_cell_at($bar2_position);
			return undef unless $self->get_bar_by_cell($bar2_cell) eq VER_BAR;
			$self->set_cell_at($gap1_position, $bar1_cell);
			$self->set_cell_at($gap2_position, $bar2_cell);
			$self->set_cell_at($bar1_position, GP);
			$self->set_cell_at($bar2_position, GP);
		} else {
			my $bar2_position = $self->apply_direction($bar1_position, $direction, 1);
			my $bar2_cell = $self->get_cell_at($bar2_position);
			$self->set_cell_at($gap1_position, $bar1_cell);
			$self->set_cell_at($bar1_position, $bar2_cell);
			$self->set_cell_at($bar2_position, GP);
		}
	}
	elsif ($bar == HOR_BAR) {
		if ($self->is_ver($direction)) {
			my $alt_direction = $bar1_cell eq H1 ? 'r' : 'l';
			my $gap2_position = $self->apply_direction($gap1_position, $alt_direction);
			my $bar2_position = $self->apply_direction($bar1_position, $alt_direction);
			return undef unless $self->get_cell_at($gap2_position) eq GP;
			my $bar2_cell = $self->get_cell_at($bar2_position);
			return undef unless $self->get_bar_by_cell($bar2_cell) eq HOR_BAR;
			$self->set_cell_at($gap1_position, $bar1_cell);
			$self->set_cell_at($gap2_position, $bar2_cell);
			$self->set_cell_at($bar1_position, GP);
			$self->set_cell_at($bar2_position, GP);
		} else {
			my $bar2_position = $self->apply_direction($bar1_position, $direction, 1);
			my $bar2_cell = $self->get_cell_at($bar2_position);
			$self->set_cell_at($gap1_position, $bar1_cell);
			$self->set_cell_at($bar1_position, $bar2_cell);
			$self->set_cell_at($bar2_position, GP);
		}
	}
	elsif ($bar == SQUARE2) {
		my $alt_direction = $self->is_ver($direction)
			? $bar1_cell eq S1 ? 'r' : $bar1_cell eq S2 ? 'l' : $bar1_cell eq S3 ? 'r' : 'l'
			: $bar1_cell eq S1 ? 'd' : $bar1_cell eq S2 ? 'd' : $bar1_cell eq S3 ? 'u' : 'u';
		my $gap2_position = $self->apply_direction($gap1_position, $alt_direction);
		my $bar2_position = $self->apply_direction($bar1_position, $alt_direction);
		my $bar3_position = $self->apply_direction($bar1_position, $direction, 1);
		my $bar4_position = $self->apply_direction($bar2_position, $direction, 1);
		return undef unless $self->get_cell_at($gap2_position) eq GP;
		my $bar2_cell = $self->get_cell_at($bar2_position);
		my $bar3_cell = $self->get_cell_at($bar3_position);
		my $bar4_cell = $self->get_cell_at($bar4_position);
		return undef unless $self->get_bar_by_cell($bar2_cell) eq SQUARE2;
		$self->set_cell_at($gap1_position, $bar1_cell);
		$self->set_cell_at($gap2_position, $bar2_cell);
		$self->set_cell_at($bar1_position, $bar3_cell);
		$self->set_cell_at($bar2_position, $bar4_cell);
		$self->set_cell_at($bar3_position, GP);
		$self->set_cell_at($bar4_position, GP);
	}

	print "$direction -> ", $self->stringify_position($gap1_position), "\n"
		if $ENV{DEBUG_MOVES};

	return $bar;
}

sub choose_random_move ($) {
	my $self = shift;

	my @gap_positions = $self->get_gap_positions;
	my ($bar, $gap_position, $direction);

	until (defined($bar = $self->move(
		$gap_position = $gap_positions[int(rand(scalar @gap_positions))],
		$direction = ['u', 'd', 'l', 'r']->[int(rand(4))]
	))) {}

	return ($bar, $gap_position, $direction);
}

sub expand_valid_moves ($) {
	my $self = shift;

	my @gap_positions = $self->get_gap_positions;
	my @move_infos = ();
	my $included_boards = {};

	for my $gap_position (@gap_positions) {
		for my $direction ('u', 'd', 'l', 'r') {
			my $board = $self->clone;
			my $bar = $board->move($gap_position, $direction);
			next unless $bar;
			my $hash = $board->hash;
			next if $included_boards->{$hash};
			$included_boards->{$hash} = 1;
			push @move_infos, [ $bar, $gap_position, $direction, $board ];
		}
	}

	@move_infos = sort { $b->[0] <=> $a->[0] } @move_infos
		if $policy == 2 || $policy == 3;
	@move_infos = reverse @move_infos
		if $policy == 1 || $policy == 3;
	@move_infos = sort { rand(2) < 1 ? 1 : -1 } @move_infos
		if $policy == -1;

	return \@move_infos;
}

1;
