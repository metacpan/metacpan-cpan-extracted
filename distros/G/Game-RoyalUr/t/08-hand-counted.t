use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

=pod

THE ONLY NUMBERS HERE THAT NO PROGRAM PRODUCED.

Each position below was laid out on paper, and its moves counted by hand from
the two routes, twice, before any generator existed. Every line gives the
moves a roll allows and, where a candidate has none, the rule that takes it
away. If one of these fails, the first thing to doubt is the engine.

Light's steps. Dark's are the same with rows 1 and 3 exchanged.

    short   1 d1  2 c1  3 b1  4 a1  5 a2  6 b2  7 c2  8 d2  9 e2 10 f2
           11 g2 12 h2 13 h1 14 g1 15 home
    long    1 d1  2 c1  3 b1  4 a1  5 a2  6 b2  7 c2  8 d2  9 e2 10 f2
           11 g2 12 g3 13 h3 14 h2 15 h1 16 g1 17 home

=cut

sub said {
    my ($bd, $roll, $rules) = @_;
    return join ' ', map {
        $_->from . '-' . $_->to . ($_->captures ? 'x' : '') . ($_->rosette ? '*' : '')
    } $bd->moves($roll, $rules);
}

sub counted {
    my ($name, $position, $rules, $want, $total) = @_;
    my ($bd, $err) = $E->of_string($position);
    die "$name: '$position' was refused, code $err" unless $bd;
    subtest $name => sub {
        ok($bd->consistent(7), 'seven a side, all accounted for');
        my $sum = 0;
        for my $roll (sort keys %$want) {
            my ($moves, $why) = @{ $want->{$roll} };
            is(said($bd, $roll, $rules), $moves, "roll $roll: $why");
            $sum += scalar(my @list = split ' ', $moves);
        }
        is($sum, $total, "and that is $total moves in all");
    };
}

# H1. Seven in each hand and nothing on the board.
for my $rules ('finkel', 'masters') {
    for my $side ('l', 'd') {
        my $row = $side eq 'l' ? 1 : 3;
        counted("H1, the start, $rules, " . ($side eq 'l' ? 'light' : 'dark'),
            "4xx2/8/4xx2 $side 7 0 7 0", $rules, {
                0 => [ '',             'nothing' ],
                1 => [ "hand-d$row",   'one move: enter at step 1' ],
                2 => [ "hand-c$row",   'one move: enter at step 2' ],
                3 => [ "hand-b$row",   'one move: enter at step 3' ],
                4 => [ "hand-a$row*",  'one move: enter at step 4, the rosette' ],
            }, 4);
    }
}

# H2. Short route. Light on b1 (3), a2 (5), g2 (11), h1 (13), two in hand, one
# home. Dark on d2, six in hand.
my $H2 = '4xx2/l2d2l1/1l2xx1l l 2 1 6 0';
counted('H2, finkel, light to move', $H2, 'finkel', {
    0 => [ '', 'nothing' ],
    1 => [ 'hand-d1 b1-a1* a2-b2 g2-h2 h1-g1*',
           'five: every candidate moves' ],
    2 => [ 'hand-c1 a2-c2 h1-home',
           'three: NOT b1 to a2 (own), NOT g2 to h1 (own)' ],
    3 => [ 'b1-b2 g2-g1*',
           'two: NOT hand to b1 (own), NOT a2 to d2 (an enemy on a safe rosette), NOT h1 (overshoots)' ],
    4 => [ 'hand-a1* b1-c2 a2-e2 g2-home',
           'four: NOT h1 (overshoots)' ],
}, 14);

counted('H2 again with the rosette not safe', $H2, { safe_rosettes => 0 }, {
    0 => [ '', 'nothing' ],
    1 => [ 'hand-d1 b1-a1* a2-b2 g2-h2 h1-g1*', 'five, as before' ],
    2 => [ 'hand-c1 a2-c2 h1-home', 'three, as before' ],
    3 => [ 'b1-b2 a2-d2x* g2-g1*', 'THREE: a2 to d2 now captures' ],
    4 => [ 'hand-a1* b1-c2 a2-e2 g2-home', 'four, as before' ],
}, 15);

# H3. Long route. Light on a2 (5), g2 (11), h2 (14), h1 (15), three in hand.
# Dark on g3, h3 and d2, four in hand.
my $H3 = '4xxdd/l2d2ll/4xx1l l 3 0 4 0';
counted('H3, masters, light to move', $H3, 'masters', {
    1 => [ 'hand-d1 a2-b2 g2-g3x* h1-g1*',
           'four, one a capture in the dark row: NOT h2 to h1 (own)' ],
    2 => [ 'hand-c1 a2-c2 g2-h3x h2-g1* h1-home',
           'five, one a capture' ],
    3 => [ 'hand-b1 a2-d2x* h2-home',
           'three, d2 captured because it is not safe: NOT g2 to h2 (own), NOT h1 (overshoots)' ],
    4 => [ 'hand-a1* a2-e2',
           'two: NOT g2 to h1 (own), NOT h2, NOT h1 (both overshoot)' ],
}, 14);

# H4. The same position with dark to move. Dark's g3 is its step 16, h3 its
# 15, d2 its 8. Light's h1 stands on dark's step 13 and light's h2 on dark's
# 14.
(my $H4 = $H3) =~ s/ l 3 0 4 0\z/ d 3 0 4 0/;
counted('H4, masters, dark to move', $H4, 'masters', {
    1 => [ 'hand-d3 d2-e2 g3-home',
           'three: NOT h3 to g3 (own)' ],
    2 => [ 'hand-c3 d2-f2 h3-home',
           'three: NOT g3 (overshoots)' ],
    3 => [ 'hand-b3 d2-g2x',
           'two, one a capture: h3 and g3 both overshoot' ],
    4 => [ 'hand-a3* d2-g1*',
           'two. THE SECOND IS THE LINE: g1 is DARK step 12, and it is empty' ],
}, 10);

# H5. One in hand and six on the board, and a roll of 1 moves every one.
my $H5 = '4xx2/1l1l1l1l/l1l1xx2 l 1 0 7 0';
for my $rules ('finkel', 'masters') {
    my ($bd) = $E->of_string($H5);
    is(scalar($bd->moves(1, $rules)), 7, "H5, $rules: seven moves, which is as many as there can be");
}
{
    my ($bd) = $E->of_string($H5);
    is(said($bd, 1, 'finkel'),  'hand-d1 c1-b1 a1-a2 b2-c2 d2-e2 f2-g2 h2-h1', 'short route, and these are they');
    is(said($bd, 1, 'masters'), 'hand-d1 c1-b1 a1-a2 b2-c2 d2-e2 f2-g2 h2-h1', 'the long route agrees on a 1');
    is(said($bd, 2, 'finkel'),  'h2-g1*',        'on a 2 the short route has one move');
    is(said($bd, 2, 'masters'), 'f2-g3* h2-g1*', 'and the long has two: f2 turns into the far row');
}

done_testing();
