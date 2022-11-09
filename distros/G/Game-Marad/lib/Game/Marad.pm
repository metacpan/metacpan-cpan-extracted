# -*- Perl -*-

package Game::Marad 0.04;
use 5.26.0;
use Object::Pad 0.52;
class Game::Marad :strict(params);

use constant {
    BOARD_SIZE => 9,
    MIDDLE     => 4,    # the middle square is used for scoring

    MAX_MOVES => 4,

    TYPE_MASK  => 0b0000_1111,    # piece type
    PLAYER_BIT => 6,              # owned by player 1 or 2?
    MOVED_MASK => 0b1000_0000,    # has the piece moved?

    MOVE_NOPE     => 0,
    MOVE_SQUARE   => 1,           # NOTE also Rook
    MOVE_DIAGONAL => 2,           # NOTE also Bishop

    PIECE_EMPTY  => 0,
    PIECE_ROOK   => 1,
    PIECE_BISHOP => 2,
    PIECE_KING   => 3,            # NOTE Rook and Bishop bits are set

    PUSH_STOP => 0,
    PUSH_OKAY => 1,
};

# NOTE the client is expected to be well behaved and to not modify the
# contents of board nor the score (hiding these references would only
# make such impolite behavior slightly more difficult)
has $board      :reader;
has $move_count :reader;
has $player     :reader;
has $score      :reader;

ADJUST {
    $board = [
        [qw/0 0 0 0 0 0 0 0 0/],    # starting game state
        [qw/0 2 0 0 0 0 0 66 0/],
        [qw/0 1 0 0 0 0 0 65 0/],
        [qw/0 1 0 0 0 0 0 65 0/],
        [qw/0 3 0 0 0 0 0 67 0/],
        [qw/0 1 0 0 0 0 0 65 0/],
        [qw/0 1 0 0 0 0 0 65 0/],
        [qw/0 2 0 0 0 0 0 66 0/],
        [qw/0 0 0 0 0 0 0 0 0/],
    ];
    $move_count = _move_count();
    $player     = 0;
    $score      = [ 0, 0 ];
}

########################################################################
#
# METHODS

method is_owner( $x, $y ) {
    return 0 if $x < 0 or $x >= BOARD_SIZE or $y < 0 or $y >= BOARD_SIZE;
    my $piece = $board->[$y][$x];
    return 0 if $piece == PIECE_EMPTY;
    return 0 unless ( $piece >> PLAYER_BIT & 1 ) == $player;
    return 1;
}

# try to carry out a game move involving two points, generally from a
# player selecting a piece to move and a direction (via the destination
# point) to move in. the move may not be possible for various reasons.
# if possible a move may cause a bunch of changes to the board and other
# game state
method move( $srcx, $srcy, $dstx, $dsty ) {
    return 0, "out of bounds"
      if $srcx < 0
      or $srcx >= BOARD_SIZE
      or $srcy < 0
      or $srcy >= BOARD_SIZE;

    my $piece = $board->[$srcy][$srcx];
    return 0, "not a piece" if $piece == PIECE_EMPTY;

    return 0, "not owner" unless ( $piece >> PLAYER_BIT & 1 ) == $player;

    my ( $move_type, $stepx, $stepy ) = _move_type( $srcx, $srcy, $dstx, $dsty );
    return 0, "invalid move" if $move_type == MOVE_NOPE;

    # this is probably too clever: the king by virtue of being number 3
    # has both the square and diagonal move bits set, while rooks and
    # bishops have only one of them set
    my $piece_type = $piece & TYPE_MASK;
    return 0, "invalid move type" unless ( $move_type & $piece_type ) > 0;

    _move_pushing( $board, $move_count, $srcx, $srcy, $stepx, $stepy );

    # score points for motion in the middle
    my $center = $board->[MIDDLE][MIDDLE];
    if ( $center > 0 and ( $center & MOVED_MASK ) == MOVED_MASK ) {
        $score->[ $center >> PLAYER_BIT & 1 ]++;
    }
    # clear any moved bits
    for my $row ( $board->@* ) {
        for my $col ( $row->@* ) {
            $col &= ~MOVED_MASK;
        }
    }

    $player ^= 1;
    $move_count = _move_count() if $player == 0;

    return 1, "ok";
}

# boards of different sizes might be supported in which case clients may
# need something like the following to obtain that information
method size() { return BOARD_SIZE }

