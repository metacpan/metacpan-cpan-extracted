use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

sub board {
    my ($position) = @_;
    my ($bd, $err) = $E->of_string($position);
    die "'$position' was refused, code $err" unless $bd;
    return $bd;
}

sub chosen {
    my ($bd, $roll, %option) = @_;
    my $found = $bd->search($roll, %option);
    my @moves = $bd->moves($roll, $option{rules});
    return $found->{index} < 0 ? '-' : $moves[ $found->{index} ]->from . '-' . $moves[ $found->{index} ]->to;
}

=pod

THE ARITHMETIC, WORKED BY HAND.

The position is H2 of t/08-hand-counted.t, short route:

    light  b1 (step 3), a2 (5), g2 (11), h1 (13), two in hand, one home
    dark   d2 (step 8), six in hand

A piece is worth the step it stands on, a piece at home is worth 15 (one more
than the fourteen steps of the route) and a piece in hand is worth nothing.

    light  3 + 5 + 11 + 13 + 15 = 47
    dark   8

The value is in sixteenths of a step: 16 * (47 - 8) = 624 for light, and
-624 for dark.

One level deep, a move is worth the position it leaves:

    a roll of 2: hand-c1, a2-c2 and h1-home each add 2 to light
                 16 * (49 - 8) = 656, all three, and the LAST is chosen

    a roll of 3: b1-b2 and g2-g1 each add 3
                 16 * (50 - 8) = 672, both, and the last is chosen

    a roll of 3 where the rosette is not safe: a2-d2 adds 3 AND captures,
                 which sends the dark piece back to nothing
                 16 * (50 - 0) = 800, against 672 for the other two

=cut

my $H2 = '4xx2/l2d2l1/1l2xx1l l 2 1 6 0';

subtest 'a position is worth its progress' => sub {
    my $bd = board($H2);
    is($bd->evaluate(SIDE_LIGHT), 624, '16 * (47 - 8) for light');
    is($bd->evaluate(SIDE_DARK), -624, 'and the opposite for dark');
    is($E->new->evaluate(SIDE_LIGHT), 0, 'the start is worth nothing to either side');
    is(board('4xx2/8/4xx2 l 0 7 7 0')->evaluate(SIDE_LIGHT), 16 * 7 * 15, 'seven home on the short route: 7 * 15 steps');
    is(board('4xx2/8/4xx2 l 0 7 7 0')->evaluate(SIDE_LIGHT, 'masters'), 16 * 7 * 17, 'and on the long: 7 * 17');
    is(board('4xxl1/8/4xx2 l 6 0 7 0')->evaluate(SIDE_LIGHT, 'masters'), 16 * 12, 'g3 is light step 12 on the long route');
    is(board('4xxd1/8/4xx2 l 7 0 6 0')->evaluate(SIDE_DARK, 'masters'), 16 * 16, 'and dark step 16');
    is($bd->evaluate(2), 0, 'a side that does not exist is worth nothing');
};

subtest 'one level deep, by hand' => sub {
    my $bd = board($H2);
    my $found = $bd->search(2, depth => 1);
    is($found->{value}, 656, 'a roll of 2: every move is worth 656');
    is(chosen($bd, 2, depth => 1), 'h1-home', 'and of three equal moves the LAST is chosen, the piece furthest along');
    is($found->{depth}, 1, 'one level');
    is($found->{nodes}, '3', 'three positions looked at, one for each move');
    ok(!$found->{stopped}, 'and it was not stopped');

    is($bd->search(3, depth => 1)->{value}, 672, 'a roll of 3: 672');
    is(chosen($bd, 3, depth => 1), 'g2-g1', 'the last of the two');

    my %open = (rules => { safe_rosettes => 0 });
    is($bd->search(3, depth => 1, %open)->{value}, 800, 'with the rosette not safe the capture is worth 800');
    is(chosen($bd, 3, depth => 1, %open), 'a2-d2', 'and it is chosen though it is not the last');
};

=pod

TWO LEVELS DEEP, WORKED BY HAND. These are the numbers that hold the search
to the dice: a level is every roll, each weighed by how often it comes, and a
roll that allows nothing is a level too.

