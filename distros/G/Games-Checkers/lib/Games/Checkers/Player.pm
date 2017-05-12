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

package Games::Checkers::Player;

use Games::Checkers::PlayerConstants;

# static method
sub create ($$$) {
	my ($type, $color, $level) = @_;
	my $class = "Games::Checkers::" . ($type == User ? "User" : "Comp") . "Player";
	return $class->new($color, $level);
}

sub new ($$$) {
	my $class = shift;
	my $color = shift;
	my $level = shift;

	my $self = {
		color => $color,
		level => $level,
		move_status => MoveDone,
	};
	return bless $self, $class;
}

sub do_move ($) { die __PACKAGE__ . ": pure virtual method is called"; }

1;
