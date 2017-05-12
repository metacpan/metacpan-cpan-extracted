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

use Games::Checkers::BoardConstants;

sub new ($@) {
	my $class = shift;

	my $self = { loc => undef, @_ };

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
	$self->{loc} = $self->increment;
	return $old;
}

sub left ($) {
	my $self = shift;
	return $self->{loc} != NL;
}

sub increment ($) {
	my $self = shift;
	$self->{loc} == NL ? NL : ++$self->{loc};
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

package Games::Checkers::PieceRuleIterator;

use base 'Games::Checkers::LocationIterator';
use Games::Checkers::BoardConstants;

sub new ($;$$) {
	my $class = shift;

	my $self = $class->SUPER::new;
	$self->init(@_) if @_;
	return $self;
}

sub increment ($) {
	my $self = shift;

	my $loc = NL;
	while ($loc == NL && $self->{dnx} < $self->destinations) {
		$loc = $self->get_location($self->{dnx}++);
	}
	return $self->{loc} = $loc;
}

sub restart ($) {
	my $self = shift;
	return unless defined $self->{src};
	$self->{dnx} = 0;
	$self->SUPER::restart;
}

sub init ($$$) {
	my $self = shift;
	my $src = shift;
	my $color = shift;

	$self->{src} = $src;
	$self->{color} = $color;
	$self->restart;
}

# ----------------------------------------------------------------------------

package Games::Checkers::PawnStepIterator;

use base 'Games::Checkers::PieceRuleIterator';
use Games::Checkers::BoardConstants;

sub destinations ($) { 2 }

sub get_location ($$) { pawn_step->[$_[0]->{color}][$_[0]->{src}][$_[1]]; }

# ----------------------------------------------------------------------------

package Games::Checkers::PawnBeatIterator;

use base 'Games::Checkers::PieceRuleIterator';
use Games::Checkers::BoardConstants;

sub destinations ($) { 4 }

sub get_location ($$) { pawn_beat->[$_[0]->{src}][$_[1]]; }

# ----------------------------------------------------------------------------

package Games::Checkers::KingStepIterator;

use base 'Games::Checkers::PieceRuleIterator';
use Games::Checkers::BoardConstants;

sub destinations ($) { 13 }

sub get_location ($$) { king_step->[$_[0]->{src}][$_[1]]; }

# ----------------------------------------------------------------------------

package Games::Checkers::KingBeatIterator;

use base 'Games::Checkers::PieceRuleIterator';
use Games::Checkers::BoardConstants;

sub destinations ($) { 9 }

sub get_location ($$) { king_beat->[$_[0]->{src}][$_[1]]; }

# ----------------------------------------------------------------------------

package Games::Checkers::Iterators;

# globals, so that we don't need to create these all the time, just init()
use constant pawn_step_iterator => Games::Checkers::PawnStepIterator->new;
use constant pawn_beat_iterator => Games::Checkers::PawnBeatIterator->new;
use constant king_step_iterator => Games::Checkers::KingStepIterator->new;
use constant king_beat_iterator => Games::Checkers::KingBeatIterator->new;

# ----------------------------------------------------------------------------

package Games::Checkers::ValidKingBeatIterator;

use base 'Games::Checkers::PieceRuleIterator';
use Games::Checkers::BoardConstants;

sub destinations ($) { 9 }

sub get_location ($$) { king_beat->[$_[0]->{src}][$_[1]]; }

# ----------------------------------------------------------------------------

package Games::Checkers::FigureIterator;

use base 'Games::Checkers::LocationIterator';
use Games::Checkers::BoardConstants;

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;

	return $class->SUPER::new(board => $board, color => $color);
}

sub increment ($) {
	my $self = shift;
	my $loc = $self->{loc};
	return NL if $loc == NL;
	while (++$loc != NL && (
		!$self->{board}->occup($loc) ||
		$self->{board}->color($loc) != $self->{color})) {}
	return $self->{loc} = $loc;
}

1;
