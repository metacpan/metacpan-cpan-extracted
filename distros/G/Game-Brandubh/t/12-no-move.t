use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine qw(ATTACKERS DEFENDERS ATTACKER DEFENDER KING);
use Game::Brandubh::Rules ':all';
use Game::Brandubh::Test::Squares qw(sq unwire);
my $R = 'Game::Brandubh::Rules';

# Rule 12: "The game is drawn [...] if a player cannot move".
#
# Every one of these boxes a piece in with the last move arriving on the side
# AWAY from the edge. A piece closed on a line is captured, not blocked, so a
# box has to be finished by the one move that completes no line: with the
# piece on the edge, the move that arrives in front of it. The edge is not an
# enemy, so nothing is taken.

subtest 'the attackers cannot move' => sub {
    my $g = $R->new(position => '7/7/7/d6/a6/d5k/1d5 d');
    is($g->outcome, ONGOING, 'before the last defender arrives the game is on');
    my ($answer, $flags) = $g->play(unwire('b1b3'));
    is($answer, PLAY_OK, 'b1b3 is played');
    is($flags, 0, 'and captures nothing: the attacker is on the edge');
    is($g->count(ATTACKER), 1, 'the attacker is still there');
    is(scalar($g->board->moves), 0, 'and has nowhere to go');
    is($g->side, ATTACKERS, 'it is the attackers\' turn');
    is($g->outcome, DRAW_NO_MOVE, 'so the game is drawn');
    ok($g->is_draw, 'a draw');
    is($g->winner, undef, 'not a loss: nobody wins');
    is(scalar($g->moves), 0, 'no moves');
};

subtest 'the defenders cannot move, the king being all they have' => sub {
    my $g = $R->new(position => '7/7/7/a6/k6/a6/1a5 a');
    is($g->outcome, ONGOING, 'before the last attacker arrives the game is on');
    my ($answer, $flags) = $g->play(unwire('b1b3'));
    is($answer, PLAY_OK, 'b1b3 is played');
    is($flags, 0, 'and does not capture the king: he is on the edge, away from any corner');
    is($g->count(KING), 1, 'he is still there');
    is($g->side, DEFENDERS, 'it is the defenders\' turn');
    is($g->outcome, DRAW_NO_MOVE, 'and they cannot move: drawn');
    is($g->winner, undef, 'nobody wins');
};

# The sentence is about a PLAYER. A king who cannot move while a defender can
# is a player who can.
subtest 'a blocked king is not a blocked side' => sub {
    my $g = $R->new(position => '7/6d/7/a6/k6/a6/1a5 a');
    $g->play(unwire('b1b3'));
    is($g->outcome, ONGOING, 'the king is boxed and the game is on');
    my @moves = $g->moves;
    cmp_ok(scalar(@moves), '>', 0, 'because the defender on g6 has ' . scalar(@moves) . ' moves');
    is(scalar(grep { Game::Brandubh::Engine->move_from($_) == sq('a3') } @moves), 0,
        'none of them the king\'s');
};

subtest 'a blocked attacker is not a blocked side either' => sub {
    my $g = $R->new(position => '7/6a/7/d6/a6/d5k/1d5 d');
    $g->play(unwire('b1b3'));
    is($g->outcome, ONGOING, 'one attacker is boxed and another is free');
};

subtest 'a position set up with the side to move already blocked' => sub {
    my $g = $R->new(position => '7/7/7/d6/ad5/d5k/7 a');
    is($g->outcome, DRAW_NO_MOVE, 'drawn where it stands');
    is($g->ply, 0, 'at ply 0');
    is($g->play(unwire('a3a3')), PLAY_OVER, 'and it takes no move');

    my $other = $R->new(position => '7/7/7/d6/ad5/d5k/7 d');
    is($other->outcome, ONGOING, 'the same squares with the OTHER side to move is a game');
};

# No move is asked AFTER no pieces: a side with nothing has lost, and only a
# side with something and nowhere to put it is blocked.
subtest 'no pieces is not no move' => sub {
    my $g = $R->new(position => '7/4d2/7/7/2da3/1k5/7 d');
    $g->play(unwire('e6e3'));
    is($g->count(ATTACKER), 0, 'the attackers have nothing');
    is($g->outcome, BY_NO_PIECES, 'which is a win for the defenders');
    isnt($g->outcome, DRAW_NO_MOVE, 'and not this draw');
};

# The box against a corner, which is NOT a box: the corner is an enemy, so the
# move that would close it captures instead.
subtest 'closing a piece against a corner captures it' => sub {
    my $g = $R->new(position => '7/7/7/d6/7/ad4k/7 d');
    my ($answer, $flags) = $g->play(unwire('a4a3'));
    is($answer, PLAY_OK, 'a4a3 is played');
    is($g->count(ATTACKER), 0, 'and the attacker on a2 is taken against a1');
    is($g->outcome, BY_NO_PIECES, 'so this is a win and not a blocked side');
};

subtest 'undo takes the draw back' => sub {
    my $g = $R->new(position => '7/7/7/d6/a6/d5k/1d5 d');
    $g->play(unwire('b1b3'));
    is($g->outcome, DRAW_NO_MOVE, 'drawn');
    is($g->undo, 1, 'undone');
    is($g->outcome, ONGOING, 'and on again');
    is($g->position, '7/7/7/d6/a6/d5k/1d5 d', 'where it was');
    cmp_ok(scalar($g->moves), '>', 0, 'with moves to make');
};

done_testing();
