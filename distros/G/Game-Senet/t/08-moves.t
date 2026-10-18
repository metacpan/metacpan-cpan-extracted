use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

# EACH BRANCH OF THE GENERATOR, from a position written for it, under each set
# where the set changes the answer. Light to move unless the string says d.
#
# THE BACKWARD FALLBACK IS EVERYWHERE. A position that refuses every forward
# move answers with backward moves, so each line below says what the backward
# moves are too, or why there are none.

sub t {
    my ($position, $roll, $set, $only) = @_;
    return join ' ', map { $_->trace } $E->new(position => $position)->moves($roll, $set, $only);
}

subtest 'the side\'s own piece on the landing house' => sub {
    is(t('l.l......./........../.......... l 5', 2, 'kendall'), '3>5', 'not 1>3: own; 3>5 moves');
};

subtest 'an enemy on a safe house is not swapped' => sub {
    for my $set (qw(kendall skyruk)) {
        is(t('........../l...d...../.......... l 5', 4, $set), '11<7',
            "$set: 11>15 is refused, dark stands on 15, a safe house; so 11<7");
        is(t('........../........../....ld.... l 5', 1, $set), '25<24',
            "$set: 25>26 is refused, dark stands on 26, a safe house; so 25<24");
    }
    is(t('........../l...d...../.......... l 5', 4, { exits => 'kendall', backward => 0 }), '',
        'without the fallback, nothing: the refusal was the safe house and not something else');
};

subtest 'a lone enemy is swapped, forward and backward' => sub {
    is(t('l...d...../........../.......... l 5', 4, 'kendall'), '1>5x', 'forward');
    is(t('........../........../l...ld.... l 5', 4, 'kendall'), '21<17',
        'no forward on a 4: 21>25 own, 25 past 26. Backward 25<21 lands on own, so 21<17 alone');
};

subtest 'a backward swap sends the enemy forward (G5)' => sub {
    my ($m) = $E->new(position => '........../.........d/.l.l.d.... l 5')->moves(2, 'kendall');
    is($m->trace, '22<20x', 'the move');
    ok($m->back && $m->swap, 'backward and a swap');
    is($m->from, 22, 'from 22, which is where dark goes: AHEAD of where it stood');
};

subtest 'a run of two and of three, landed on and passed' => sub {
    my $two = 'l....dd.../........../.......... l 5';
    is(t($two, 5, 'kendall'), '', 'kendall: 1>6 lands in a pair, protected; 1<-4 is no house');
    is(t($two, 5, 'skyruk'),  '', 'skyruk: 6 is an end of the pair, protected');

    my $pass2 = '.l..dd..../........../.......... l 5';
    is(t($pass2, 5, 'kendall'), '2>7', 'kendall: 2>7 passes the pair 5-6, no blockade');
    is(t($pass2, 5, 'skyruk'),  '',    'skyruk: the pair is a blockade; 2<-3 is no house');

    my $pass3 = '.l..ddd.../........../.......... l 5';
    is(t($pass3, 5, 'kendall'), '', 'kendall: 2>7 passes 5-6 of a run of three');
    is(t($pass3, 3, 'kendall'), '', 'kendall: 2>5 lands on an end of a run of three, protected');
    is(t('l...ddd.../........../.......... l 5', 3, 'kendall'), '1>4',
        'kendall: 1>4 lands on the house before the blockade');
    is(t('l...ddd..l/........../.......... l 5', 4, 'kendall'), '10>14',
        'kendall: 1>5 is refused, 10>14 moves');
};

subtest 'a run across houses 10 and 11 is one run' => sub {
    my $pos = '.......l.d/d........./.......... l 5';
    is(t($pos, 3, 'kendall'), '8<5',  'kendall: 8>11 lands on 11, in the run 10-11: protected, so back');
    is(t($pos, 4, 'kendall'), '8>12', 'kendall: 8>12 passes the pair, no blockade');
    is(t($pos, 4, 'skyruk'),  '8<4',  'skyruk: 8>12 passes the pair 10-11, a blockade, so back');
    is(t('d........./.........d/l......... l 5', 1, 'skyruk'), '21>22',
        'houses 1 and 20 share a column and are not a run');
    is(t('.........d/d........./.......... d 5', 1, 'kendall'), '11>12',
        'dark\'s own run 10-11 does not stop it: 10>11 own, 11>12 moves');
};

