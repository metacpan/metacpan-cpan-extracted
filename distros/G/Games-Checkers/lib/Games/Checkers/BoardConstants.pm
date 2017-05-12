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

package Games::Checkers::BoardConstants;

use constant NL => 32;

use Games::Checkers::DeclareConstant {
	MAX_LOCATION => 31,
	NL => NL,      # no location
	ML => NL + 1,  # multiple locations
	DIRECTION_NUM => 4,
	DEFAULT_LEVEL => 6,
};

use Games::Checkers::DeclareConstant loc_directions => [
	[ NL,  4, NL, NL], [  4,  5, NL, NL], [  5,  6, NL, NL], [  6,  7, NL, NL],
	[  8,  9,  0,  1], [  9, 10,  1,  2], [ 10, 11,  2,  3], [ 11, NL,  3, NL],
	[ NL, 12, NL,  4], [ 12, 13,  4,  5], [ 13, 14,  5,  6], [ 14, 15,  6,  7],
	[ 16, 17,  8,  9], [ 17, 18,  9, 10], [ 18, 19, 10, 11], [ 19, NL, 11, NL],
	[ NL, 20, NL, 12], [ 20, 21, 12, 13], [ 21, 22, 13, 14], [ 22, 23, 14, 15],
	[ 24, 25, 16, 17], [ 25, 26, 17, 18], [ 26, 27, 18, 19], [ 27, NL, 19, NL],
	[ NL, 28, NL, 20], [ 28, 29, 20, 21], [ 29, 30, 21, 22], [ 30, 31, 22, 23],
	[ NL, NL, 24, 25], [ NL, NL, 25, 26], [ NL, NL, 26, 27], [ NL, NL, 27, NL],
];

use Games::Checkers::DeclareConstant convert_type => [
	#     pawn         king
	[ 0xF0000000, 0x00000000 ],  # white
	[ 0x0000000F, 0x00000000 ],  # black
];

use Games::Checkers::DeclareConstant pawn_step => [
[
	[ NL,  4], [  4,  5], [  5,  6], [  6,  7],
	[  8,  9], [  9, 10], [ 10, 11], [ 11, NL],
	[ NL, 12], [ 12, 13], [ 13, 14], [ 14, 15],
	[ 16, 17], [ 17, 18], [ 18, 19], [ 19, NL],
	[ NL, 20], [ 20, 21], [ 21, 22], [ 22, 23],
	[ 24, 25], [ 25, 26], [ 26, 27], [ 27, NL],
	[ NL, 28], [ 28, 29], [ 29, 30], [ 30, 31],
	[ NL, NL], [ NL, NL], [ NL, NL], [ NL, NL],
], [
	[ NL, NL], [ NL, NL], [ NL, NL], [ NL, NL],
	[  0,  1], [  1,  2], [  2,  3], [  3, NL],
	[ NL,  4], [  4,  5], [  5,  6], [  6,  7],
	[  8,  9], [  9, 10], [ 10, 11], [ 11, NL],
	[ NL, 12], [ 12, 13], [ 13, 14], [ 14, 15],
	[ 16, 17], [ 17, 18], [ 18, 19], [ 19, NL],
	[ NL, 20], [ 20, 21], [ 21, 22], [ 22, 23],
	[ 24, 25], [ 25, 26], [ 26, 27], [ 27, NL],
]
];

use Games::Checkers::DeclareConstant pawn_beat => [
	[ NL,  9, NL, NL], [  8, 10, NL, NL], [  9, 11, NL, NL], [ 10, NL, NL, NL],
	[ NL, 13, NL, NL], [ 12, 14, NL, NL], [ 13, 15, NL, NL], [ 14, NL, NL, NL],
	[ NL, 17, NL,  1], [ 16, 18,  0,  2], [ 17, 19,  1,  3], [ 18, NL,  2, NL],
	[ NL, 21, NL,  5], [ 20, 22,  4,  6], [ 21, 23,  5,  7], [ 22, NL,  6, NL],
	[ NL, 25, NL,  9], [ 24, 26,  8, 10], [ 25, 27,  9, 11], [ 26, NL, 10, NL],
	[ NL, 29, NL, 13], [ 28, 30, 12, 14], [ 29, 31, 13, 15], [ 30, NL, 14, NL],
	[ NL, NL, NL, 17], [ NL, NL, 16, 18], [ NL, NL, 17, 19], [ NL, NL, 18, NL],
	[ NL, NL, NL, 21], [ NL, NL, 20, 22], [ NL, NL, 21, 23], [ NL, NL, 22, NL],
];

