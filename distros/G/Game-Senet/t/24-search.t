use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

=pod

THE SEARCH, CHECKED BY HAND.

The position: light's last piece on 30, dark's last on 29, kendall, light to
throw, valued for light. Light's progress is 4 * 31 + 30 = 154 and dark's
4 * 31 + 29 = 153, so the plain evaluation is 16 * (154 - 153) = 16.

Light bears off only on a roll of 1 (4 in 16). A 4 or a 5 (1 in 16 each) is a
forfeit that keeps the sticks; a 2 or a 3 (6 and 4 in 16) passes them. Dark
bears off only on a 2.

Depth 1, one throw:

    roll 1, light wins at depth 0:      4 * 1,000,000 = 4,000,000
    rolls 2 to 5, forfeits, evaluated:  12 * 16       =       192
    (4,000,000 + 192) / 16                            =   250,012

Depth 2, two throws:

    roll 1, light wins at depth 1:      4 * 1,000,001 =  4,000,004
    roll 2 or 3, dark to throw at depth 1:
        dark's 2 wins at depth 0:  6 * -1,000,000     = -6,000,000
        dark's 1, 3, 4, 5 forfeit: 10 * 16            =        160
        (-6,000,000 + 160) / 16, toward zero          =   -374,990
    weighted:                           10 * -374,990 = -3,749,900
    roll 4 or 5, light throws again at depth 1, which is depth 1 above:
                                        2 * 250,012   =    500,024
    (4,000,004 - 3,749,900 + 500,024) / 16 = 750,128 / 16 =   46,883

The last two rows are a chain: after a forfeit on a 4 or a 5 the node below is
light's own again, a max over a max, not dark's.

Under skyruk the same piece bears off on any roll, so at depth 1 every throw
wins: exactly 1,000,000.

=cut

my $END = '........../........../........dl l 5';

subtest 'the hand-worked values' => sub {
    my $bd = $E->new(position => $END);
    is($bd->evaluate(SIDE_LIGHT, 'kendall'), 16, 'the plain evaluation is 16');
    is($bd->expect(1, rules => 'kendall'), 250_012, 'depth 1: 250,012');
    is($bd->expect(2, rules => 'kendall'), 46_883, 'depth 2: 46,883');
    is($bd->expect(1, rules => 'skyruk'), WIN, 'skyruk, depth 1: exactly a win');
    is($bd->expect(1, rules => 'kendall', side => SIDE_DARK), -250_012, 'and for dark, the same with the sign turned');
};

subtest 'a win in one is taken at every depth' => sub {
    my $bd = $E->new(position => 'd........./........../........l. l 5');
    my @moves = map { $_->trace } $bd->moves(2, 'kendall');
    is("@moves", '29>off', 'on a 2 light\'s last piece bears off from 29');
    for my $depth (1 .. 4) {
        my $found = $bd->search(2, rules => 'kendall', depth => $depth);
        is($moves[ $found->{index} ], '29>off', "depth $depth bears off");
        cmp_ok($found->{value}, '>=', WIN, '  and values it a win');
    }
};

subtest 'a piece left exposed to a swap is seen at depth 2' => sub {
    my $bd = $E->new(position => '.......d.l/..l......./.......... l 5');
    my @moves = map { $_->trace } $bd->moves(2, 'kendall');
    is("@moves", '10>12 13>15', 'on a 2, which passes the sticks: make the pair 12-13, or leave 10 alone');
    my $one = $bd->search(2, rules => 'kendall', depth => 1);
    is($moves[ $one->{index} ], '13>15', 'depth 1 sees two equal moves and takes the later');
    my $two = $bd->search(2, rules => 'kendall', depth => 2);
    is($moves[ $two->{index} ], '10>12', 'depth 2 sees dark\'s 2 swapping with the piece left on 10, and makes the pair');
};

subtest 'a bound throw searches the bound piece alone' => sub {
    my $bd = $E->new(position => 'd........./........../.l...l.... l 5');
    my @all = map { $_->trace } $bd->moves(3, 'skyruk');
    is("@all", '22>25 26>29', 'unbound, a 3 moves 22 or 26');
    my @bound = map { $_->trace } $bd->moves(3, 'skyruk', 26);
    is("@bound", '26>29', 'bound, 26 alone');
    my $found = $bd->search(3, rules => 'skyruk', depth => 3, only => 26);
    is($bound[ $found->{index} ], '26>29', 'and the search answers an index into the bound list');
};

subtest 'a finished position' => sub {
    my $bd = $E->new(position => 'd........./........../.......... d 5');
    is($bd->status, WON, 'light has nothing on the board: won');
    is($bd->expect(3, rules => 'kendall', side => SIDE_LIGHT), WIN + 3, 'worth a win, and the depth in hand');
    is($bd->expect(3, rules => 'kendall', side => SIDE_DARK), -(WIN + 3), 'and a loss for dark');
    is($bd->search(1, rules => 'kendall')->{index}, -1, 'and there is nothing to search');
};