FINKEL. Light has h1 (step 13) and one piece in hand, five home; dark has h3
(its step 13) and six home. Progress is 5*15 + 13 = 88 against 6*15 + 13 = 103.
Light rolls 1 and may enter on d1 or move h1 to g1, which is a rosette. Either
makes light 89. Four dice roll 0, 1, 2, 3, 4 with weights 1, 4, 6, 4, 1 in 16.

  hand-d1, and dark is to move:
    0  nothing to move, the turn is lost     16 * (89 - 103)     =       -224
    1  h3-g3, dark 104                       16 * (89 - 104)     =       -240
    2  h3 home: DARK HAS WON                                       -1,000,000
    3  overshoots, the turn is lost                                      -224
    4  overshoots, the turn is lost                                      -224
       (-224 - 4*240 - 6*1,000,000 - 4*224 - 224) / 16         =   -375,144

  h1-g1, and LIGHT is to move again:
    0  the turn is lost                                                  -224
    1  hand-d1 or g1 home, light 90 either way  16 * (90 - 103)  =       -208
    2  hand-c1, light 91                                                 -192
    3  hand-b1, light 92                                                 -176
    4  hand-a1, light 93                                                 -160
       (-224 - 4*208 - 6*192 - 4*176 - 160) / 16               =       -192

So two levels deep light moves h1 to g1, and the move is worth -192.

MASTERS, where the dice are three and a throw of nothing is worth four: the
rolls are 1, 2, 3, 4 with weights 3, 3, 1, 1 in 8, and the route is sixteen
steps, so home is worth 17. Light has g1 (step 16) and one in hand, five home;
dark has g3 (its step 16) and six home: 5*17 + 16 = 101 against 6*17 + 16 =
118. Light rolls 1 and may enter on d1 or take g1 home. Either makes light
102, and either passes the turn.

    1  g3 home: DARK HAS WON                                       -1,000,000
    2, 3, 4  overshoot, the turn is lost     16 * (102 - 118)    =       -256
       (-3*1,000,000 - 3*256 - 256 - 256) / 8                  =   -375,160

Both moves are worth that, and the last of them is chosen.

=cut

subtest 'two levels deep, by hand' => sub {
    my $finkel = board('4xx1d/8/4xx1l l 1 5 0 6');
    is($finkel->evaluate(SIDE_LIGHT), 16 * (88 - 103), 'finkel: the position is 88 against 103');
    my $found = $finkel->search(1, depth => 2);
    is(chosen($finkel, 1, depth => 2), 'h1-g1', 'light moves h1 to the rosette');
    is($found->{value}, -192, 'and it is worth -192: five rolls, a lost turn among them, weighed 1 4 6 4 1');
    is($found->{depth}, 2, 'two levels');

    my @moves = $finkel->moves(1);
    my $undo = $finkel->apply($moves[0]);
    is($finkel->side, SIDE_DARK, 'after hand-d1 dark is to move');
    $finkel->unapply($undo);
    is($finkel->search(1, depth => 1)->{value}, 16 * (89 - 103), 'one level deep both moves are worth -224');

    my $masters = board('4xxd1/8/4xxl1 l 1 5 0 6');
    is($masters->evaluate(SIDE_LIGHT, 'masters'), 16 * (101 - 118), 'masters: the position is 101 against 118');
    my $deep = $masters->search(1, depth => 2, rules => 'masters');
    is($deep->{value}, -375_160, 'two levels deep it is worth -375,160: four rolls weighed 3 3 1 1, and one of them loses the game');
    is(chosen($masters, 1, depth => 2, rules => 'masters'), 'g1-home', 'and of two equal moves the last is chosen');
    isnt($masters->search(1, depth => 2)->{value}, -375_160, 'under finkel dice the same board is worth something else');
};

