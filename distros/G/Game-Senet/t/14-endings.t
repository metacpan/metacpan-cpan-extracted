use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
use Game::Senet::Rules;
use Game::Senet::Sticks qw(roll_for);
my $E = 'Game::Senet::Engine';

subtest 'the last piece off ends the game on that move' => sub {
    my $g = Game::Senet::Rules->new(rules => 'kendall',
        position => 'd........./........../.....l.... l 5');
    my ($m) = $g->moves(5);
    is($m->trace, '26>off', 'light\'s last piece bears off on a 5');
    $g->apply($m);
    is($g->status, 'won', 'won');
    is($g->winner, 'light', 'by light');
    is($g->how, 'home', 'by bearing off');
    is($g->side, 'light', 'a 5 would throw again, and nothing is thrown: the side does not change');
    is(scalar($g->moves(1)), 0, 'no move after the end');
    is($g->apply($m), undef, 'Rules refuses a move after the end');
    is($g->forfeit(2), 0, 'and a forfeit');
};

subtest 'a side with four home has not won' => sub {
    my $g = Game::Senet::Rules->new(rules => 'kendall',
        position => 'd........./........../.....l...l l 5');
    is($g->home('light'), 3, 'three home');
    my ($m) = grep { $_->trace eq '30>off' } $g->moves(1);
    $g->apply($m);
    is($g->home('light'), 4, 'four home after 30>off');
    is($g->status, 'ongoing', 'and the game goes on');
};

subtest 'the ply cap' => sub {
    my $bd = $E->new(position => 'd........./........../.....l.... l 5');
    my $cap = $bd->ply_cap;
    cmp_ok($cap, '>', 0, "the cap is $cap plies");
    $bd->set_ply($cap - 1);
    is($bd->status, ONGOING, 'one ply short of it the game goes on');
    $bd->forfeit(2);
    is($bd->ply, $cap, 'a forfeit is a ply');
    is($bd->status, DRAWN, 'at the cap the game is drawn');
    is($bd->how, BY_PLY_CAP, 'by the cap');
    is($bd->winner, -1, 'and nobody wins');
};

# THE 28 TO 30 ENDINGS, EXACTLY. One piece a house, so a side waiting there has
# at most three. Alone, under kendall, a piece on 28 leaves on a 3, on 29 on a
# 2, on 30 on a 1, and nothing else moves. The expected number of the side's
# own throws to bear them all off, by the recurrence, as fractions:
#
#     E(S) = (1 + sum over r that clears a house h of S: p(r) E(S - h)) / p(any clears)

my %P = (1 => 4, 2 => 6, 3 => 4, 4 => 1, 5 => 1);
my %OFF_ON = (28 => 3, 29 => 2, 30 => 1);

sub gcd { my ($a, $b) = @_; ($a, $b) = ($b, $a % $b) while $b; return $a }

sub reduce { my ($n, $d) = @_; my $g = gcd($n, $d); return [ $n / $g, $d / $g ] }

sub expect {
    my (@houses) = sort @_;
    return [0, 1] unless @houses;
    my ($n, $d, $clears) = (16, 1, 0);
    for my $h (@houses) {
        my $p = $P{ $OFF_ON{$h} };
        $clears += $p;
        my ($en, $ed) = @{ expect(grep { $_ != $h } @houses) };
        ($n, $d) = ($n * $ed + $p * $en * $d, $d * $ed);
    }
    return reduce($n, $d * $clears);
}

my %EXACT = (
    '28'       => '4/1',
    '29'       => '8/3',
    '30'       => '4/1',
    '28 29'    => '76/15',
    '28 30'    => '6/1',
    '29 30'    => '76/15',
    '28 29 30' => '694/105',
);

subtest 'the recurrence, as fractions' => sub {
    for my $s (sort keys %EXACT) {
        my ($n, $d) = @{ expect(split / /, $s) };
        is("$n/$d", $EXACT{$s}, "light on $s alone: $EXACT{$s} throws");
    }
};

subtest 'and 10,000 seeded endings of each agree' => sub {
    for my $s (sort keys %EXACT) {
        my @houses = split / /, $s;
        my ($n, $d) = split m{/}, $EXACT{$s};
        my ($sum, $sumsq, $games) = (0, 0, 10_000);
        my $throw = 0;
        my $seed = "senet endings $s";
        for my $game (1 .. $games) {
            my $bd = $E->new(pieces => 5);
            $bd->put($_, DARK) for 1 .. 5;
            $bd->put($_, LIGHT) for @houses;
            my $count = 0;
            while ($bd->count(SIDE_LIGHT)) {
                my $roll = roll_for($seed, $throw++);
                $count++;
                my ($m) = $bd->moves($roll, 'kendall');
                $m ? $bd->apply($m, 'kendall') : $bd->forfeit($roll);
                $bd->set_side(SIDE_LIGHT);
            }
            $sum += $count;
            $sumsq += $count * $count;
        }
        my $mean = $sum / $games;
        my $sd = sqrt($sumsq / $games - $mean * $mean);
        cmp_ok(abs($mean - $n / $d), '<', 4 * $sd / sqrt($games),
            sprintf('light on %s: %.3f throws in %d endings, against %.3f', $s, $mean, $games, $n / $d));
    }
};

done_testing();