use Games::Checkers::DeclareConstant king_step => [
	[  4,  9, 13, 18, 22, 27, 31, NL, NL, NL, NL, NL, NL],
	[  4,  8,  5, 10, 14, 19, 23, NL, NL, NL, NL, NL, NL],
	[  5,  9, 12, 16,  6, 11, 15, NL, NL, NL, NL, NL, NL],
	[  6, 10, 13, 17, 20, 24,  7, NL, NL, NL, NL, NL, NL],
	[  8,  9, 13, 18, 22, 27, 31,  0,  1, NL, NL, NL, NL],
	[  9, 12, 16, 10, 14, 19, 23,  1,  2, NL, NL, NL, NL],
	[ 10, 13, 17, 20, 24, 11, 15,  2,  3, NL, NL, NL, NL],
	[ 11, 14, 18, 21, 25, 28,  3, NL, NL, NL, NL, NL, NL],
	[ 12, 17, 21, 26, 30,  4,  1, NL, NL, NL, NL, NL, NL],
	[ 12, 16, 13, 18, 22, 27, 31,  4,  0,  5,  2, NL, NL],
	[ 13, 17, 20, 24, 14, 19, 23,  5,  1,  6,  3, NL, NL],
	[ 14, 18, 21, 25, 28, 15,  6,  2,  7, NL, NL, NL, NL],
	[ 16, 17, 21, 26, 30,  8,  9,  5,  2, NL, NL, NL, NL],
	[ 17, 20, 24, 18, 22, 27, 31,  9,  4,  0, 10,  6,  3],
	[ 18, 21, 25, 28, 19, 23, 10,  5,  1, 11,  7, NL, NL],
	[ 19, 22, 26, 29, 11,  6,  2, NL, NL, NL, NL, NL, NL],
	[ 20, 25, 29, 12,  9,  5,  2, NL, NL, NL, NL, NL, NL],
	[ 20, 24, 21, 26, 30, 12,  8, 13, 10,  6,  3, NL, NL],
	[ 21, 25, 28, 22, 27, 31, 13,  9,  4,  0, 14, 11,  7],
	[ 22, 26, 29, 23, 14, 10,  5,  1, 15, NL, NL, NL, NL],
	[ 24, 25, 29, 16, 17, 13, 10,  6,  3, NL, NL, NL, NL],
	[ 25, 28, 26, 30, 17, 12,  8, 18, 14, 11,  7, NL, NL],
	[ 26, 29, 27, 31, 18, 13,  9,  4,  0, 19, 15, NL, NL],
	[ 27, 30, 19, 14, 10,  5,  1, NL, NL, NL, NL, NL, NL],
	[ 28, 20, 17, 13, 10,  6,  3, NL, NL, NL, NL, NL, NL],
	[ 28, 29, 20, 16, 21, 18, 14, 11,  7, NL, NL, NL, NL],
	[ 29, 30, 21, 17, 12,  8, 22, 19, 15, NL, NL, NL, NL],
	[ 30, 31, 22, 18, 13,  9,  4,  0, 23, NL, NL, NL, NL],
	[ 24, 25, 21, 18, 14, 11,  7, NL, NL, NL, NL, NL, NL],
	[ 25, 20, 16, 26, 22, 19, 15, NL, NL, NL, NL, NL, NL],
	[ 26, 21, 17, 12,  8, 27, 23, NL, NL, NL, NL, NL, NL],
	[ 27, 22, 18, 13,  9,  4,  0, NL, NL, NL, NL, NL, NL],
];

use Games::Checkers::DeclareConstant king_beat => [
	[  9, 13, 18, 22, 27, 31, NL, NL, NL],
	[  8, 10, 14, 19, 23, NL, NL, NL, NL],
	[  9, 12, 16, 11, 15, NL, NL, NL, NL],
	[ 10, 13, 17, 20, 24, NL, NL, NL, NL],
	[ 13, 18, 22, 27, 31, NL, NL, NL, NL],
	[ 12, 16, 14, 19, 23, NL, NL, NL, NL],
	[ 13, 17, 20, 24, 15, NL, NL, NL, NL],
	[ 14, 18, 21, 25, 28, NL, NL, NL, NL],
	[ 17, 21, 26, 30,  1, NL, NL, NL, NL],
	[ 16, 18, 22, 27, 31,  0,  2, NL, NL],
	[ 17, 20, 24, 19, 23,  1,  3, NL, NL],
	[ 18, 21, 25, 28,  2, NL, NL, NL, NL],
	[ 21, 26, 30,  5,  2, NL, NL, NL, NL],
	[ 20, 24, 22, 27, 31,  4,  0,  6,  3],
	[ 21, 25, 28, 23,  5,  1,  7, NL, NL],
	[ 22, 26, 29,  6,  2, NL, NL, NL, NL],
	[ 25, 29,  9,  5,  2, NL, NL, NL, NL],
	[ 24, 26, 30,  8, 10,  6,  3, NL, NL],
	[ 25, 28, 27, 31,  9,  4,  0, 11,  7],
	[ 26, 29, 10,  5,  1, NL, NL, NL, NL],
	[ 29, 13, 10,  6,  3, NL, NL, NL, NL],
	[ 28, 30, 12,  8, 14, 11,  7, NL, NL],
	[ 29, 31, 13,  9,  4,  0, 15, NL, NL],
	[ 30, 14, 10,  5,  1, NL, NL, NL, NL],
	[ 17, 13, 10,  6,  3, NL, NL, NL, NL],
	[ 16, 18, 14, 11,  7, NL, NL, NL, NL],
	[ 17, 12,  8, 19, 15, NL, NL, NL, NL],
	[ 18, 13,  9,  4,  0, NL, NL, NL, NL],
	[ 21, 18, 14, 11,  7, NL, NL, NL, NL],
	[ 20, 16, 22, 19, 15, NL, NL, NL, NL],
	[ 21, 17, 12,  8, 23, NL, NL, NL, NL],
	[ 22, 18, 13,  9,  4,  0, NL, NL, NL],
];

1;
