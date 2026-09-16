#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Backgammon::Board;

# The position and the numbering. The numbering tests are the point of this
# file: a backgammon engine's bugs live in "which way round is it", so the
# symmetry is asserted from both sides of the board rather than from white's
# only, where a direction error is invisible.

subtest 'the opening position' => sub {
    plan tests => 8;
    my $b = Game::Backgammon::Board->new;

    is($b->pip_count('white'), 167, 'white opens on 167 pips');
    is($b->pip_count('black'), 167, 'and so does black: the opening is symmetric');

    # the same four points, said from each side
    for my $player (qw(white black)) {
        is_deeply([ map { $b->mine_on($player, $_) } 6, 8, 13, 24 ], [ 5, 3, 5, 2 ],
                  "$player has 5 on 6, 3 on 8, 5 on 13 and 2 on 24");
    }

    is($b->checkers_on_points('white'), 15, 'fifteen white checkers');
    is($b->checkers_on_points('black'), 15, 'fifteen black');
    is_deeply([ $b->consistent ], [], 'and the position is sound');
    is($b->bar('white') + $b->off('white'), 0, 'nothing on the bar or off');
};

subtest 'your point n is their point 25 - n' => sub {
    plan tests => 4;
    my $b = Game::Backgammon::Board->new;

    # white's 24 point holds two white checkers; that same point is black's 1
    is($b->mine_on('white', 24), 2, "white has two on its 24");
    is($b->theirs_on('black', 1), 2, 'which black sees as two of theirs on its 1');

    is($b->index_for('white', 1), $b->index_for('black', 24),
       "white's 1 and black's 24 are the same square");
    is($b->index_for('white', 24), $b->index_for('black', 1),
       'and so are the other ends');
};

subtest 'blots and blocked points' => sub {
    plan tests => 5;
    my $b = Game::Backgammon::Board->new;

    ok($b->is_blocked('white', 1), "black's two checkers block white's 1 point");
    ok(!$b->is_blot('white', 1), 'two is not a blot');

    $b->set_point('black', 24, 1);        # black's 24 is white's 1
    ok($b->is_blot('white', 1), 'one is');
    ok(!$b->is_blocked('white', 1), 'and a blot does not block');

    $b->set_point('black', 24, 0);
    ok(!$b->is_blot('white', 1) && !$b->is_blocked('white', 1), 'an empty point is neither');
};

subtest 'home, and what stops you being home' => sub {
    plan tests => 4;
    # every white checker on its 1 point: all home
    my $b = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    $b->set_point('white', 1, 15);
    $b->set_point('black', 1, 15);
    ok($b->all_home('white'), 'fifteen on the 1 point is all home');

    $b->set_point('white', 1, 14);
    $b->to_bar('white');
    ok(!$b->all_home('white'),
       'a checker on the bar is not home, which is what stops bearing off after a hit');

    $b->to_bar("white", -1);
    $b->set_point('white', 1, 14);
    $b->set_point('white', 7, 1);
    ok(!$b->all_home('white'), 'and neither is one outside the home board');

    is($b->highest_occupied('white'), 7, 'the highest occupied point is found');
};

subtest 'pip counts' => sub {
    plan tests => 3;
    my $b = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    $b->set_point('white', 6, 1);
    $b->set_point('black', 1, 15);
    is($b->pip_count('white'), 6, 'one checker on the 6 point is six pips');

    $b->to_bar('white');
    is($b->pip_count('white'), 6 + 25, 'and one on the bar is twenty-five');

    $b->to_off('white', 3);
    is($b->pip_count('white'), 31, 'a checker borne off is no pips at all');
};

subtest 'the invariant complains, and says what is wrong' => sub {
    plan tests => 3;
    my $b = Game::Backgammon::Board->new;
    $b->add('white', 6, 1);                       # a sixteenth white checker
    my @wrong = $b->consistent;
    is(scalar @wrong, 1, 'one complaint');
    like($wrong[0], qr/white has 16 checkers/, 'naming the side and the count');

    # A point holding BOTH colours cannot be represented: one signed number
    # cannot be positive and negative at once. That is why the signed array
    # was chosen, so it is asserted rather than left as folklore.
    my $c = Game::Backgammon::Board->new;
    my ($mine, $theirs) = $c->point_for('white', 1);
    ok(!($mine && $theirs), 'a point is never both colours at once, by construction');
};

done_testing();