########################################################################
#
# SUBROUTINES

# this many moves happen in each turnpair
sub _move_count () { 1 + int rand(MAX_MOVES) }

# moves stuff around the board
sub _move_pushing ( $grid, $moves, $srcx, $srcy, $stepx, $stepy ) {
    state sub swap ( $grid, $x1, $y1, $x2, $y2 ) {
        $grid->[$y1][$x1] |= MOVED_MASK;
        ( $grid->[$y1][$x1], $grid->[$y2][$x2] ) =
          ( $grid->[$y2][$x2], $grid->[$y1][$x1] );
    }
    state sub step ( $grid, $newx, $newy, $stepx, $stepy ) {
        return PUSH_STOP
          if $newx < 0
          or $newx >= BOARD_SIZE
          or $newy < 0
          or $newy >= BOARD_SIZE;
        return PUSH_OKAY if $grid->[$newy][$newx] == 0;    # empty
        my ( $morex, $morey ) = ( $newx + $stepx, $newy + $stepy );
        return PUSH_STOP
          if __SUB__->( $grid, $morex, $morey, $stepx, $stepy ) != PUSH_OKAY;
        swap( $grid, $newx, $newy, $morex, $morey );
        return PUSH_OKAY;
    }

    my ( $morex, $morey ) = ( $srcx + $stepx, $srcy + $stepy );
    for my $i ( 1 .. $moves ) {
        last if step( $grid, $morex, $morey, $stepx, $stepy ) != PUSH_OKAY;
        swap( $grid, $srcx, $srcy, $morex, $morey );
        ( $srcx, $srcy ) = ( $morex, $morey );
        $morex += $stepx;
        $morey += $stepy;
    }
}

# given two points, what sort of movement is it? (may not be valid)
sub _move_type ( $x1, $y1, $x2, $y2 ) {
    return MOVE_NOPE, undef, undef if $x1 == $x2 and $y1 == $y2;

    my ( $dy, $plus_x ) = ( $y2 - $y1, $x2 > $x1 );
    return MOVE_SQUARE, ( $plus_x ? 1 : -1 ), 0 if $dy == 0;

    my ( $dx, $plus_y ) = ( $x2 - $x1, $y2 > $y1 );
    return MOVE_SQUARE, 0, ( $plus_y ? 1 : -1 ) if $dx == 0;

    return MOVE_DIAGONAL, ( $plus_x ? 1 : -1 ), ( $plus_y ? 1 : -1 )
      if abs($dx) == abs($dy);

    return MOVE_NOPE, undef, undef;
}

1;
__END__

=head1 NAME

Game::Marad - a board game for two players

=head1 SYNOPSIS

  use Game::Marad;
  my $game = Game::Marad->new;
  $game->move( 1, 1, 0, 0 );    # 1, "ok"
  $game->turn;                  # 1
  $game->player;                # 1
  ...

=head1 DESCRIPTION

This module is an implementation of Marad (originally devised for a
cardboard sheet with coins on it, and then Common LISP). With L<Curses>
installed the C<bin/pmarad> script will play the game in a terminal
window. Otherwise a client should not be too difficult to implement,
study the module and C<bin/pmarad> to work out these details.

=head1 METHODS

=over 4

=item B<board>

Returns a reference to the game board. Callers should not modify this,
only read from it.

=item B<is_owner> I<x> I<y>

Returns true if the current player owns the piece on the given point,
false otherwise.

=item B<move_count>

Returns the current move count (how far a piece moved will move). This
is shared between players for each turn pair.

=item B<move> I<srcx> I<srcy> I<dstx> I<dsty>

Attempts to move from the source point in the direction of the
destination point, if that is legal. Returns a list C<0> and an error
message when the move fails, and C<1> and C<undef> when the move is
okay. In this case the game state has been updated; in the prior case no
changes have been made.

=item B<new>

Constructor. Returns a new game in the initial game state.

=item B<player>

Returns the player C<0> or C<1> whose turn it is to move.

=item B<size>

Returns the size of the game board, C<9>.

=item B<score>

Returns an array reference containing the current score. Clients again
should not modify this, only read from it.

=back

=head1 BUGS

None known.

=head1 SEE ALSO

L<gemini://thrig.me/game/marad.gmi> - game rules

L<https://thrig.me/src/marad.git> - Common LISP implementation

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
