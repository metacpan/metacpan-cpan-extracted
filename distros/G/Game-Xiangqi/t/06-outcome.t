use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# THE RULE EVERYBODY GETS WRONG IS THE ENDING.
#
#   "Unlike in chess, in which stalemate is a draw, in xiangqi, it is a loss for
#    the player who has no legal move."
#
# Every chess engine's structure is `if (no moves) return in_check ? MATE : DRAW`
# and every port of one to this game ships a bug that appears only in endgames,
# which is where the games that matter are decided. This file asserts the
# stalemate BY RESULT and not by "the game ended", because "ended" is true either
# way and is exactly what a ported engine would also report.

subtest 'checkmate is a loss for the side to move' => sub {
    # 4k4/3RRR3/9/9/9/9/9/9/9/4K4 b: three red chariots abreast on rank 8. The
    # one on e8 checks and the other two defend it along the rank.
    my $b = $E->new(fen => '4k4/3RRR3/9/9/9/9/9/9/9/4K4 b');
    ok($b, 'the position loads');
    is(scalar($b->legal), 0, 'black has no legal move');
    ok($b->in_check(BLACK), 'and is in check');

    my ($winner, $reason) = $b->outcome;
    is($winner, RED, 'RED wins');
    is($reason, BY_CHECKMATE, 'by checkmate');
    ok($b->is_over, 'and the game is over');
};

subtest 'STALEMATE IS ALSO A LOSS, and this is the assertion that matters' => sub {
    # 3k5/R8/9/9/9/9/9/9/4R4/4K4 b. Black's general is on d9 and its only two
    # squares are covered: d8 by the chariot along rank 8, e9 by the chariot up
    # file e. The general itself is NOT attacked, so this is stalemate and not
    # mate, and a chess engine would call it a draw.
    my $b = $E->new(fen => '3k5/R8/9/9/9/9/9/9/4R4/4K4 b');
    ok($b, 'the position loads');
    is(scalar($b->legal), 0, 'black has no legal move');

    ok(!$b->in_check(BLACK), 'and is NOT in check, which is what makes it stalemate');
    is($b->attacked($E->point_of(3, 9), RED), 0, '  the general is not attacked');
    ok($b->attacked($E->point_of(3, 8), RED), '  but d8 is');
    ok($b->attacked($E->point_of(4, 9), RED), '  and so is e9');

    my ($winner, $reason) = $b->outcome;

    # THE THREE ASSERTIONS A PORTED CHESS ENGINE FAILS
    is($winner, RED, 'RED WINS. Not a draw');
    is($reason, BY_STALEMATE, 'by stalemate');
    isnt($winner, 0, 'and the winner is emphatically not nobody');
};

subtest 'a game in progress is neither' => sub {
    my $b = $E->new;
    my ($winner, $reason) = $b->outcome;
    is($winner, 0, 'the opening has no winner');
    is($reason, ONGOING, 'and no reason');
    ok(!$b->is_over, 'and is not over');
    is(scalar($b->legal), 44, 'because there are 44 moves to make');
};

subtest 'one move away from each ending' => sub {
    # Take the mate and give black a piece that can ANSWER the check. A spare
    # piece is not enough and the first version of this test assumed it was: a
    # black chariot on a5 has plenty of moves on an empty board and not one of
    # them is legal, because every one leaves the general in check. It was still
    # mate. THE PIECE HAS TO BE ABLE TO CAPTURE THE CHECKER, so it goes on e5
    # where it bears up the file at the chariot on e8.
    my $b = $E->new(fen => '4k4/3RRR3/9/9/9/9/9/9/9/4K4 b');
    $b->put($E->point_of(4, 5), BLACK | CHARIOT);
    my ($w) = $b->outcome;
    is($w, 0, 'a black chariot that can take the checker ends the mate');
    is(scalar($b->legal), 1, '  and it has exactly one legal move: the capture');

    # and the stalemate likewise
    my $s = $E->new(fen => '3k5/R8/9/9/9/9/9/9/4R4/4K4 b');
    $s->put($E->point_of(0, 5), BLACK | SOLDIER);
    my ($w2) = $s->outcome;
    is($w2, 0, 'a spare black soldier ends the stalemate');
};

subtest 'two bare generals' => sub {
    # not on the same file: the game simply continues
    my $b = $E->new(empty => 1);
    $b->put($E->point_of(3, 0), RED | GENERAL);
    $b->put($E->point_of(4, 9), BLACK | GENERAL);
    my ($w, $r) = $b->outcome;
    is($w, 0, 'two bare generals on different files is an ongoing game');
    is($r, ONGOING, '  with no reason');

    # THERE IS NO INSUFFICIENT MATERIAL RULE HERE, and that is a rule and not an
    # omission: the Wikipedia article notes that because stalemate is a loss,
    # most book draws are fortresses rather than bare-king positions.
    ok(scalar($b->legal) > 0, 'and a bare general still has moves to make');

    # on the same file they face, which is check, and the side to move must break it
    my $f = $E->new(empty => 1);
    $f->put($E->point_of(4, 0), RED | GENERAL);
    $f->put($E->point_of(4, 9), BLACK | GENERAL);
    ok($f->generals_face, 'on one file they face');
    ok($f->in_check(RED), 'which is check for whoever is to move');
    for my $mv ($f->legal) {
        my (undef, $u) = $f->do_move($mv);
        ok(!$f->generals_face, 'and every legal move breaks it');
        $f->undo_move($u);
    }
};

subtest 'outcome never returns a draw, by construction' => sub {
    # A POSITION ON ITS OWN CAN NEVER BE A DRAW in this game. The draws it has
    # are the Asian Rules' repetition rulings and the three house counters, and
    # every one of them is a property of a SEQUENCE, which phase 06 owns. This
    # walks a few hundred positions and asserts the only three answers.
    my $b = $E->new;
    my %seen;
    my @stack;
    for my $i (1 .. 200) {
        my @legal = $b->legal;
        my ($w, $r) = $b->outcome;
        $seen{$r}++;
        if (!@legal) {
            isnt($w, 0, 'a position with no legal move always has a winner');
            last;
        }
        is($w, 0, 'and one with legal moves never does') if $i <= 3;
        my (undef, $u) = $b->do_move($legal[ ($i * 7) % @legal ]);
        push @stack, $u;
    }
    my @reasons = sort { $a <=> $b } keys %seen;
    ok(!grep({ $_ != ONGOING && $_ != BY_CHECKMATE && $_ != BY_STALEMATE } @reasons),
        'every reason seen is one of the three, and none of them is a draw');
};

done_testing();
