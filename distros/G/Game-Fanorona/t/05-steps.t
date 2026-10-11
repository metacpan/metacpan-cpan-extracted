use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use FnT qw(sq name text texts board roller);
my $E = 'Game::Fanorona::Engine';

# EVERY POSITION HERE WAS WORKED OUT BY HAND and each names the sentence of the
# rules it is there for. The expected lists were written before the engine
# produced one.

subtest 'approach: the stone beyond the point moved to' => sub {
    #   . . w . b . .      c3 steps to d3 and stands next to e3
    my $bd = board('9/9/2w1b4/9/9 w');
    is(texts($bd->steps), 'c3-d3Axe3', 'c3-d3 takes e3, and it is the only step');
    my ($s) = $bd->steps;
    is($s->{kind}, APPROACH, 'by approach');
    is($s->{dir}, E, 'going east');
    is_deeply($s->{taken}, [ sq('e3') ], 'taking e3');
};

subtest 'withdrawal: the stone behind the point moved from' => sub {
    #   . . b w . . .      d3 steps to e3, away from c3
    my $bd = board('9/9/2bw5/9/9 w');
    is(texts($bd->steps), 'd3-e3Wxc3', 'd3-e3 takes c3');
    my ($s) = $bd->steps;
    is($s->{kind}, WITHDRAWAL, 'by withdrawal');
    is_deeply($s->{taken}, [ sq('c3') ], 'taking c3');
};

# "It is not allowed to capture by approach and withdrawal at the same time ...
# the player has to choose"
subtest 'one step, two lines, two entries' => sub {
    #   . . b w . b . . .
    my $bd = board('9/9/2bw1b3/9/9 w');
    is(texts($bd->steps), 'd3-e3Axf3 d3-e3Wxc3', 'd3-e3 is listed twice, once for each line');
    my %by = map { $_->{kind} => $_ } $bd->steps;
    is_deeply($by{ +APPROACH }{taken}, [ sq('f3') ], 'the approach takes f3 and not c3');
    is_deeply($by{ +WITHDRAWAL }{taken}, [ sq('c3') ], 'the withdrawal takes c3 and not f3');

    my $token = $bd->do_step($by{ +APPROACH });
    is($bd->at(sq('c3')), BLACK, 'after the approach, c3 still stands');
    is($bd->at(sq('f3')), EMPTY, 'and f3 is gone');
    $bd->undo_step($token);
    $bd->do_step($by{ +WITHDRAWAL });
    is($bd->at(sq('f3')), BLACK, 'after the withdrawal, f3 still stands');
    is($bd->at(sq('c3')), EMPTY, 'and c3 is gone');
};

# "all opponent pieces in line beyond that stone ... are captured as well"
subtest 'the whole line goes' => sub {
    my $seven = board('9/9/w1bbbbbbb/9/9 w');
    is(texts($seven->steps), 'a3-b3Axc3,d3,e3,f3,g3,h3,i3', 'an approach takes seven, nearest first');
    is($E->line_max, 7, 'and seven is the most a line can be');

    my $back = board('9/9/1wbbbbbbb/9/9 w');
    is(texts($back->steps), 'b3-a3Wxc3,d3,e3,f3,g3,h3,i3', 'a withdrawal takes seven too');

    my $up = board('4b4/4b4/9/4w4/9 w');
    is(texts($up->steps), 'e2-e3Axe4,e5', 'a line runs up a file as well as along a rank');

    my $slant = board('8b/7b1/9/5w3/9 w');
    is(texts($slant->steps), 'f2-g3Axh4,i5', 'and along a diagonal');
};

# "(as long as there is no interruption by an empty point or an own stone)"
subtest 'the line stops at a gap, and at an own stone' => sub {
    my $gap = board('9/9/w1bb1bb2/9/9 w');
    is(texts($gap->steps), 'a3-b3Axc3,d3', 'c3 and d3 go; f3 and g3 are past the gap and stay');

    my $own = board('9/9/w1bbwbb2/9/9 w');
    is(texts($own->steps), 'a3-b3Axc3,d3', 'c3 and d3 go; f3 and g3 are past a white stone and stay');
    # and the white stone on e3 takes nothing itself: both its neighbours on
    # the rank are occupied, and nothing lies beyond any empty point it has
    is(scalar(grep { $_->{from} == sq('e3') } $own->steps), 0, 'e3 has no capture of its own');
};

# "capturing 'around a corner' is not allowed"
subtest 'only along the line of the step' => sub {
    #  b2 to c3 is a diagonal step. c4 is next to c3 but not on that diagonal.
    my $bd = board('9/2b6/9/1w7/9 w');
    my @steps = $bd->steps;
    is(scalar(@steps), 8, 'b2 has its eight steps');
    is(scalar(grep { $_->{kind} != PAIKA } @steps), 0, 'and none of them takes c4');
    is($bd->step_why(sq('b2'), NE, APPROACH), WHY_TAKES_NOTHING, 'b2-c3 as an approach takes nothing');
};

