use strict;
use warnings;
use Test::More;

use Game::Senet::Engine;
my $E = 'Game::Senet::Engine';

# H1 TO H6 OF plan_game_senet/03, COUNTED BY HAND. The only numbers in the
# phase no program produced: counted from 00's tables when 03 was written, and
# counted again with that file closed before this one was. Light to move in
# each. A trace is the house moved from, > forward or < backward, the house
# moved to, x a swap. Each line carries the rule that makes it.

my %SETS = (
    'kendall'       => 'kendall',
    'skyruk'        => 'skyruk',
    'ends-open'     => { exits => 'skyruk', blockade => 0 },
    'masters-shape' => { protect => 'none', blockade => 0, backward => 0 },
);

sub traces {
    my ($position, $roll, $set) = @_;
    my $bd = $E->new(position => $position);
    return join ' ', map { $_->trace } $bd->moves($roll, $SETS{$set});
}

sub check {
    my ($name, $position, $set, $rows, $total) = @_;
    subtest "$name under $set" => sub {
        my $sum = 0;
        for my $row (@$rows) {
            my ($roll, $want, $why) = @$row;
            is(traces($position, $roll, $set), $want, "roll $roll: $why");
            $sum += () = $want =~ /\S+/g;
        }
        is($sum, $total, "$total moves in all");
    };
}

my $H1 = 'dldldldldl/........../.......... l 5';
for my $set (qw(kendall skyruk masters-shape)) {
    check('H1, the start', $H1, $set, [
        [ 1, '2>3x 4>5x 6>7x 8>9x 10>11', 'every piece a run of one: nothing protected, nothing blocks' ],
        [ 2, '10>12',                     'not 2, 4, 6, 8: an own piece two on' ],
        [ 3, '2>5x 4>7x 6>9x 8>11 10>13', 'a lone dark piece passed is no blockade' ],
        [ 4, '8>12 10>14',                'not 2, 4, 6: own' ],
        [ 5, '2>7x 4>9x 6>11 8>13 10>15', 'an empty 15 is a house like any other' ],
    ], 18);
}

my $H2 = '.....lld.d/d.l.dl..../..ld...... l 5';
check('H2, the swap', $H2, 'kendall', [
    [ 1, '7>8x 13>14 16>17 23>24x', 'not 6 (own); 7>8x breaks light\'s own run, which does not matter' ],
    [ 2, '6>8x 7>9 16>18 23>25',    'not 13: dark stands on 15, a safe house' ],
    [ 3, '6>9 16>19 23>26',         'not 7: 10 protected; not 13: own on 16' ],
    [ 4, '13>17 16>20',             'not 6, 7: 10 and 11 protected; not 23: past 26' ],
    [ 5, '7>12 13>18 16>21',        '7>12 passes 10-11: a pair is no blockade under kendall' ],
], 16);
check('H2, the swap', $H2, 'skyruk', [
    [ 1, '7>8x 13>14 16>17 23>24x', 'as kendall' ],
    [ 2, '6>8x 7>9 16>18 23>25',    'as kendall' ],
    [ 3, '6>9 16>19 23>26',         'not 7: 10 is an end of 10-11, protected' ],
    [ 4, '13>17 16>20',             'not 23: from 23, past 26 is not a move under any' ],
    [ 5, '13>18 16>21',             'not 7>12: 10-11 is a blockade of two under skyruk' ],
], 15);

my $H3 = '...l..ddd./.l.l..dd../l...l..... l 5';
check('H3, protection and the blockade', $H3, 'kendall', [
    [ 1, '4>5 12>13 14>15 21>22 25>26', '25>26 lands exactly' ],
    [ 2, '4>6 14>16 21>23',             '4>6 lands on the house before a blockade; not 12 (own); not 25: past 26' ],
    [ 3, '12>15 21>24',                 'not 4: 7 protected; not 14: 17 protected' ],
    [ 4, '12>16',                       'not 4>8: passes 7 of a blockade; not 14>18: protected; not 21: own on 25' ],
    [ 5, '14>19 21>26',                 '14>19 passes 17-18, a pair: no blockade under kendall' ],
], 13);
check('H3, protection and the blockade', $H3, 'skyruk', [
    [ 1, '4>5 12>13 14>15 21>22 25>26', 'as kendall' ],
    [ 2, '4>6 14>16 21>23 25>26',       '25>26: from 25 any roll reaches 26' ],
    [ 3, '12>15 21>24 25>26',           'not 4: 7 is an end; not 14: 17 is an end' ],
    [ 4, '12>16 25>26',                 'not 4>8: passes 7; not 14>18: passes 17, a blockade of two' ],
    [ 5, '21>26 25>26',                 'not 14>19: passes 17-18' ],
], 16);
check('H3, protection and the blockade', $H3, 'ends-open', [
    [ 1, '4>5 12>13 14>15 21>22 25>26', 'as skyruk' ],
    [ 2, '4>6 14>16 21>23 25>26',       'as skyruk' ],
    [ 3, '12>15 21>24 25>26',           'the ends are still protected' ],
    [ 4, '4>8x 12>16 25>26',            '4>8x: THE INNER PIECE OF 7-8-9, reachable once nothing blocks' ],
    [ 5, '14>19 21>26 25>26',           '14>19: nothing blocks' ],
], 18);

my $H4 = '........../.........d/.l.l.d.... l 5';
for my $set (qw(kendall skyruk)) {
    check('H4, backward with a swap', $H4, $set, [
        [ 1, '22>23 24>25', 'a forward move exists, so nothing backward' ],
        [ 2, '22<20x',      'no forward: 22>24 own, 24>26 a safe house held. Dark goes to 22 (G5)' ],
        [ 3, '22>25',       'forward' ],
        [ 4, '22<18 24<20x', '24<20x passes light\'s own 22' ],
        [ 5, '22<17 24<19', 'no forward: both past 26' ],
    ], 8);
}
check('H4, backward with a swap', $H4, 'masters-shape', [
    [ 1, '22>23 24>25', 'forward' ],
    [ 2, '',            'no backward moves: a forfeit' ],
    [ 3, '22>25',       'forward' ],
    [ 4, '',            'a forfeit' ],
    [ 5, '',            'a forfeit' ],
], 3);

my $H5 = '........../........dd/.l.l.d.... l 5';
check('H5, backward through a pair', $H5, 'kendall', [
    [ 1, '22>23 24>25', 'forward' ],
    [ 2, '',            '22<20: 20 protected. A forfeit' ],
    [ 3, '22>25',       'forward' ],
    [ 4, '22<18',       '22<18 passes 19-20, no blockade under kendall; 24<20 protected' ],
    [ 5, '22<17',       '24<19 protected' ],
], 5);
check('H5, backward through a pair', $H5, 'skyruk', [
    [ 1, '22>23 24>25', 'forward' ],
    [ 2, '',            '20 is an end: protected' ],
    [ 3, '22>25',       'forward' ],
    [ 4, '',            '22<18 passes 19-20, a blockade backward too (G8); 24<20 an end' ],
    [ 5, '',            '22<17 passes it; 24<19 an end, and passes 20' ],
], 3);

my $H6 = 'dldldldldl/dldl....../.......... l 7';
for my $set (qw(kendall skyruk)) {
    check('H6, seven moves', $H6, $set, [
        [ 1, '2>3x 4>5x 6>7x 8>9x 10>11x 12>13x 14>15', 'SEN_MOVES_MAX moves' ],
    ], 7);
}

done_testing();
