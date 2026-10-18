use strict;
use warnings;
use Test::More;

use Game::Senet::Rules;

# SCRIPTED GAMES, plan_game_senet/04. Each step is a roll, the move chosen (its
# trace, or 'forfeit'), and the position string expected after it, worked out
# by hand from the rules and typed here. The side in each string is the
# engine's answer to whose throw it is, which nothing in Perl computes.

sub script {
    my ($name, $rules, $start, @steps) = @_;
    subtest $name => sub {
        my $g = Game::Senet::Rules->new(rules => $rules, position => $start);
        my $ply = 0;
        for my $step (@steps) {
            my ($roll, $choice, $want, $only) = @$step;
            if ($choice eq 'forfeit') {
                is(scalar($g->moves($roll)), 0, "roll $roll allows nothing");
                $g->forfeit($roll);
            }
            else {
                my ($m) = grep { $_->trace eq $choice } $g->moves($roll);
                ok($m, "roll $roll offers $choice") or return;
                $g->apply($m);
            }
            $ply++;
            is($g->position, $want, "  then $want");
            is($g->only, $only // 0, '  bound to ' . ($only // 'nothing'));
        }
        is($g->ply, $ply, "$ply plies");
    };
}

script('kendall: a chain of four extra throws', 'kendall',
    'dldldldldl/........../.......... l 5',
    [ 1, '10>11', 'dldldldld./l........./.......... l 5' ],
    [ 4, '11>15', 'dldldldld./....l...../.......... l 5' ],
    [ 5, '15>20', 'dldldldld./.........l/.......... l 5' ],
    [ 1, '20>21', 'dldldldld./........../l......... l 5' ],
    [ 2, '21>23', 'dldldldld./........../..l....... d 5' ],
    [ 3, '9>12',  'dldldldl../.d......../..l....... l 5' ],
);

script('kendall: a forfeit on a 4 keeps the turn, on a 2 passes it', 'kendall',
    'l.ddd...../........../.......... l 5',
    [ 4, 'forfeit', 'l.ddd...../........../.......... l 5' ],
    [ 2, 'forfeit', 'l.ddd...../........../.......... d 5' ],
    [ 3, '5>8',     'l.dd...d../........../.......... l 5' ],
);

script('kendall: a backward move on a 5, then a bear-off on a 1 (G14)', 'kendall',
    'd........./........../.l.......l l 5',
    [ 5, '22<17',  'd........./......l.../.........l l 5' ],
    [ 1, '30>off', 'd........./......l.../.......... l 5' ],
    [ 2, '17>19',  'd........./........l./.......... d 5' ],
);

script('skyruk: 25>26 on a 2, the bound throw, then 22>26 on a 4 earning ONE throw', 'skyruk',
    'd........./........../.l..l..... l 5',
    [ 2, '25>26', 'd........./........../.l...l.... l 5', 26 ],
    [ 3, '26>29', 'd........./........../.l......l. d 5' ],
    [ 3, '1>4',   '...d....../........../.l......l. l 5' ],
    [ 4, '22>26', '...d....../........../.....l..l. l 5', 26 ],
    [ 2, '26>28', '...d....../........../.......ll. d 5' ],
);

script('skyruk: E4, a piece in the water on a 5, then off on a 4', 'skyruk',
    '........../....d...../......l... l 5',
    [ 5, 'forfeit', '........../....d...../......l... l 5' ],
    [ 4, '27>off',  '........../....d...../.......... l 5' ],
);

subtest 'the bound throw offers the bound piece alone' => sub {
    my $g = Game::Senet::Rules->new(rules => 'skyruk', position => 'd........./........../.l..l..... l 5');
    my ($m) = grep { $_->trace eq '25>26' } $g->moves(2);
    $g->apply($m);
    is(join(' ', map { $_->trace } $g->moves(3)), '26>29', 'only 26 moves: not 22>25');
    my ($other) = grep { $_->trace eq '22>25' }
        Game::Senet::Engine->new(position => $g->position)->moves(3, 'skyruk');
    is($g->apply($other), undef, 'and Rules refuses a move of another piece while bound');
    ok($g->undo, 'undo the move onto 26');
    is($g->only, 0, 'and the binding goes with it');
};

subtest 'the water game is won' => sub {
    my $g = Game::Senet::Rules->new(rules => 'skyruk', position => '........../....d...../......l... l 5');
    $g->forfeit(5);
    my ($m) = $g->moves(4);
    $g->apply($m);
    is($g->status, 'won', 'light\'s last piece borne off from the water');
    is($g->winner, 'light', 'light wins');
};

done_testing();