# A level that did not finish has an opinion about the moves it got to, and
# that opinion is thrown away. One level deep the answer here is g2-home (the
# last of two equal moves); two levels deep it is a2-e2. A budget of three
# positions pays for the first level and stops the second inside its first
# move.
subtest 'a level cut short does not get a say' => sub {
    my $bd = board('d3xx2/l5l1/4xx2 l 0 5 6 0');
    my $found = $bd->search(4, budget => 3);
    is($found->{depth}, 1, 'three positions finish one level');
    ok($found->{stopped}, 'and the second is stopped');
    is(chosen($bd, 4, budget => 3), 'g2-home', 'the answer is the first level\'s, not the half-looked-at second\'s');
    is($found->{value}, $bd->search(4, depth => 1)->{value}, 'at the first level\'s value');
};

# Light has a2, with a dark piece one step behind it on a3, and g2. A roll of
# 4 takes a2 out of reach or takes g2 home. Both add four steps, so one level
# deep they are equal and the last is chosen: g2 goes home and a2 is left
# where a dark roll of 1, four throws in sixteen, sends it back five steps.
# Two levels deep the search has seen dark's reply.
subtest 'two levels deep sees the reply' => sub {
    my $bd = board('d3xx2/l5l1/4xx2 l 0 5 6 0');
    is(chosen($bd, 4, depth => 1), 'g2-home', 'one level: the piece furthest along, leaving a2 where it can be taken');
    is(chosen($bd, 4, depth => 2), 'a2-e2', 'two levels: a2 is moved out of reach');
    cmp_ok($bd->search(4, depth => 2)->{value}, '<', $bd->search(4, depth => 1)->{value},
        'and the position is worth less than it looked');
    is($bd->greedy(4), 1, 'the choice without looking ahead is the one a level of search makes');
};

subtest 'a game seen to be won' => sub {
    my $bd = board('4xx2/1d6/4xxl1 l 0 6 6 0');
    my $found = $bd->search(1, depth => 3);
    is(chosen($bd, 1, depth => 3), 'g1-home', 'the last piece goes home');
    cmp_ok($found->{value}, '>=', WIN, 'and the value says the game is won');
    is($found->{depth}, 1, 'a move with no alternative is not thought about');

    my $over = board('4xx2/1d6/4xx2 d 0 7 6 0');
    is($over->search(1)->{index}, -1, 'a finished game has no move to find');
    is($E->new->search(0)->{index}, -1, 'nor has a roll of nothing');
};

subtest 'the choice without looking ahead' => sub {
    my $capture = board('4xx2/l1d3l1/2l1xx2 l 4 0 6 0');
    my @moves = $capture->moves(2);
    is(join(' ', map { $_->from . '-' . $_->to . ($_->captures ? 'x' : '') . ($_->rosette ? '*' : '') } @moves),
        'c1-a1* a2-c2x g2-h1', 'a roll of 2 offers a rosette, a capture and a plain move');
    is($moves[ $capture->greedy(2) ]->captures, 1, 'a capture is taken before a rosette or the piece furthest along');

    my $rosette = board('4xx2/l5l1/2l1xx2 l 4 0 7 0');
    my @plain = $rosette->moves(2);
    is($plain[ $rosette->greedy(2) ]->to, 'a1', 'with no capture, the rosette');

    my $neither = board('4xx2/l5l1/4xx2 l 5 0 7 0');
    my @far = $neither->moves(1);
    is($far[ $neither->greedy(1) ]->from, 'g2', 'with neither, the piece furthest along');
    is($E->new->greedy(0), -1, 'and nothing on a roll of nothing');
};

