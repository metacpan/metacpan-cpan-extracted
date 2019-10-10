#!perl

use strict;
use warnings;

use Test::Most;    # test count is down at bottom

use Game::TextPatterns::Util qw(adj_4way adj_8way);

# NOTE these tests assume the points are returned in a particular order
# which may not be the case if the code changes to use a different
# method of generation

# 4-way
#   0..7 for a hypothetical 8x8 pattern
# corners
eq_or_diff([ adj_4way([ 0, 0 ], 7, 7) ], [ [ 1, 0 ], [ 0, 1 ] ]);
eq_or_diff([ adj_4way([ 7, 0 ], 7, 7) ], [ [ 6, 0 ], [ 7, 1 ] ]);
eq_or_diff([ adj_4way([ 0, 7 ], 7, 7) ], [ [ 1, 7 ], [ 0, 6 ] ]);
eq_or_diff([ adj_4way([ 7, 7 ], 7, 7) ], [ [ 6, 7 ], [ 7, 6 ] ]);

# not-corner edges
eq_or_diff([ adj_4way([ 3, 0 ], 7, 7) ], [ [ 2, 0 ], [ 4, 0 ], [ 3, 1 ] ]);
eq_or_diff([ adj_4way([ 7, 2 ], 7, 7) ], [ [ 6, 2 ], [ 7, 1 ], [ 7, 3 ] ]);
eq_or_diff([ adj_4way([ 0, 4 ], 7, 7) ], [ [ 1, 4 ], [ 0, 3 ], [ 0, 5 ] ]);
eq_or_diff([ adj_4way([ 5, 7 ], 7, 7) ], [ [ 4, 7 ], [ 6, 7 ], [ 5, 6 ] ]);

# somewhere inside
eq_or_diff([ adj_4way([ 2, 2 ], 7, 7) ],
    [ [ 1, 2 ], [ 3, 2 ], [ 2, 1 ], [ 2, 3 ] ]);

# outside the bounding box - see NOTE in Util.pm as to why this permits
# points outside said bounding box
eq_or_diff([ adj_4way([ -1, -1 ], 7, 7) ], [ [ 0, -1 ], [ -1, 0 ] ]);
eq_or_diff([ adj_4way([ 8,  8 ],  7, 7) ], [ [ 7, 8 ],  [ 8,  7 ] ]);

# 8-way
#   0..7 for a hypothetical 8x8 pattern
# corners
eq_or_diff([ adj_8way([ 0, 0 ], 7, 7) ], [ [ 1, 0 ], [ 0, 1 ], [ 1, 1 ] ]);
eq_or_diff([ adj_8way([ 7, 0 ], 7, 7) ], [ [ 6, 0 ], [ 7, 1 ], [ 6, 1 ] ]);
eq_or_diff([ adj_8way([ 0, 7 ], 7, 7) ], [ [ 1, 7 ], [ 0, 6 ], [ 1, 6 ] ]);
eq_or_diff([ adj_8way([ 7, 7 ], 7, 7) ], [ [ 6, 7 ], [ 7, 6 ], [ 6, 6 ] ]);

# not-corner edges
eq_or_diff([ adj_8way([ 3, 0 ], 7, 7) ],
    [ [ 2, 0 ], [ 4, 0 ], [ 3, 1 ], [ 2, 1 ], [ 4, 1 ] ]);
eq_or_diff([ adj_8way([ 7, 2 ], 7, 7) ],
    [ [ 6, 2 ], [ 7, 1 ], [ 7, 3 ], [ 6, 1 ], [ 6, 3 ] ]);
eq_or_diff([ adj_8way([ 0, 4 ], 7, 7) ],
    [ [ 1, 4 ], [ 0, 3 ], [ 0, 5 ], [ 1, 3 ], [ 1, 5 ] ]);
eq_or_diff([ adj_8way([ 5, 7 ], 7, 7) ],
    [ [ 4, 7 ], [ 6, 7 ], [ 5, 6 ], [ 4, 6 ], [ 6, 6 ] ]);

# somewhere inside
eq_or_diff(
    [ adj_8way([ 2, 2 ], 7, 7) ],
    [   [ 1, 2 ], [ 3, 2 ], [ 2, 1 ], [ 2, 3 ],
        [ 1, 1 ], [ 1, 3 ], [ 3, 1 ], [ 3, 3 ]
    ]
);

done_testing 20
