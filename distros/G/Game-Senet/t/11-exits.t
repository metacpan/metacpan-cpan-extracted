use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

# THE MARKED HOUSES' EXITS, plan_game_senet/04. A piece on 26 to 30 does not
# count along the track: it reads its house's chain for the roll. An exit never
# swaps, and no blockade judges it.

sub t {
    my ($position, $roll, $set, $only) = @_;
    return join ' ', map { $_->trace } $E->new(position => $position)->moves($roll, $set, $only);
}

sub rolls {
    my ($position, $set) = @_;
    return [ map { t($position, $_, $set) } 1 .. 5 ];
}

subtest 'E1: H4 with light on 28, 29 and 30' => sub {
    my $pos = '........../.........d/.l.l.d.lll l 5';
    is_deeply(rolls($pos, 'kendall'),
        [ '22>23 24>25 30>off', '29>off', '22>25 28>off', '22<18 24<20x', '22<17 24<19' ],
        'kendall: ten, the exits exact, and rolls 4 and 5 fall back');
    is_deeply(rolls($pos, 'skyruk'),
        [ '22>23 24>25 30>off', '29>off 30>off', '22>25 28>off 30>off', '30>off', '30>off' ],
        'skyruk: ten, and 30 leaves on any roll, so nothing ever goes back while it stands');
};

subtest 'E2: light on 26 and 29, dark on 14, 15, 30' => sub {
    my $pos = '........../...dd...../.....l..ld l 5';
    is_deeply(rolls($pos, 'kendall'), [ '26>13', '26>28 29>off', '', '', '26>off' ],
        'kendall: four; the walk passes dark on 15 and 14; 3 and 4 are forfeits (29 own, 30 held)');
    is_deeply(rolls($pos, 'skyruk'), [ '26>27', '26>28 29>off', '26>27', '26>27', '26>off' ],
        'skyruk: six; 29 own and 30 held fall to the water');
};

subtest 'E3, skyruk: the walk passes light\'s own 13' => sub {
    is_deeply(rolls('........../..ldd...../.....ld... l 5', 'skyruk'),
        [ '26>12', '26>28', '26>29', '26>30', '26>off' ],
        'five, one a roll; 13 has nothing (14 an end, 15 safe, the pair a blockade)');
};

subtest 'E4, skyruk: a piece in the water' => sub {
    is_deeply(rolls('........../....d...../......l... l 5', 'skyruk'),
        [ '27>14', '27>14', '27>14', '27>off', '' ],
        'four; on a 5 it stays, which is not a move');
};

subtest 'E5: the fullest walk, kendall, seven pieces' => sub {
    my $pos = '..dldldldl/dldld...../.....l.... l 7';
    is(t($pos, 1, { exits => 'kendall', pieces => 7 }, 26), '26>2',
        'thirteen houses down, the deepest a walk can go');
    my ($m) = $E->new(position => $pos)->moves(1, { exits => 'kendall', pieces => 7 }, 26);
    ok($m->walk, 'and the move says it came by the walk');
};

# EACH ROW OF BOTH TABLES, a lone light piece on the house and nothing else.
my %ROW = (
    kendall => {
        26 => [ '26>15', '26>28', '26>29', '26>30', '26>off' ],
        27 => [ '', '', '', '', '' ],
        28 => [ '', '', '28>off', '', '' ],
        29 => [ '', '29>off', '', '', '' ],
        30 => [ '30>off', '', '', '', '' ],
    },
    skyruk => {
        26 => [ '26>27', '26>28', '26>29', '26>30', '26>off' ],
        27 => [ '27>15', '27>15', '27>15', '27>off', '' ],
        28 => [ '', '', '28>off', '', '' ],
        29 => [ '', '29>off', '', '', '' ],
        30 => [ '30>off', '30>off', '30>off', '30>off', '30>off' ],
    },
);

for my $set (qw(kendall skyruk)) {
    subtest "every row of $set\'s table" => sub {
        for my $h (26 .. 30) {
            my $flat = '.' x 30;
            substr($flat, $h - 1, 1) = 'l';
            my $pos = join('/', substr($flat, 0, 10), substr($flat, 10, 10), substr($flat, 20, 10)) . ' l 5';
            is_deeply(rolls($pos, $set), $ROW{$set}{$h}, "house $h");
        }
    };
}

subtest 'each step of each chain, the house before it held by each side' => sub {
    for my $who ('l', 'd') {
        my $p28 = '........../........../.....l.' . $who . '.. l 5';
        is(t($p28, 2, 'kendall', 26), '', "kendall 26 on a 2 with 28 held by $who: the chain is one long, not a move");
        is(t($p28, 2, 'skyruk', 26), '26>27', "skyruk 26 on a 2 with 28 held by $who: the water");
        my $p2728 = '........../........../.....l' . $who . $who . '.. l 5';
        is(t($p2728, 2, 'skyruk', 26), '26>15', "skyruk with 28 and 27 held by $who: the walk");
        my $p27 = '........../........../.....l' . $who . '... l 5';
        is(t($p27, 1, 'skyruk', 26), '26>15', "skyruk 26 on a 1 with 27 held by $who: the walk");
        is(t('........../....' . $who . '...../.....l.... l 5', 1, 'kendall', 26), '26>14',
            "kendall's walk past 15 held by $who");
    }
    is(t('........../....l...../.....l.... l 5', 1, 'kendall', 26), '26>14',
        'the walk passes 15 held by the MOVER\'s own side too');
    is(t('........../..ddd...../.....l.... l 5', 1, 'kendall'), '26>12',
        'and never swaps: it passes three dark pieces');
};

subtest 'an exit is not judged by the blockade (a decision)' => sub {
    is(t('........../........../.....ldddd l 5', 5, 'kendall'), '26>off',
        'kendall: 26 bears off on a 5 past dark on 27, 28, 29 and 30');
    is(t('........../........../.....ldd.. l 5', 3, 'skyruk'), '26>29',
        'skyruk: 26 reaches 29 past the dark pair on 27 and 28');
};

subtest 'an exit is a forward move, for the fallback' => sub {
    is(t('........../........../.l.......l l 5', 5, 'skyruk'), '30>off',
        'skyruk: 30 bears off on a 5, so 22 does not go back');
    is(t('........../........../.l.......l l 5', 5, 'kendall'), '22<17',
        'kendall: 30 has nothing on a 5, so 22 goes back');
};

subtest 'an overfull board where the walk finds nothing' => sub {
    my $bd = $E->new(pieces => 7);
    $bd->put($_, DARK) for 1 .. 15;
    $bd->put(26, LIGHT);
    ok(!$bd->consistent, 'fifteen dark pieces on a board of seven: not a position');
    is(join(' ', map { $_->trace } $bd->moves(1, { exits => 'kendall', pieces => 7 })), '',
        'the chain is exhausted, nothing crashes and nothing loops');
};

subtest 'the claim, by sampling: the walk always lands, and never too low' => sub {
    for my $pieces (5, 7) {
        my ($landed, $lowest) = Game::Senet::Engine::_sample_walk(100_000, 18 + $pieces, $pieces);
        is($landed, 100_000, "$pieces a side: 100,000 boards with every other piece on 1 to 15, and the walk landed on each");
        cmp_ok($lowest, '>=', 15 - (2 * $pieces - 1), "  never below house " . (15 - (2 * $pieces - 1)));
        cmp_ok($lowest, '>', 1, '  and never on house 1');
    }
};

done_testing();
