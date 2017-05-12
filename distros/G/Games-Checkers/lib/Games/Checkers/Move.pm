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

package Games::Checkers::Move;

use Games::Checkers::BoardConstants;
use Games::Checkers::LocationConversions;

sub new ($$$$) {
	my $class = shift;
	my ($is_beat, $src, $dsts) = @_;

	die "Games::Checkers::Move constructor, third arg should be array"
		unless ref($dsts) eq 'ARRAY';
	die "No destinations in Move construction" unless $src == NL || @$dsts;
	my $self = [ $is_beat, $src, [@$dsts] ];

	bless $self, $class;
	return $self;
}

use constant NoMove => Games::Checkers::Move->new(0, NL, []);

sub num_steps ($) {
	my $self = shift;
	return scalar @{$self->[2]};
}

sub is_beat ($) {
	my $self = shift;
	return $self->[0];
}

sub source ($) {
	my $self = shift;
	return $self->[1];
}

sub destin ($$) {
	my $self = shift;
	my $num = shift;
	return $num < 0 || $num >= @{$self->[2]} ? NL : $self->[2]->[$num];
}

sub clone ($) {
	my $self = shift;
	return Games::Checkers::Move->new(@$self);
}

sub dump ($) {
	my $self = shift;
	my $delim = $self->is_beat ? ":" : "-";
	my $str = location_to_str($self->source);
	for (my $i = 0; $i < $self->num_steps; $i++) {
		$str .= $delim . location_to_str($self->destin($i));
	}
	return $str;
}

1;
