use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use FnT qw(sq name text texts board);
my $E = 'Game::Fanorona::Engine';

# THE FIRST TWO PLIES, COUNTED BY HAND from the set-up and written down before
# the engine had produced a step.
#
#   5  b b b b b b b b b
#   4  b b b b b b b b b
#   3  b w b w . b w b w
#   2  w w w w w w w w w
#   1  w w w w w w w w w
#      a b c d e f g h i
#
# e3 is the only empty point, so every step goes there; and e3 is strong, so
# it can be reached along a diagonal, but only from d2 and f2, which are strong
# themselves. d4 and f4 are Black's.

my %FIRST = (
    'd3-e3Axf3'    => 'd3 east: f3 is black, g3 is white and stops the line',
    'd3-e3Wxc3'    => 'd3 east, away from c3: c3 is black, b3 is white and stops it',
    'e2-e3Axe4,e5' => 'e2 north: e4 and e5 are black, and then the board ends',
    'f2-e3Axd4,c5' => 'f2 north-west: d4 and c5 are black, and then the board ends',
    'd2-e3Axf4,g5' => 'd2 north-east: f4 and g5 are black, and then the board ends',
);

subtest 'White has exactly five steps, and each takes' => sub {
    my $bd = $E->new;
    my @steps = $bd->steps;
    is(scalar(@steps), 5, 'five');
    is(texts(@steps), join(' ', sort keys %FIRST), 'and they are the five');
    is(scalar(grep { $_->{to} != sq('e3') } @steps), 0, 'every one goes to e3');
    is(scalar(grep { $_->{kind} == PAIKA } @steps), 0, 'and none is a paika');
    note("$_: $FIRST{$_}") for sort keys %FIRST;

    # the three that have no withdrawal, because the point behind is White's
    is($bd->step_why(sq('e2'), N, WITHDRAWAL), WHY_TAKES_NOTHING, 'e2-e3 has no withdrawal: e1 is white');
    is($bd->step_why(sq('f2'), NW, WITHDRAWAL), WHY_TAKES_NOTHING, 'f2-e3 has none: g1 is white');
    is($bd->step_why(sq('d2'), NE, WITHDRAWAL), WHY_TAKES_NOTHING, 'd2-e3 has none: c1 is white');
    is($bd->step_why(sq('f3'), W, APPROACH), WHY_NOT_YOURS, 'and f3-e3 is Black\'s to make, not White\'s');
    is($bd->perft_steps(1), '5', 'perft 1 is 5');
};

# BLACK'S REPLIES, each board drawn after White's step. A step passes the turn
# at this version, so Black is to move in every one.
my %REPLY = (
    # 3  b w b . w . w b w     d3 and f3 are empty, both weak.
    #   into d3: c3 east (approach e3; withdrawal from b3) and d4 south
    #   (approach d2, d1). into f3: f4 south (approach f2, f1).
    'd3-e3Axf3' => [ 'c3-d3Axe3', 'c3-d3Wxb3', 'd4-d3Axd2,d1', 'f4-f3Axf2,f1' ],

    # 3  b w . . w b w b w     c3 is empty and strong, d3 empty and weak.
    #   into c3: c4 south (c2, c1), b4 south-east (d2, e1), d4 south-west
    #   (b2, a1). into d3: d4 south (d2, d1).
    'd3-e3Wxc3' => [ 'c4-c3Axc2,c1', 'b4-c3Axd2,e1', 'd4-c3Axb2,a1', 'd4-d3Axd2,d1' ],

    # 5  b b b b . b b b b
    # 4  b b b b . b b b b     e5, e4 and e2 are empty.
    # 3  b w b w w b w b w
    # 2  w w w w . w w w w
    #   Five black steps reach e4 or e5, and four take nothing. The fifth is
    #   f4 north-west to e5, which leaves g3 behind it: g3, h2 and i1 are white.
    #   So that is the only step, and the four paikas are not steps at all.
    'e2-e3Axe4,e5' => [ 'f4-e5Wxg3,h2,i1' ],

    # 5  b b . b b b b b b
    # 4  b b b . b b b b b     c5, d4 and f2 are empty.
    # 3  b w b w w b w b w
    # 2  w w w w w . w w w
    #   d5 south to d4 approaches d3, d2, d1. c3 north-east to d4 leaves b2, a1
    #   behind it. f3 south to f2 approaches f1.
    'f2-e3Axd4,c5' => [ 'd5-d4Axd3,d2,d1', 'c3-d4Wxb2,a1', 'f3-f2Axf1' ],

    # 5  b b b b b b . b b
    # 4  b b b b b . b b b     g5, f4 and d2 are empty.
    # 3  b w b w w b w b w
    # 2  w w w . w w w w w
    #   e5 south-east to f4 approaches g3, h2, i1. f3 north to f4 leaves f2, f1.
    #   g4 north to g5 leaves g3, g2, g1. h4 north-west to g5 leaves i3.
    #   c3 south-east to d2 approaches e1.
    'd2-e3Axf4,g5' => [ 'e5-f4Axg3,h2,i1', 'f3-f4Wxf2,f1', 'g4-g5Wxg3,g2,g1', 'h4-g5Wxi3', 'c3-d2Axe1' ],
);

subtest 'Black\'s replies to each of the five' => sub {
    is_deeply([ sort keys %REPLY ], [ sort keys %FIRST ], 'a reply list for each of the five');
    my $total = 0;
    for my $first (sort keys %REPLY) {
        my $bd = $E->new;
        my ($step) = grep { text($_) eq $first } $bd->steps;
        ok($step, "$first is a step") or next;
        $bd->do_step($step);
        is($bd->side, BLACK, "after $first it is Black to move");
        is(texts($bd->steps), join(' ', sort @{ $REPLY{$first} }),
            "after $first: " . scalar(@{ $REPLY{$first} }) . ' replies, as counted');
        $total += @{ $REPLY{$first} };
    }
    is($total, 17, 'seventeen in all');
    is($E->new->perft_steps(2), '17', 'and perft 2 is 17');
};

# After e2-e3 the obligation is doing the work: Black has five steps into the
# two empty points, and only the one that takes is a step.
subtest 'the four paikas the obligation removes' => sub {
    my $bd = $E->new;
    my ($step) = grep { text($_) eq 'e2-e3Axe4,e5' } $bd->steps;
    $bd->do_step($step);
    my @raw = map { $bd->steps_of(sq($_)) } qw(d4 f4 d5 f5);
    is(texts(@raw), 'd4-e4 d4-e5 d5-e5 f4-e4 f4-e5Wxg3,h2,i1 f5-e5',
        'the four stones round the hole have six steps between them');
    is(scalar($bd->steps), 1, 'and one of the six is a step');
    is($bd->step_why(sq('d4'), E, PAIKA), WHY_MUST_CAPTURE, 'd4-e4 is refused: a capture is there to be made');
};

# THE LADDER. 5 and 17 are counted above. The rest are the twin's, which
# counted them from the rules text in another language, and the engine's,
# which agree. A step passes the turn in this count, so it is NOT the game's
# perft: it is the generator's.
subtest 'the ladder' => sub {
    my $bd = $E->new;
    my $before = $bd->to_string;
    is_deeply([ map { $bd->perft_steps($_) } 0 .. 5 ], [ qw(1 5 17 100 647 4404) ], '1, 5, 17, 100, 647, 4404');
    like($bd->perft_steps(5), qr/\A[0-9]+\z/, 'a count is a string of digits');
    is($bd->to_string, $before, 'and counting leaves the board as it was');
    is($bd->key_hex, $bd->key_full_hex, 'key and all');
};

done_testing();