subtest 'skyruk from 24 and from 25' => sub {
    my $pos = '........../........../...l...... l 5';
    is(t($pos, 1, 'skyruk'), '24>25', 'roll 1 is a move');
    is(t($pos, 2, 'skyruk'), '24>26', 'roll 2 lands on 26');
    is(t($pos, $_, 'skyruk'), '24<' . (24 - $_), "roll $_ goes past 26 from 24, so back") for 3 .. 5;
    is(t('........../........../....l..... l 5', $_, 'skyruk'), '25>26', "from 25, roll $_ lands on 26")
        for 1 .. 5;
    is(t('........../........../....l..... l 5', 3, 'kendall'), '25<22', 'under kendall it does not');
    is(t('........../........../....ll.... l 5', 3, 'skyruk'), '26>29',
        'from 25 with its own piece on 26: not a move; 26 leaves by its chain (04), so nothing goes back');
    is(t('........../........../....ld.... l 5', 3, 'skyruk'), '25<22',
        'from 25 with dark on 26, a safe house: not a move either');
};

subtest 'a backward move that would reach house 0' => sub {
    is(t('.lddd...../........../.......... l 5', 3, 'kendall'), '',
        '2>5 passes a blockade; 2<-1 is no house: no move at all');
};

subtest 'a piece on 26 or beyond never moves back' => sub {
    is(t('........../........../.....l.lll l 5', 4, 'kendall'), '',
        'kendall, light on 26, 28, 29, 30 and a 4: 26>30 own, 28 to 30 have no 4. Nothing back');
    is(t('........../........../.l...l.lll l 5', 4, { exits => 'kendall', pieces => 5 }), '22<18',
        'with light on 22 as well, only 22 goes back');
};

subtest 'only' => sub {
    my $pos = 'l.l.l...../........../.......... l 5';
    is(t($pos, 1, 'kendall', 3), '3>4', 'only the piece on 3');
    is(t($pos, 1, 'kendall', 2), '',    'only a house with no piece of the side: nothing');
    is(t($pos, 1, 'kendall', 0), '1>2 3>4 5>6', '0 means any');
    is(t('l.l......./........../.......... l 5', 2, 'kendall', 1), '',
        'only restricts the backward fallback too: 1>3 own, 1<-1 no house, and 3 may not move');
    ok(!eval { t($pos, 1, 'kendall', 31); 1 }, 'only 31 croaks');
};

subtest 'the order is ascending house' => sub {
    is(t('l..l..l.../........../.......... l 5', 1, 'kendall'), '1>2 4>5 7>8', 'ascending forward');
    is(t('........../........../.l.l...... l 5', 5, 'kendall'), '22<17 24<19', 'and ascending backward');
};

subtest 'a roll of 0 or 6 is refused' => sub {
    my $bd = $E->new(position => 'l........./........../.......... l 5');
    for my $roll (0, 6, -1, 'five', '') {
        ok(!eval { $bd->moves($roll, 'kendall'); 1 }, "roll '$roll' croaks");
    }
    like($@, qr/a roll is a whole number of houses from 1 to 5/, 'with a sentence');
    ok(!eval { Game::Senet::Engine::_moves(0, 0, 'kendall', 0); 1 }, 'and so does the XSUB, for 0');
};

subtest 'a move is a Game::Senet::Move' => sub {
    my ($m) = $E->new(position => 'l...d...../........../.......... l 5')->moves(4, 'kendall');
    isa_ok($m, 'Game::Senet::Move');
    is($m->side, 'light', 'its side');
    is($m->roll, 4, 'its roll');
    is($m->from, 1, 'from');
    is($m->to, 5, 'to');
    is($m->swap, 1, 'a swap');
    is($m->back, 0, 'forward');
    is($m->off, 0, 'not off');
    is(scalar($E->new(position => 'l...d...../........../.......... d 5')->moves(1, 'kendall')), 1,
        'scalar context counts, and dark moves when dark is to move');
};

done_testing();
