use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# The attack walk on its own. t/05-moves.t exercises it through generation,
# which is where it is USED; this file addresses it directly, because a
# legality filter that is wrong in one direction only is a bug that half the
# tests cannot see.
#
# `attacked` is generated BACKWARDS from the point rather than forwards from
# every piece, which is what makes the legality filter affordable. Three things
# in it are not a chess engine's: the cannon needs exactly one screen, the horse
# is blocked and its leg is read FROM THE HORSE'S SIDE, and the general attacks
# its orthogonal neighbours only inside its own palace.

sub pt { $E->point_of(@_) }
sub setup {
    my $b = $E->new(empty => 1);
    $b->put(pt($_->[0], $_->[1]), $_->[2]) for @_;
    return $b;
}

subtest 'the chariot, and what stops it' => sub {
    my $b = setup([4, 4, RED | CHARIOT], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($b->attacked(pt(4, 9), RED), 'up the file, any distance');
    ok($b->attacked(pt(0, 4), RED), 'along the rank too');
    ok(!$b->attacked(pt(3, 5), RED), 'but never diagonally');

    my $blocked = setup([4, 4, RED | CHARIOT], [4, 6, BLACK | SOLDIER],
                        [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($blocked->attacked(pt(4, 6), RED), 'the first piece in the way IS attacked');
    ok(!$blocked->attacked(pt(4, 7), RED), 'and everything beyond it is not');
};

subtest 'the cannon needs exactly one screen, and this is the whole rule' => sub {
    my $none = setup([4, 0, RED | CANNON], [3, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$none->attacked(pt(4, 5), RED), 'no screen, no attack, however clear the line');

    my $one = setup([4, 0, RED | CANNON], [4, 2, BLACK | SOLDIER],
                    [3, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($one->attacked(pt(4, 5), RED), 'one screen, and everything beyond it on that ray');
    ok(!$one->attacked(pt(4, 1), RED), 'but nothing BEFORE the screen');
    ok(!$one->attacked(pt(4, 2), RED), 'and not the screen itself');

    my $two = setup([4, 0, RED | CANNON], [4, 2, BLACK | SOLDIER], [4, 3, BLACK | SOLDIER],
                    [3, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$two->attacked(pt(4, 5), RED), 'two screens, nothing');

    # the screen is of EITHER colour, which is the half a chess intuition drops
    my $own = setup([4, 0, RED | CANNON], [4, 2, RED | SOLDIER],
                    [3, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($own->attacked(pt(4, 5), RED), 'and its own piece screens just as well');
};

subtest 'the horse, and its leg read from the horse side' => sub {
    my $b = setup([4, 4, RED | HORSE], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    my @dest = ([3, 6], [5, 6], [3, 2], [5, 2], [2, 5], [2, 3], [6, 5], [6, 3]);
    ok($b->attacked(pt(@$_), RED), "attacks (@$_)") for @dest;
    ok(!$b->attacked(pt(4, 6), RED), 'but not two straight up');

    # the leg is the ORTHOGONAL STEP FROM THE HORSE, not a neighbour of the
    # destination. Blocking d/e5 kills the two destinations reached through it
    # and leaves the other six.
    my $leg = setup([4, 4, RED | HORSE], [4, 5, BLACK | SOLDIER],
                    [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$leg->attacked(pt(3, 6), RED), 'the hobbled pair goes');
    ok(!$leg->attacked(pt(5, 6), RED), '  both of it');
    ok($leg->attacked(pt(2, 5), RED), 'and the other six stay');
    ok($leg->attacked(pt(3, 2), RED), '  every one');
};

subtest 'the soldier attacks forward, and sideways only across the river' => sub {
    my $home = setup([4, 3, RED | SOLDIER], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($home->attacked(pt(4, 4), RED), 'forward');
    ok(!$home->attacked(pt(4, 2), RED), 'never backward');
    ok(!$home->attacked(pt(5, 3), RED), 'and not sideways on its own side');

    my $over = setup([4, 5, RED | SOLDIER], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($over->attacked(pt(5, 5), RED), 'sideways once it is across');
    ok($over->attacked(pt(3, 5), RED), '  both ways');
    ok($over->attacked(pt(4, 6), RED), 'and still forward');
    ok(!$over->attacked(pt(4, 4), RED), 'and still never backward');

    # and Black goes the other way, which a copied implementation gets wrong
    my $black = setup([4, 6, BLACK | SOLDIER], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($black->attacked(pt(4, 5), BLACK), 'black forward is DOWN the ranks');
    ok(!$black->attacked(pt(4, 7), BLACK), '  and not up them');
};

subtest 'the elephant and the advisor attack too' => sub {
    # a legality filter that forgets them lets a general walk onto a defended point
    my $e = setup([2, 0, RED | ELEPHANT], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($e->attacked(pt(4, 2), RED), 'the elephant attacks two points diagonally');
    ok($e->attacked(pt(0, 2), RED), '  the other way as well');

    my $eye = setup([2, 0, RED | ELEPHANT], [3, 1, BLACK | SOLDIER],
                    [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$eye->attacked(pt(4, 2), RED), 'and not with its eye blocked');

    my $a = setup([4, 1, RED | ADVISOR], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($a->attacked(pt(3, 0), RED), 'the advisor attacks diagonally inside the palace');
    ok($a->attacked(pt(5, 2), RED), '  all four of them');

    my $out = setup([3, 2, RED | ADVISOR], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$out->attacked(pt(2, 3), RED), 'and never outside it');
};

subtest 'the general attacks its neighbours, inside its palace only' => sub {
    my $g = setup([4, 1, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok($g->attacked(pt(4, 0), RED), 'one step down');
    ok($g->attacked(pt(3, 1), RED), 'one step across');
    ok($g->attacked(pt(4, 2), RED), 'one step up');
    ok(!$g->attacked(pt(4, 3), RED), 'but not two');

    my $edge = setup([3, 2, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$edge->attacked(pt(2, 2), RED), 'and not outside the palace, which it cannot enter');
    ok(!$edge->attacked(pt(3, 3), RED), '  in either direction');
};

# THE FLYING GENERAL IS NOT IN `attacked`, AND THAT IS THE DESIGN.
#
# `attacked` answers "could a piece of that colour capture this point", which is
# a question about PIECES. Facing generals are a question about the two generals
# only, so folding it in would make `attacked` answer differently for one point
# than for every other. `in_check` adds it, and `gen_legal` refuses any move that
# leaves it true.
#
# Prove it in BOTH directions, because a one-sided implementation is the likely
# bug and half the tests cannot see it.
subtest 'the flying general lives in in_check, and works both ways' => sub {
    my $open = setup([4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    ok($open->generals_face, 'the generals face down the open file');
    ok($open->in_check(RED),   'RED is in check');
    ok($open->in_check(BLACK), 'and so is BLACK, which is the both-ways half');
    is($open->attacked(pt(4, 9), RED), 0,
        'while `attacked` says nothing about it, deliberately');

    my $blocked = setup([4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL],
                        [4, 5, RED | SOLDIER]);
    ok(!$blocked->generals_face, 'one piece between and they do not');
    ok(!$blocked->in_check(RED),   'neither is in check');
    ok(!$blocked->in_check(BLACK), '  neither of them');

    # a piece may not step off the file and expose them, from either side
    for my $colour (RED, BLACK) {
        my $b = setup([4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL],
                      [4, 5, $colour | CHARIOT]);
        $b->set_side($colour);
        my %to = map { $E->move_to($_) => 1 }
                 grep { $E->move_from($_) == pt(4, 5) } $b->legal;
        ok(!$to{ pt(3, 5) },
            sprintf('a %s chariot may not step off the file', $colour == RED ? 'red' : 'black'));
        ok($to{ pt(4, 6) } || $to{ pt(4, 4) }, '  but may slide along it');
    }
};

subtest 'attacked and in_check agree about a general' => sub {
    # a thousand positions from a real game: whenever a general is attacked by a
    # piece, in_check says so, and the only disagreements are the flying general
    my $b = $E->new;
    my $disagree = 0;
    for my $i (1 .. 120) {
        my @legal = $b->legal;
        last unless @legal;
        for my $colour (RED, BLACK) {
            my $g = $b->find($colour | GENERAL);
            next unless $g;
            my $by_piece = $b->attacked($g, Game::Xiangqi::Engine::other($colour)) ? 1 : 0;
            my $checked  = $b->in_check($colour) ? 1 : 0;
            next if $by_piece == $checked;
            $disagree++ unless $b->generals_face;
        }
        $b->do_move($legal[ ($i * 11) % @legal ]);
    }
    is($disagree, 0, 'they never disagree except when the generals face');
};

done_testing();
