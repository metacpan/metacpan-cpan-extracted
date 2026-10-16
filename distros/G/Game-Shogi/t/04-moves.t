use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

# A board with the pieces given and nothing else, no kings, so every
# pseudo-legal move is legal. `side` is who is to move.
sub board {
    my ($side, %piece) = @_;
    my $b = $E->new(empty => 1);
    $b->put($E->square($_), $piece{$_}) for keys %piece;
    $b->set_side_to_move($side);
    return $b;
}

sub moves_of { my ($b) = @_; [ sort $b->board_moves ] }

# ---- each kind from 5e, Black ---------------------------------------------------------
#
# Worked by hand from W's movement section. Black's zone is ranks a to c, and
# a move that touches it may promote; a pawn or lance onto rank a, or a knight
# onto a or b, must.

my %BLACK = (
    P  => [qw(5e5d)],
    L  => [qw(5e5d 5e5c+ 5e5c 5e5b+ 5e5b 5e5a+)],
    N  => [qw(5e4c+ 5e4c 5e6c+ 5e6c)],
    S  => [qw(5e5d 5e4d 5e6d 5e4f 5e6f)],
    G  => [qw(5e5d 5e4d 5e6d 5e4e 5e6e 5e5f)],
    K  => [qw(5e5d 5e4d 5e6d 5e4e 5e6e 5e5f 5e4f 5e6f)],
    B  => [qw(5e4d 5e3c+ 5e3c 5e2b+ 5e2b 5e1a+ 5e1a
              5e6d 5e7c+ 5e7c 5e8b+ 5e8b 5e9a+ 5e9a
              5e4f 5e3g 5e2h 5e1i 5e6f 5e7g 5e8h 5e9i)],
    R  => [qw(5e5d 5e5c+ 5e5c 5e5b+ 5e5b 5e5a+ 5e5a
              5e5f 5e5g 5e5h 5e5i
              5e4e 5e3e 5e2e 5e1e 5e6e 5e7e 5e8e 5e9e)],
);
$BLACK{$_} = $BLACK{G} for qw(+P +L +N +S);
$BLACK{'+B'} = [ (grep { !/\+$/ } @{ $BLACK{B} }), qw(5e5d 5e5f 5e4e 5e6e) ];
$BLACK{'+R'} = [ (grep { !/\+$/ } @{ $BLACK{R} }), qw(5e4d 5e6d 5e4f 5e6f) ];

for my $t (sort keys %BLACK) {
    is_deeply(moves_of(board('b', '5e' => $t)), [ sort @{ $BLACK{$t} } ],
        sprintf('Black %-2s on 5e: %d moves', $t, scalar @{ $BLACK{$t} }));
}

# ---- and White, whose forward is towards rank i -------------------------------------

my %WHITE = (
    p  => [qw(5e5f)],
    l  => [qw(5e5f 5e5g+ 5e5g 5e5h+ 5e5h 5e5i+)],
    n  => [qw(5e4g+ 5e4g 5e6g+ 5e6g)],
    s  => [qw(5e5f 5e4f 5e6f 5e4d 5e6d)],
    g  => [qw(5e5f 5e4f 5e6f 5e4e 5e6e 5e5d)],
);
$WHITE{$_} = $WHITE{g} for qw(+p +l +n +s);
for my $t (sort keys %WHITE) {
    is_deeply(moves_of(board('w', '5e' => $t)), [ sort @{ $WHITE{$t} } ],
        sprintf('White %-2s on 5e: %d moves', $t, scalar @{ $WHITE{$t} }));
}
my %WHITE_COUNT = (k => 8, b => 22, r => 19, '+b' => 20, '+r' => 20);
is(scalar(@{ moves_of(board('w', '5e' => $_)) }), $WHITE_COUNT{$_}, "White $_ on 5e: $WHITE_COUNT{$_} moves")
    for sort keys %WHITE_COUNT;

# ---- the edges --------------------------------------------------------------------

