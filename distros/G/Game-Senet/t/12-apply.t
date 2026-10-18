use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

# A MOVE MADE, plan_game_senet/04: apply, the side to move afterwards, unapply,
# and the forfeit. Whose turn it is follows the roll just thrown: a 1, 4 or 5
# keeps it, a 2 or 3 passes it, whatever was done with the throw.

sub play {
    my ($position, $roll, $set, $trace, $only) = @_;
    my $bd = $E->new(position => $position);
    my ($m) = grep { $_->trace eq $trace } $bd->moves($roll, $set, $only);
    die "no move $trace on a $roll in $position\n" unless $m;
    my ($undo, $bound) = $bd->apply($m, $set);
    return ($bd, $bound, $undo);
}

subtest 'the turn table, row by row' => sub {
    my $pos = 'l.......d./........../.......... l 5';
    my ($bd) = play($pos, 2, 'kendall', '1>3');
    is($bd->side, SIDE_DARK, 'a forward move on a 2: the other side');
    ($bd) = play($pos, 1, 'kendall', '1>2');
    is($bd->side, SIDE_LIGHT, 'a forward move on a 1: the same side');
    ($bd) = play('........../.........d/.l.l.d.... l 5', 4, 'kendall', '24<20x');
    is($bd->side, SIDE_LIGHT, 'a backward swap on a 4: the same side');
    ($bd) = play('........../.........d/.l.l.d.... l 5', 2, 'kendall', '22<20x');
    is($bd->side, SIDE_DARK, 'a backward swap on a 2: the other side');
    ($bd) = play('........../........../.l.....l.l l 5', 3, 'kendall', '28>off');
    is($bd->side, SIDE_DARK, 'a bear-off on a 3 that does not win: the other side');
    ($bd) = play('l........./........../.........l l 5', 1, 'kendall', '30>off');
    is($bd->side, SIDE_LIGHT, 'a bear-off on a 1 that does not win: the same side (G14)');
    is($bd->home(SIDE_LIGHT), 4, '  and light has four home');
};

subtest 'a forfeit follows the roll too' => sub {
    my $bd = $E->new(position => 'l.ddd...../........../.......... l 5');
    is(scalar($bd->moves(2, 'kendall')), 0, 'light on 1 has nothing on a 2: 1>3 is protected');
    $bd->forfeit(2);
    is($bd->side, SIDE_DARK, 'a forfeit on a 2 passes the turn');
    is($bd->ply, 1, 'and is a ply');
    $bd = $E->new(position => 'l.ddd...../........../.......... l 5');
    $bd->forfeit(4);
    is($bd->side, SIDE_LIGHT, 'a forfeit on a 4 keeps it (G3)');
    my $water = $E->new(position => '........../....d...../......l... l 5');
    is(scalar($water->moves(5, 'skyruk')), 0, 'skyruk: a piece in the water on a 5 stays, which is no move');
    $water->forfeit(5);
    is($water->side, SIDE_LIGHT, 'and the throw still gives another throw (M2: G3 is built)');
    ok(!eval { $water->forfeit(0); 1 }, 'a forfeit of roll 0 croaks: it is a throw');
};

subtest 'skyruk: the throw on 26' => sub {
    my ($bd, $bound) = play('........../........../...l...... l 5', 2, 'skyruk', '24>26');
    is($bound, 26, 'a piece arriving on 26 binds the next throw to it');
    is($bd->side, SIDE_LIGHT, 'and light throws again, though the roll was a 2');
    ($bd, $bound) = play('........../........../....l..... l 5', 4, 'skyruk', '25>26');
    is($bound, 26, 'arriving on a 4, the same');
    is($bd->side, SIDE_LIGHT, 'ONE more throw, not two: the binding is the extra throw');
    is(join(' ', map { $_->trace } $bd->moves(2, 'skyruk', $bound)), '26>28', 'that throw moves the piece on 26');
    my ($m) = $bd->moves(2, 'skyruk', $bound);
    my (undef, $after) = $bd->apply($m, 'skyruk');
    is($after, 0, 'and binds nothing further');
    is($bd->side, SIDE_DARK, 'its own roll, a 2, passes the turn');
    ($bd, $bound) = play('........../........../...l...... l 5', 2, 'kendall', '24>26');
    is($bound, 0, 'kendall has no throw on 26');
    is($bd->side, SIDE_DARK, 'and a 2 passes');
};

