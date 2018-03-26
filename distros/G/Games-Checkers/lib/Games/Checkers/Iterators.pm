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

# ----------------------------------------------------------------------------

package Games::Checkers::LocationIterator;

use Games::Checkers::Constants;

sub new ($$%) {
	my $class = shift;
	my $board = shift || die "No board in constructor";

	my $self = { board => $board, loc => undef, @_ };

	bless $self, $class;
	$self->restart;

	return $self;
}

sub last ($) {
	my $self = shift;
	return $self->{loc};
}

sub next ($) {
	my $self = shift;
	my $old = $self->{loc};
	$self->increment;
	return $old;
}

sub left ($) {
	my $self = shift;
	return $self->{loc} != NL;
}

sub increment ($) {
	my $self = shift;
	return NL if $self->{loc} == NL;
	$self->{loc} = NL
		unless ++$self->{loc} < $self->{board}->locs;
	return $self->{loc};
}

sub restart ($) {
	my $self = shift;
	$self->{loc} = -1;
	$self->increment;
}

sub all ($) {
	my $self = shift;
	my @locations = ();
	push @locations, $self->next while $self->left;
	return @locations;
}

# ----------------------------------------------------------------------------

package Games::Checkers::FigureIterator;

use base 'Games::Checkers::LocationIterator';
use Games::Checkers::Constants;

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;

	return $class->SUPER::new($board, color => $color);
}

sub increment ($) {
	my $self = shift;
	my $loc = $self->{loc};

	return NL if $loc == NL;

	my $board = $self->{board};

	while (++$loc < $board->locs) {
		if (
			$board->occup($loc) &&
			$board->color($loc) == $self->{color}
		) {
			return $self->{loc} = $loc;
		}
	}

	return $self->{loc} = NL;
}

1;