is_deeply(moves_of(board('b', '1e' => 'N')), [qw(1e2c 1e2c+)], 'a knight on file 1 jumps one way only, and never wraps');
is_deeply(moves_of(board('b', '9e' => 'N')), [qw(9e8c 9e8c+)], 'nor on file 9');
is_deeply(moves_of(board('b', '1i' => 'K')), [qw(1i1h 1i2h 1i2i)], 'a king in the corner has three');
is_deeply(moves_of(board('w', '9a' => 'l')), [ sort qw(9a9b 9a9c 9a9d 9a9e 9a9f 9a9g+ 9a9g 9a9h+ 9a9h 9a9i+) ],
    "White's lance from 9a runs the whole file");

# ---- the pawn takes straight ahead ----------------------------------------------------

is_deeply(moves_of(board('b', '5e' => 'P', '5d' => 'p')), ['5e5d'], 'the pawn takes the piece straight ahead of it');
is_deeply(moves_of(board('b', '5e' => 'P', '4d' => 'p', '6d' => 'p')), ['5e5d'],
    'and NOT diagonally: it is not chess\'s pawn');
is_deeply([ grep { /^5e/ } board('b', '5e' => 'P', '5d' => 'G')->board_moves ], [], 'a pawn behind its own gold has no move');

# ---- slides stop -------------------------------------------------------------------

{
    my $b = board('b', '5e' => 'R', '5c' => 'P', '5g' => 'p', '3e' => 'G', '7e' => 'g');
    my @rook = sort grep { /^5e/ } $b->board_moves;
    is_deeply(\@rook, [ sort qw(5e5d 5e5f 5e5g 5e4e 5e6e 5e7e) ],
        'a rook stops before its own piece, and on a rival it takes');
}

# ---- the zone ----------------------------------------------------------------------

is_deeply(moves_of(board('b', '4c' => 'S')), [ sort qw(4c4b+ 4c4b 4c3b+ 4c3b 4c5b+ 4c5b 4c3d+ 4c3d 4c5d+ 4c5d) ],
    'a silver in the zone may promote going deeper, and going OUT of it too');
is_deeply(moves_of(board('b', '4d' => 'S')), [ sort qw(4d4c+ 4d4c 4d3c+ 4d3c 4d5c+ 4d5c 4d3e 4d5e) ],
    'a silver going INTO the zone may promote; going back from outside it may not');
is_deeply(moves_of(board('b', '4b' => 'S')), [ sort qw(4b4a+ 4b4a 4b3a+ 4b3a 4b5a+ 4b5a 4b3c+ 4b3c 4b5c+ 4b5c) ],
    'a silver is never made to promote, even on the last rank');
is_deeply(moves_of(board('w', '6g' => 's')), [ sort qw(6g6h+ 6g6h 6g5h+ 6g5h 6g7h+ 6g7h 6g5f+ 6g5f 6g7f+ 6g7f) ],
    "White's zone is ranks g to i, and the same rule holds");

# ---- forced promotion ----------------------------------------------------------------

is_deeply(moves_of(board('b', '5b' => 'P')), ['5b5a+'], 'a pawn onto the last rank must promote');
is_deeply(moves_of(board('b', '5d' => 'P')), [ sort qw(5d5c+ 5d5c) ], 'a pawn into the zone may');
is_deeply(moves_of(board('b', '5c' => 'L')), [ sort qw(5c5b+ 5c5b 5c5a+) ], 'a lance onto the last rank must; onto the next it may');
is_deeply(moves_of(board('b', '5d' => 'N')), [ sort qw(5d4b+ 5d6b+) ], 'a knight onto the second rank must promote');
is_deeply(moves_of(board('b', '5c' => 'N')), [ sort qw(5c4a+ 5c6a+) ], 'and onto the last');
is_deeply(moves_of(board('w', '5h' => 'p')), ['5h5i+'], "White's pawn onto rank i must");
is_deeply(moves_of(board('w', '5f' => 'n')), [ sort qw(5f4h+ 5f6h+) ], "White's knight onto rank h must");

# ---- what never promotes -----------------------------------------------------------

ok(!(grep { /\+$/ } $_->board_moves), 'no + in ' . $_->sfen) for
    board('b', '5c' => 'G'), board('b', '5c' => 'K'), board('b', '5c' => '+P'),
    board('b', '5c' => '+S'), board('b', '5c' => '+B'), board('b', '5c' => '+R');

done_testing();
