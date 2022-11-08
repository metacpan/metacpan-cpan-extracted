#!perl
#
# Game::Marad tests

use 5.26.0;
use Test2::V0;
use Game::Marad;

########################################################################
#
# INTERNAL FUNCTIONS
#
# _move_count

# NOTE PORTABILITY may fail if rand() rolls unlucky or rand() sucks
my $TRIALS = 10000;
my %moves;
for my $i ( 1 .. $TRIALS ) {
    $moves{Game::Marad::_move_count}++;
}
$_ = sprintf "%.2f", $_ / $TRIALS for values %moves;
is( \%moves, { 1 => 0.25, 2 => 0.25, 3 => 0.25, 4 => 0.25 } );

########################################################################
#
#_move_pushing ( $grid, $moves, $srcx, $srcy, $stepx, $stepy )

sub showboard {
    diag "BOARD";
    for my $row ( 0 .. Game::Marad::BOARD_SIZE - 1 ) {
        diag join "\t", $_[0]->[$row]->@*;
    }
}

sub newboard {
    [   [qw/0 0 0 0 0 0 0 0 0/],    # empty board
        [qw/0 0 0 0 0 0 0 0 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
    ]
}
my $board = newboard();

# on the wild assumption that only the squares expected to be modified
# are (there will be a round-up board test at the end)
$board->[0][0] = 1;
Game::Marad::_move_pushing( $board, 1, 0, 0, 1, 0 );
is [ $board->[0]->@[ 0, 1 ] ], [ 0, 0b10000001 ];

# bump against North edge
Game::Marad::_move_pushing( $board, 2, 1, 0, 0, -1 );

# back to start and West edge bump
Game::Marad::_move_pushing( $board, 3, 1, 0, -1, 0 );
is [ $board->[0]->@[ 0, 1 ] ], [ 0b10000001, 0 ];

# some things to push and a South edge bump
$board->[2][0] = 2;
$board->[4][0] = 3;
Game::Marad::_move_pushing( $board, 10, 0, 0, 0, 1 );
is [ map $_->[0], $board->@[ 0, 2, 4, 6, 7, 8 ] ],
  [ 0, 0, 0, 0b10000001, 0b10000010, 0b10000011 ];

# clear two of the pieces and a East edge bump
$board->[6][0] = $board->[7][0] = 0;
Game::Marad::_move_pushing( $board, 11, 0, 8, 1, 0 );
is [ $board->[8]->@[ 0, -1 ] ], [ 0, 0b10000011 ];

# clear last piece and check that the board is clean
$board->[8][-1] = 0;
is $board, newboard();

########################################################################
#
# _move_type

# invalid move - same cell
is [ Game::Marad::_move_type( 0, 0, 0, 0 ) ],
  [ Game::Marad::MOVE_NOPE, undef, undef ];

# invalid move - ain't no chess knights here
is [ Game::Marad::_move_type( 0, 0, 1, 2 ) ],
  [ Game::Marad::MOVE_NOPE, undef, undef ];

# valid moves, around the unit circle we go...
is [ Game::Marad::_move_type( 0, 0, 2, 0 ) ],
  [ Game::Marad::MOVE_SQUARE, 1, 0 ];

is [ Game::Marad::_move_type( 0, 0, 3, 3 ) ],
  [ Game::Marad::MOVE_DIAGONAL, 1, 1 ];

is [ Game::Marad::_move_type( 0, 0, 0, 4 ) ],
  [ Game::Marad::MOVE_SQUARE, 0, 1 ];

is [ Game::Marad::_move_type( 0, 0, -5, 5 ) ],
  [ Game::Marad::MOVE_DIAGONAL, -1, 1 ];

is [ Game::Marad::_move_type( 0, 0, -6, 0 ) ],
  [ Game::Marad::MOVE_SQUARE, -1, 0 ];

is [ Game::Marad::_move_type( 0, 0, -7, -7 ) ],
  [ Game::Marad::MOVE_DIAGONAL, -1, -1 ];

is [ Game::Marad::_move_type( 0, 0, 0, -8 ) ],
  [ Game::Marad::MOVE_SQUARE, 0, -1 ];

is [ Game::Marad::_move_type( 0, 0, 9, -9 ) ],
  [ Game::Marad::MOVE_DIAGONAL, 1, -1 ];

########################################################################
#
# OBJECTIVE TESTS

# not very random but easier to make the players score points with
my @moves = (2,4,3,3);
{
    no warnings 'redefine';
    *Game::Marad::_move_count = sub {
        state $i = 0;
        my $c = $moves[$i];
        $i = ($i + 1) % @moves;
        return $c;
    };
}

my $m = Game::Marad->new;
is $m->score, [ 0, 0 ];
is $m->turn,      0;
is $m->player,    0;
my $count = $m->move_count;
number $count;

is [ $m->move( -1, 0,  0, 0 ) ], [ 0, "out of bounds" ];
is [ $m->move( ~0, 0,  0, 0 ) ], [ 0, "out of bounds" ];
is [ $m->move( 0,  -1, 0, 0 ) ], [ 0, "out of bounds" ];
is [ $m->move( 0,  ~0, 0, 0 ) ], [ 0, "out of bounds" ];
is [ $m->move( 0,  0,  0, 0 ) ], [ 0, "not a piece" ];
is [ $m->move( 7,  1,  0, 0 ) ], [ 0, "not owner" ];
is [ $m->move( 1,  1,  1, 1 ) ], [ 0, "invalid move" ];
is [ $m->move( 1,  1,  2, 1 ) ], [ 0, "invalid move type" ];

# diagonal move into the corner has the same result regardless the
# move count
is [ $m->move( 1,  1,  0, 0 ) ], [ 1, "ok" ];
is $m->turn,      1;
is $m->player,    1;
# do we have the same move count as prior for the 2nd player?
is $m->move_count, $count;

$board = $m->board;

is [ $m->move( 7,  1,  8, 0 ) ], [ 1, "ok" ];
is $m->turn,      2;
is $m->player,    0;
is $m->score, [ 0, 0 ];

# diagonal moves into the center scoring square
is [ $m->move( 0,  0,  1, 1 ) ], [ 1, "ok" ];
is $m->score, [ 1, 0 ];
is [ $m->move( 8,  0,  7, 1 ) ], [ 1, "ok" ];
is $m->score, [ 1, 1 ];

# some other move to confirm that the score does not increase due to the
# player 2 piece sitting unmoved in the scoring square
is [ $m->move( 1,  2,  0, 2 ) ], [ 1, "ok" ];
is $m->score, [ 1, 1 ];

#showboard($board);

done_testing
