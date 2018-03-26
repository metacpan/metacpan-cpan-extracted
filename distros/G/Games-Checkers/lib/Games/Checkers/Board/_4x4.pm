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

package Games::Checkers::Board::_4x4;

use strict;
use warnings;

use base 'Games::Checkers::Board';
use Games::Checkers::Constants;

use constant size_x => 4;
use constant size_y => 4;
use constant locs => 8;
use constant default_rows => 1;

use constant loc_directions => [
	[ NL,  2, NL, NL ], [  2,  3, NL, NL ],
	[  4,  5,  0,  1 ], [  5, NL,  1, NL ],
	[ NL,  6, NL,  2 ], [  6,  7,  2,  3 ],
	[ NL, NL,  4,  5 ], [ NL, NL,  5, NL ],
];

use constant is_crowning => [
[
	0, 0,
	0, 0,
	0, 0,
	1, 1,
], [
	1, 1,
	0, 0,
	0, 0,
	0, 0,
]
];

use constant pawn_step => [
[
	[      2 ], [  2,  3 ],
	[  4,  5 ], [  5     ],
	[      6 ], [  6,  7 ],
	[        ], [        ],
], [
	[        ], [        ],
	[  0,  1 ], [  1     ],
	[      2 ], [  2,  3 ],
	[  4,  5 ], [  5     ],
]
];

use constant pawn_beat => [
	[      5         ], [  4             ],
	[      7         ], [  6             ],
	[              1 ], [          0     ],
	[              3 ], [          2     ],
];

use constant pawn_beat_forward => [
[
	[      5 ], [  4     ],
	[      7 ], [  6     ],
	[        ], [        ],
	[        ], [        ],
], [
	[        ], [        ],
	[        ], [        ],
	[      1 ], [  0     ],
	[      3 ], [  2     ],
]
];

use constant pawn_beat_8dirs => [
	[      5                         ], [  4                             ],
	[      7                         ], [  6                             ],
	[              1                 ], [          0                     ],
	[              3                 ], [          2                     ],
];

use constant king_step => [
	[      2,              5,              7         ],
	[  2,  3,          4                             ],
	[  4,  5,  0,  1,      7                         ],
	[  5,      1,      6                             ],
	[      6,      2,              1                 ],
	[  6,  7,  2,  3,          0                     ],
	[          4,  5,              3                 ],
	[          5,              2,              0     ],
];

use constant king_beat => [
	[      5,              7         ],
	[  4                             ],
	[      7                         ],
	[  6                             ],
	[              1                 ],
	[          0                     ],
	[              3                 ],
	[          2,              0     ],
];

use constant king_step_short => [
	[      2         ], [  2,  3         ],
	[  4,  5,  0,  1 ], [  5,      1     ],
	[      6,      2 ], [  6,  7,  2,  3 ],
	[          4,  5 ], [          5     ],
];

use constant king_beat_short => [
	[      5         ], [  4             ],
	[      7         ], [  6             ],
	[              1 ], [          0     ],
	[              3 ], [          2     ],
];

use constant king_beat_8dirs => [
	[      5,                              7                         ],
	[  4                                                             ],
	[      7                                                         ],
	[  6                                                             ],
	[              1                                                 ],
	[          0                                                     ],
	[              3                                                 ],
	[          2,                              0                     ],
];

use constant enclosed_locs => [
	{  5 => [  2 ],  7 => [  2,  5 ] },
	{  4 => [  2 ] },
	{  7 => [  5 ] },
	{  6 => [  5 ] },
	{  1 => [  2 ] },
	{  0 => [  2 ] },
	{  3 => [  5 ] },
	{  0 => [  5,  2 ],  2 => [  5 ] },
];

use constant enclosed_8dirs_locs => [
	{  5 => [  2 ],  7 => [  2,  5 ] },
	{  4 => [  2 ] },
	{  7 => [  5 ] },
	{  6 => [  5 ] },
	{  1 => [  2 ] },
	{  0 => [  2 ] },
	{  3 => [  5 ] },
	{  0 => [  5,  2 ],  2 => [  5 ] },
];

1;