subtest 'a search leaves the board alone' => sub {
    srand(20261009);
    my @bad;
    my $live = $E->live;
    for my $rules ('finkel', 'masters') {
        my $spelled = $E->rules($rules);
        my @rolls = grep { $_ } map { $_->[0] } $E->chances($spelled->{dice}, $spelled->{zero_rolls});
        my $bd = $E->new;
        for my $n (1 .. 1_000) {
            $bd = $E->new if $bd->status($rules) != ONGOING;
            my $roll = $rolls[ rand @rolls ];
            my $before = join ' | ', $bd->to_string, $bd->key_hex, $bd->ply;
            my @moves = $bd->moves($roll, $rules);
            my $found = $bd->search($roll, rules => $rules, depth => 1 + $n % 3);
            push @bad, "$before changed under a search" unless $before eq join ' | ', $bd->to_string, $bd->key_hex, $bd->ply;
            push @bad, "$before: index $found->{index} of " . scalar(@moves)
                unless @moves ? ($found->{index} >= 0 && $found->{index} < @moves) : $found->{index} == -1;
            if (@moves) { $bd->apply($moves[ $found->{index} ], $rules) } else { $bd->forfeit }
        }
    }
    is(scalar @bad, 0, 'two thousand searches, and the board, its key, its hands and its ply are as they were')
        or diag(join "\n", @bad[0 .. ($#bad > 4 ? 4 : $#bad)]);
    is($E->live, $live, 'and every board a search copied was dropped again');
};

subtest 'the weights' => sub {
    my $bd = board('d3xx2/l5l1/4xx2 l 0 5 6 0');
    my $plain = $bd->evaluate(SIDE_LIGHT);
    my $wary  = $bd->evaluate(SIDE_LIGHT, undef, { exposed => 16 });
    is($plain - $wary, 20, 'a2 can be taken by a dark roll of 1: 4 sixteenths of its 5 steps is 20 sixteenths of a step');
    is($bd->evaluate(SIDE_LIGHT, undef, { exposed => 8 }), $plain - 10, 'and half the weight is half of it');
    is(chosen($bd, 4, depth => 1, weights => { exposed => 16 }), 'a2-e2', 'with that weight, one level is enough to move a2');

    # ON THE LONG ROUTE a cell is a different step for each side. Light on g3
    # (its step 12) can be taken by the dark piece on h3 (dark step 15, and g3
    # is dark step 16): a dark roll of 1, three throws in eight, 6 sixteenths
    # of light's 12 steps, 72. And the dark piece on h3 can be taken by that
    # light piece, for h3 is light step 13: 6 sixteenths of dark's 15, 90.
    my $far = board('4xxld/8/4xx2 l 6 0 6 0');
    is($far->evaluate(SIDE_LIGHT, 'masters', { exposed => 16 }) - $far->evaluate(SIDE_LIGHT, 'masters'), 90 - 72,
        'long route: each side is asked of its attacker\'s step for the cell, not its own');

    my $held = board('4xx2/3l4/4xx2 l 6 0 7 0');
    is($held->evaluate(SIDE_LIGHT, undef, { rosette => 16 }) - $held->evaluate(SIDE_LIGHT), 16, 'a piece on the middle rosette, at 16');
    is(board('4xx2/8/l3xx2 l 6 0 7 0')->evaluate(SIDE_LIGHT, undef, { rosette => 16 }), 16 * 4,
        'but not one on a rosette only its own side visits');
    is($E->new->evaluate(SIDE_LIGHT, undef, { entry => 8 }), 0, 'seven in each hand cancel');
    is(board('4xx2/8/3lxx2 l 6 0 7 0')->evaluate(SIDE_LIGHT, undef, { entry => 8 }), 16 + 8, 'and a piece entered is a step and a weight');

    ok(!eval { $bd->evaluate(SIDE_LIGHT, undef, { exposure => 16 }); 1 }, 'a weight that does not exist croaks');
    ok(!eval { $bd->search(4, weights => [ 16 ]); 1 }, 'and so do weights that are not a hash');
};

subtest 'what search refuses' => sub {
    my $bd = $E->new;
    ok(!eval { $bd->search(5); 1 }, 'a roll of 5');
    ok(!eval { $bd->search(1, budget => -1); 1 }, 'a budget below nothing');
    ok(!eval { $bd->search(1, budget => 3_000_000_000); 1 }, 'a budget above two thousand million: refused, not wrapped');
    ok(!eval { $bd->search(1, depth => 33); 1 }, 'a depth past 32');
    ok(!eval { $bd->search(1, deep => 3); 1 }, 'and an option that is not one');
    is(DEPTH_MAX, 32, 'DEPTH_MAX is 32');
};

done_testing();
