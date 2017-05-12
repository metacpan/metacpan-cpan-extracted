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

use base 'Games::Checkers::Board';
use Games::Checkers::Constants;
use Games::Checkers::BoardConstants;
use Games::Checkers::MoveConstants;

use constant MAX_MOVE_JUMP_NUM => 9;

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;

	my $self = $class->SUPER::new($board);
	my $fields = {
		color => $color,
		destin => [],
		src => NL,
		piece => 0,
		must_beat => $board->can_color_beat($color),
		orig_board => $board,
	};
	$self->{$_} = $fields->{$_} foreach keys %$fields;
	return $self;
}
	
sub init ($) {
	my $self = shift;
	$self->{destin} = [];
	$self->{src} = NL;
	$self->copy($self->{orig_board});
}

sub source ($$) {
	my $self = shift;
	my $loc = shift;
	$self->init;
	return Err if $loc == NL || !$self->occup($loc) || $self->color($loc) != $self->{color};
	return Err if $self->{must_beat} && !$self->can_piece_beat($loc) || !$self->{must_beat} && !$self->can_piece_step($loc);
	$self->{piece} = $self->piece($self->{src} = $loc);
	return Ok;
}

sub add_dst ($$) {
	my $self = shift;
	my $dst = shift;
	return Err if $self->{src} == NL || @{$self->{destin}} == MAX_MOVE_JUMP_NUM-1;
	if ($self->{must_beat}) {
		die "Internal" unless $self->occup($self->dst_1);
		return Err unless $self->can_piece_beat($self->dst_1, $dst);
	} else {
		return Err if @{$self->{destin}} > 0;
		return Err unless $self->can_piece_step($self->{src}, $dst);
	}
	push @{$self->{destin}}, $dst;
	$self->transform_one;
	return Ok;
}

sub del_dst ($) {
	my $self = shift;
	return NL if $self->{src} == NL || @{$self->{destin}} == 0;
	my $dst = pop @{$self->{destin}};
	$self->transform_all;
	return $dst;
}

sub can_create_move ($) {
	my $self = shift;
	return $self->{must_beat} && @{$self->{destin}} > 0
		&& $self->can_piece_beat($self->dst_1) == No
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

sub transform_one ($) {
	my $self = shift;
	my $src = $self->dst_2;
	my $dst = $self->dst_1;
	$self->clr($src);
	$self->set($dst, $self->{color}, $self->{piece});
	$self->clr($self->figure_between($src, $dst)) if $self->{must_beat};
	if (convert_type->[$self->{color}][$self->{piece}] & (1 << $dst)) {
		$self->{piece_map} ^= (1 << $dst);
		$self->{piece} ^= 1;
	}
}

sub transform_all ($) {
	my $self = shift;
	$self->copy($self->{orig_board});
	return if $self->{src} == NL || @{$self->{destin}} == 0;
	$self->{piece} = $self->piece($self->{src});
	my $destin = $self->{destin};
	$self->{destin} = [];
	while (@$destin) {
		push @{$self->{destin}}, shift @$destin;
		$self->transform_one;
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