# "f4 is too far away to capture c4 ... the piece has to be moved to an
# intersection adjacent to the captured piece"
subtest 'the enemy must be next to the step, not merely on its line' => sub {
    my $bd = board('9/2b2w3/9/9/9 w');
    my @steps = $bd->steps;
    is(scalar(@steps), 8, 'f4 has its eight steps');
    is(scalar(grep { $_->{kind} != PAIKA } @steps), 0, 'and f4-e4 does not take c4, two points further on');
};

# "on a strong intersection, it is also possible to move a stone diagonally"
subtest 'a diagonal capture needs a strong point' => sub {
    my $strong = board('9/3b5/9/1w7/9 w');
    is(texts($strong->steps), 'b2-c3Axd4', 'from b2, which is strong, c3 is a step and it takes d4');

    # the same picture one file to the right: c2 is weak
    my $weak = board('9/4b4/9/2w6/9 w');
    my @steps = $weak->steps;
    is(texts(@steps), 'c2-b2 c2-c1 c2-c3 c2-d2', 'from c2 there is no d3 to step to');
    is($weak->step_why(sq('c2'), NE, APPROACH), WHY_NO_LINE, 'and asking for it is answered: no line');
};

# "If any capturing moves are possible anywhere on the board, then a capturing
# move must be made."
subtest 'the obligation is global' => sub {
    my $bd = board('9/9/3w1b3/9/w8 w');
    is(texts($bd->steps), 'd3-e3Axf3', 'one stone can take, so the other stone has no step at all');
    is(texts($bd->steps_of(sq('a1'))), 'a1-a2 a1-b1 a1-b2', 'though steps_of still names what a1 could do');
    is($bd->step_why(sq('a1'), N, PAIKA), WHY_MUST_CAPTURE, 'and step_why says why not');
    ok($bd->can_capture, 'the side to move can capture');
    ok($bd->can_capture(WHITE), 'White can');
    # f3 could step to e3 and approach d3. (This line first said Black could
    # not, and the engine was right.)
    ok($bd->can_capture(BLACK), 'and so could Black, were it Black to move: f3-e3 approaches d3');

    # take the capture away and the paikas are steps again
    $bd->lift(sq('f3'));
    my @steps = $bd->steps;
    is(scalar(grep { $_->{from} == sq('a1') } @steps), 3, 'with nothing to take, a1 has its three paikas');
    is($bd->step_why(sq('a1'), N, PAIKA), WHY_OK, 'and step_why agrees');
    ok(!$bd->can_capture(WHITE), 'now White cannot capture');
    ok(!$bd->can_capture(BLACK), 'and with no black stone, nor can Black');
    ok(!$bd->can_capture(7), 'and a side that is not a side cannot');

    # WITH NO ARGUMENT IT IS THE SIDE TO MOVE, whichever that is. In the corner
    # a1 cannot get away from b1 along their line, and b1 can: c1 is empty.
    my $corner = board('9/9/9/9/wb7 b');
    ok($corner->can_capture, 'Black to move, and Black can capture: b1-c1 withdraws from a1');
    ok(!$corner->can_capture(WHITE), 'White could not');
    $corner->set_side(WHITE);
    ok(!$corner->can_capture, 'so with White to move the answer is no');
    is(texts($corner->steps), 'a1-a2 a1-b2', 'and White has its two paikas');
};

# A step that could take, takes: there is no moving there and declining.
subtest 'a step that takes is not also a paika' => sub {
    my $bd = board('9/9/3w1b3/9/9 w');
    is(scalar(grep { $_->{from} == sq('d3') && $_->{to} == sq('e3') } $bd->steps), 1, 'd3-e3 is listed once');
    is($bd->step_why(sq('d3'), E, PAIKA), WHY_NOT_A_PAIKA, 'and as a paika it is refused');
    is($bd->step_why(sq('d3'), E, APPROACH), WHY_OK, 'as an approach it is the step');
    is($bd->step_why(sq('d3'), E, WITHDRAWAL), WHY_TAKES_NOTHING, 'as a withdrawal it takes nothing');
};

# "If multiple captures are possible, you can choose which to do."
subtest 'the largest capture has no priority' => sub {
    #   w . b . w . b b b
    my $bd = board('9/9/w1b1w1bbb/9/9 w');
    is(texts($bd->steps), 'a3-b3Axc3 e3-d3Axc3 e3-f3Axg3,h3,i3', 'a capture of one is listed beside a capture of three');
};