subtest 'the move that wins' => sub {
    my ($bd) = play('........../........../.........l l 1', 1, { exits => 'kendall', pieces => 1 }, '30>off');
    is($bd->status, WON, 'light\'s last piece off: won');
    is($bd->winner, SIDE_LIGHT, 'by light');
    is($bd->how, BY_HOME, 'by bearing off');
    is($bd->side, SIDE_LIGHT, 'and the side does not change after the move that wins');
};

subtest 'a swap is an exchange' => sub {
    my ($bd) = play('l...d...../........../.......... l 5', 4, 'kendall', '1>5x');
    is($bd->at(5), LIGHT, 'light lands on 5');
    is($bd->at(1), DARK, 'dark is on 1, where light left');
    is($bd->count(SIDE_DARK), 1, 'and nowhere else');
    ($bd) = play('........../.........d/.l.l.d.... l 5', 2, 'kendall', '22<20x');
    is($bd->at(20), LIGHT, 'backward: light lands on 20');
    is($bd->at(22), DARK, 'and dark goes FORWARD to 22 (G5)');
};

subtest 'apply asks only that the mover is on from' => sub {
    my $bd = $E->new(position => 'l...d...../........../.......... l 5');
    my $m = Game::Senet::Move->new(side => 'light', roll => 2, from => 3, to => 5, swap => 0, back => 0, off => 0);
    my ($undo) = $bd->apply($m, 'kendall');
    ok(!defined $undo, 'no light piece on 3: not made');
    is($bd->to_string, 'l...d...../........../.......... l 5', 'and nothing changed');
};

# APPLY THEN UNAPPLY, over random games: every move tried, undone, and the
# position compared, then one of them played on.
for my $set (qw(kendall skyruk)) {
    subtest "apply and unapply restore the position, $set" => sub {
        srand($set eq 'kendall' ? 41 : 42);
        my ($tried, $forfeits, $swaps, $walks, $offs, @bad) = (0, 0, 0, 0, 0);
        my $bd = $E->new(position => 'dldldldldl/........../.......... l 5');
        my $bound = 0;
        while ($tried < 5_000) {
            if ($bd->status != ONGOING) {
                $bd = $E->new(position => 'dldldldldl/........../.......... l 5');
                $bound = 0;
            }
            my $roll = 1 + int(rand(5));
            my @moves = $bd->moves($roll, $set, $bound);
            my $before = join '|', $bd->to_string, $bd->key_hex, $bd->side, $bd->ply;
            if (!@moves) {
                my $undo = $bd->forfeit($roll);
                $bd->unapply($undo);
                push @bad, "forfeit $before" unless $before eq join '|', $bd->to_string, $bd->key_hex, $bd->side, $bd->ply;
                $bd->forfeit($roll);
                $bound = 0;
                $forfeits++;
                $tried++;
                next;
            }
            for my $m (@moves) {
                my ($undo) = $bd->apply($m, $set);
                $bd->unapply($undo);
                my $after = join '|', $bd->to_string, $bd->key_hex, $bd->side, $bd->ply;
                push @bad, $m->trace . " $before" unless $after eq $before;
                $swaps++ if $m->swap;
                $walks++ if $m->walk;
                $offs++  if $m->off;
                $tried++;
            }
            my (undef, $b2) = $bd->apply($moves[ int(rand(@moves)) ], $set);
            $bound = $b2;
        }
        is("@bad", '', "$tried moves and forfeits undone exactly");
        cmp_ok($forfeits, '>', 0, "forfeits among them ($forfeits)");
        cmp_ok($swaps, '>', 0, "swaps ($swaps)");
        cmp_ok($walks, '>', 0, "walks ($walks)");
        cmp_ok($offs, '>', 0, "bear-offs ($offs)");
    };
}

done_testing();