subtest 'the search leaves the board as it found it' => sub {
    srand(24);
    my @bad;
    for my $n (1 .. 2_000) {
        my $bd = $E->new(pieces => 5);
        for my $side (0, 1) {
            my $want = 1 + int(rand(5));
            while ($want) {
                my $h = 1 + int(rand(30));
                next if $bd->at($h);
                $bd->put($h, $side + 1);
                $want--;
            }
        }
        $bd->set_side(int(rand(2)));
        $bd->set_ply(int(rand(100)));
        my $before = join '|', $bd->key_hex, $bd->side, $bd->ply;
        my $roll = 1 + int(rand(5));
        $bd->search($roll, rules => ($n % 2 ? 'kendall' : 'skyruk'), depth => 2);
        $bd->expect(1, rules => 'kendall');
        push @bad, $before unless join('|', $bd->key_hex, $bd->side, $bd->ply) eq $before;
    }
    is(scalar @bad, 0, '2,000 searches, and the key, the side and the ply untouched');
};

# THE SEARCH AGAINST A PLAIN EXPECTIMINIMAX IN PERL, written from plan_game_senet/07
# over the engine's own moves, apply and forfeit, and nothing of the C search.
# Every structural slip, a sign, a weight, a lost bound piece, a board not put
# back, shows here as a different number.
sub pvalue {
    my ($bd, $set, $depth, $only, $root) = @_;
    my $winner = $bd->winner;
    return $winner == $root ? WIN + $depth : -(WIN + $depth) if $winner >= 0;
    return 0 if $bd->status != ONGOING;
    return $bd->evaluate($root, $set) if $depth == 0;
    my $sum = 0;
    for my $row ($E->chances) {
        my ($roll, $weight) = @$row;
        my @moves = $bd->moves($roll, $set, $only);
        my $best;
        if (!@moves) {
            my $undo = $bd->forfeit($roll);
            $best = pvalue($bd, $set, $depth - 1, 0, $root);
            $bd->unapply($undo);
        }
        else {
            my $ours = $bd->side == $root;
            for my $m (@moves) {
                my ($undo, $bound) = $bd->apply($m, $set);
                my $v = pvalue($bd, $set, $depth - 1, $bound, $root);
                $bd->unapply($undo);
                $best = $v if !defined $best || ($ours ? $v > $best : $v < $best);
            }
        }
        $sum += $weight * $best;
    }
    return $sum >= 0 ? int($sum / 16) : -int(-$sum / 16);
}

subtest 'the C search agrees with a plain expectiminimax in Perl' => sub {
    srand(2407);
    my ($n, @bad) = (0);
    for my $set (qw(kendall skyruk)) {
        for (1 .. 200) {
            my $bd = $E->new(pieces => 5);
            for my $side (0, 1) {
                my $want = 1 + int(rand(5));
                while ($want) {
                    my $h = 1 + int(rand(30));
                    next if $bd->at($h);
                    $bd->put($h, $side + 1);
                    $want--;
                }
            }
            $bd->set_side(int(rand(2)));
            my $root = int(rand(2));
            my $only = ($set eq 'skyruk' && $bd->at(26) == piece_of($bd->side) && rand() < 0.5) ? 26 : 0;
            my $mine = pvalue($bd, $set, 2, $only, $root);
            my $theirs = $bd->expect(2, rules => $set, side => $root, only => $only);
            $n++;
            push @bad, $bd->to_string . " root $root only $only: perl $mine, C $theirs" unless $mine == $theirs;
        }
    }
    is(scalar @bad, 0, "$n positions, both sets, two throws deep: the same value") or diag(join "\n", @bad[0 .. 4]);
};

subtest 'a piece at home counts 31, with homes that differ' => sub {
    my $bd = $E->new(position => 'dddd....../........../........ll l 5');
    is($bd->evaluate(SIDE_LIGHT, 'kendall'), 1_776,
        'light 3 home and on 29, 30; dark 1 home and on 1 to 4: 16 * ((3*31 + 59) - (31 + 10)) = 1,776');
    is($bd->evaluate(SIDE_DARK, 'kendall'), -1_776, 'and for dark the sign turned');
};

subtest 'the blockade term, worked by hand' => sub {
    my $bd = $E->new(position => 'd...d....l/l........./.......... l 5');
    is($bd->evaluate(SIDE_LIGHT, 'skyruk'), 240, 'light on 10 and 11, dark on 1 and 5: 16 * ((3*31 + 21) - (3*31 + 6)) = 240');
    is($bd->evaluate(SIDE_LIGHT, 'skyruk', { blockade => 64 }), 304,
        'skyruk: the pair 10-11 is a blockade of two with dark behind it: 240 + 64 = 304');
    is($bd->evaluate(SIDE_LIGHT, 'kendall', { blockade => 64 }), 240,
        'kendall: a pair is no blockade of three, and the term counts nothing');
    is($bd->evaluate(SIDE_DARK, 'skyruk', { blockade => 64 }), -304, 'and for dark the sign is turned');
    my $ahead = $E->new(position => '.........l/l...d...../d......... l 5');
    is($ahead->evaluate(SIDE_LIGHT, 'skyruk', { blockade => 64 }), $ahead->evaluate(SIDE_LIGHT, 'skyruk'),
        'with dark only AHEAD of the pair, 15 and 21, it blocks nobody and the term counts nothing');
};

done_testing();
