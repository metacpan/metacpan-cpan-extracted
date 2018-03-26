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

package Games::Checkers::MoveLocationConstructor;

use Games::Checkers::Constants;
use Games::Checkers::Board;
use Games::Checkers::MoveConstants;

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;

	my $self = {
		color => $color,
		destin => [],
		src => NL,
		piece => 0,
		must_beat => $board->can_color_beat($color),
		orig_board => $board,
	};
	bless $self, $class;

	return $self;
}
	
sub init_work_board ($) {
	my $self = shift;

	return $self->{work_board}
		? $self->{work_board}->copy($self->{orig_board})
		: ($self->{work_board} = $self->{orig_board}->clone);
}

sub source ($$) {
	my $self = shift;
	my $loc = shift;

	my $board = $self->{orig_board};
	return Err
		if $loc == NL
		|| !$board->occup($loc)
		|| $board->color($loc) != $self->{color}
		||  $self->{must_beat} && !$board->can_piece_beat($loc)
		|| !$self->{must_beat} && !$board->can_piece_step($loc);

	$self->{piece} = $board->piece($self->{src} = $loc);
	$self->{destin} = [];
	$self->init_work_board;

	return Ok;
}

sub add_dst ($$) {
	my $self = shift;
	my $dst = shift;

	return Err if $self->{src} == NL || @{$self->{destin}} == 100;

	my $board = $self->{work_board} or die "Internal";
	if ($self->{must_beat}) {
		die "Internal" unless $board->occup($self->dst_1);
		return Err unless $board->can_piece_beat($self->dst_1, $dst);
	} else {
		return Err if @{$self->{destin}} > 0;
		return Err unless $board->can_piece_step($self->{src}, $dst);
	}
	push @{$self->{destin}}, $dst;
	$self->apply_last_dst;

	return Ok;
}

sub del_dst ($) {
	my $self = shift;
	return NL if $self->{src} == NL || @{$self->{destin}} == 0;
	my $dst = pop @{$self->{destin}};
	$self->reapply_all;
	return $dst;
}

sub can_create_move ($) {
	my $self = shift;
	return $self->{must_beat} && @{$self->{destin}} > 0
		&& $self->{work_board}->can_piece_beat($self->dst_1) == No
		|| !$self->{must_beat} && @{$self->{destin}} == 1;
}

sub create_move ($) {
	my $self = shift;
	return NO_MOVE	if $self->{src} == NL
		|| $self->{must_beat} && @{$self->{destin}} < 1
		|| !$self->{must_beat} && @{$self->{destin}} != 1;
	return new Games::Checkers::Move(
		$self->{must_beat}, $self->{src}, $self->{destin});
}

sub apply_last_dst ($) {
	my $self = shift;

	my $board = $self->{work_board};
	my $src = $self->dst_2;
	my $dst = $self->dst_1;
	$board->clr($src);
	$board->set($dst, $self->{color}, $self->{piece});
	$board->clr($board->enclosed_figure($src, $dst)) if $self->{must_beat};
	if ($self->{piece} == Pawn && $board->is_crowning->[$self->{color}][$dst]) {
		$board->cnv($dst);
		$self->{piece} ^= 1;
	}
}

sub reapply_all ($) {
	my $self = shift;

	my $board = $self->init_work_board;
	return if $self->{src} == NL || @{$self->{destin}} == 0;

	$self->{piece} = $board->piece($self->{src});
	my $destin = $self->{destin};
	$self->{destin} = [];
	while (@$destin) {
		push @{$self->{destin}}, shift @$destin;
		$self->apply_last_dst;
	}
}

sub dst_1 ($) {
	my $self = shift;
	return @{$self->{destin}} == 0 ? $self->{src} : $self->{destin}->[-1];
}

sub dst_2 ($) {
	my $self = shift;
	return @{$self->{destin}} == 1 ? $self->{src} : $self->{destin}->[-2];
}

1;
