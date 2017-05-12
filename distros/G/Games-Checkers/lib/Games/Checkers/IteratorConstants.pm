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

package Games::Checkers::IteratorConstants;

use Games::Checkers::Iterators;

use Games::Checkers::DeclareConstant {
	pawn_step_iterator => Games::Checkers::Iterators::pawn_step_iterator,
	pawn_beat_iterator => Games::Checkers::Iterators::pawn_beat_iterator,
	king_step_iterator => Games::Checkers::Iterators::king_step_iterator,
	king_beat_iterator => Games::Checkers::Iterators::king_beat_iterator,
};

1;