subtest 'the side to move, and only that side' => sub {
    my $bd = board('9/9/2bw1b3/9/9 b');
    # Black's f3 can approach d3 by stepping to e3; c3 cannot move east, and
    # stepping west from c3 withdraws from d3.
    is(texts($bd->steps), 'c3-b3Wxd3 f3-e3Axd3', 'with Black to move the steps are Black\'s');
    is($bd->step_why(sq('d3'), E, APPROACH), WHY_NOT_YOURS, 'and White\'s stone is not theirs to move');
    is(texts($bd->steps_of(sq('d3'))), 'd3-d2 d3-d4 d3-e3Axf3 d3-e3Wxc3', 'steps_of does not care whose turn it is');
};

subtest 'why a step is not one, in the order it is asked' => sub {
    my $bd = board('9/9/2bw1b3/4w4/9 w');
    is($bd->step_why(0, N, PAIKA), WHY_OFF_BOARD, 'a point that is not a point');
    is($bd->step_why(sq('d3'), 8, PAIKA), WHY_BAD_STEP, 'a direction that is not one');
    is($bd->step_why(sq('d3'), N, 3), WHY_BAD_STEP, 'a kind that is not one');
    is($bd->step_why(sq('a1'), N, PAIKA), WHY_NO_STONE, 'an empty point');
    is($bd->step_why(sq('c3'), W, WITHDRAWAL), WHY_NOT_YOURS, 'the other side\'s stone');
    is($bd->step_why(sq('d3'), NE, PAIKA), WHY_NO_LINE, 'a diagonal from a weak point');
    is($bd->step_why(sq('d3'), W, APPROACH), WHY_OCCUPIED, 'a point with a stone on it');
    is($bd->step_why(sq('e2'), N, APPROACH), WHY_TAKES_NOTHING, 'an approach with nothing to approach');
    is($bd->step_why(sq('d3'), E, PAIKA), WHY_NOT_A_PAIKA, 'a paika that would take');
    is($bd->step_why(sq('e2'), S, PAIKA), WHY_MUST_CAPTURE, 'a paika while another stone can take');
    is($bd->step_why(sq('d3'), E, APPROACH), WHY_OK, 'and a step that is one');
    is($bd->step_why({ from => sq('d3'), dir => E, kind => WITHDRAWAL }), WHY_OK, 'given as a hash as well');
    is_deeply([ WHY_OK, WHY_OFF_BOARD, WHY_BAD_STEP, WHY_NO_STONE, WHY_NOT_YOURS, WHY_NO_LINE,
                WHY_OCCUPIED, WHY_TAKES_NOTHING, WHY_NOT_A_PAIKA, WHY_MUST_CAPTURE ], [ 0 .. 9 ],
        'the codes are 0 to 9 in the order they are asked');

    my $edge = board('9/9/9/9/w8 w');
    is($edge->step_why(sq('a1'), S, PAIKA), WHY_NO_LINE, 'and a step off the edge is no line too');
};

# step_why agrees with the list on every stone, direction and kind.
subtest 'step_why is the list' => sub {
    my $roll = roller(2026);
    my ($asked, @bad) = (0);
    for my $i (1 .. 60) {
        my $bd = $E->new(empty => 1);
        my @all = $bd->all_squares;
        my $stones = 2 + $roll->(30);
        $bd->put($all[ $roll->(45) ], $roll->(2) ? WHITE : BLACK) for 1 .. $stones;
        $bd->set_side($roll->(2) ? WHITE : BLACK);
        my %legal = map { join(',', @{$_}{qw(from dir kind)}) => 1 } $bd->steps;
        for my $from (@all) {
            for my $dir (0 .. 7) {
                for my $kind (PAIKA, APPROACH, WITHDRAWAL) {
                    $asked++;
                    my $ok = $bd->step_why($from, $dir, $kind) == WHY_OK;
                    push @bad, $bd->to_string . ' ' . name($from) . " dir $dir kind $kind"
                        if $ok != !!$legal{"$from,$dir,$kind"};
                }
            }
        }
    }
    is($asked, 60 * 45 * 8 * 3, "$asked questions asked");
    is(scalar(@bad), 0, 'and step_why says OK exactly when the step is in the list')
        or diag join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)];
};

subtest 'the list is in point order, and never too long' => sub {
    my $bd = board('9/9/9/1w5w1/w7w w');
    my @from = map { name($_->{from}) } $bd->steps;
    my %first;
    my @order = grep { !$first{$_}++ } @from;
    is("@order", 'a1 i1 b2 h2', 'a1 first, along each rank in turn');
    my @dirs = map { $_->{dir} } grep { $_->{from} == sq('b2') } $bd->steps;
    is_deeply(\@dirs, [ sort { $a <=> $b } @dirs ], 'and each stone\'s steps go clockwise from north');
    is($E->steps_max, 216, 'a caller is told to keep room for 216');
    is(scalar($bd->steps), scalar(@from), 'in scalar context, steps is their number');

    my $none = board('9/9/9/9/b8 w');
    is(scalar(my @empty = $none->steps), 0, 'a side with no stones has no steps');
};

done_testing();
