use strict;
use warnings;
use Test::More;

use Game::Senet;

# THE INVARIANT, plan_game_senet/06: between calls the game is over, or the side
# to move holds a throw and at least one legal move. Over 200 seeded games a
# set, after every play.
for my $set (qw(kendall skyruk)) {
    subtest "the invariant, $set" => sub {
        my ($plays, $games, $broken, $forfeits, $forced, $chain_max) = (0, 0, 0, 0, 0, 0);
        srand($set eq 'kendall' ? 18 : 81);
        while ($plays < 20_000) {
            my $g = Game::Senet->new(seed => "facade $set $games", rules => $set);
            $games++;
            $broken++ unless $g->is_over || $g->legal;
            while (!$g->is_over) {
                my @m = $g->legal;
                $forced++ if @m == 1;
                $g->play($m[ int(rand(@m)) ]) or die $g->error->code;
                $plays++;
                $broken++ unless $g->is_over || $g->legal;
                my $turn = $g->turn;
                $chain_max = $turn->{segment} if $turn && $turn->{segment} > $chain_max;
            }
            $forfeits += scalar $g->forfeits_since(0);
        }
        is($broken, 0, "$plays plays over $games games, and legal was never empty between them");
        cmp_ok($forfeits, '>', 0, "the game settled $forfeits forfeits by itself");
        diag(sprintf '%s: %d plays, %d games, %d forfeits settled, %.1f%% of plays forced, longest turn %d throws',
            $set, $plays, $games, $forfeits, 100 * $forced / $plays, $chain_max);
    };
}

subtest 'the throw in hand is stable' => sub {
    my $g = Game::Senet->new(seed => 'stable');
    my ($s, $t, $r, $n) = ($g->sticks, $g->throw, $g->roll, $g->throws);
    for (1 .. 3) {
        is_deeply($g->sticks, $s, 'sticks');
        is($g->throw, $t, 'throw');
        is($g->roll, $r, 'roll');
        is($g->throws, $n, 'and the count of throws does not move');
    }
    is(scalar(grep { $_ } @$s), $t, 'the throw is the light faces of the sticks');
    is($r, $t == 0 ? 5 : $t, 'and the roll what the throw is worth');
};

subtest 'chances, against 00\'s table' => sub {
    my @c = Game::Senet->chances;
    is_deeply([ map { [ @{$_}{qw(roll throw weight denominator extra)} ] } @c ],
              [ [1, 1, 4, 16, 1], [2, 2, 6, 16, 0], [3, 3, 4, 16, 0], [4, 4, 1, 16, 1], [5, 0, 1, 16, 1] ],
              'roll, throw, weight in sixteenths, and another throw');
};

subtest 'the start' => sub {
    my $five = Game::Senet->new(seed => 'start');
    is($five->position, 'dldldldldl/........../.......... l 5', 'five a side on 1 to 10');
    is($five->at(2), 'light', 'light on the even houses');
    is($five->at(1), 'dark', 'dark on the odd');
    is($five->at(11), undef, 'and 11 empty');
    my $seven = Game::Senet->new(seed => 'start', rules => Game::Senet::Variant->named('kendall', pieces => 7));
    is($seven->position, 'dldldldldl/dldl....../.......... l 7', 'seven a side on 1 to 14');
    is($five->first, 'light', 'light throws first');
    is(Game::Senet->new(seed => 'start', first => 'dark')->side, 'dark', 'first => dark: dark throws first');
};

subtest 'seats and sides' => sub {
    my $p1 = Game::Senet->new(seed => 'seats');
    is($p1->side_of('p1'), 'light', 'by default p1 plays light');
    is($p1->side_of('p2'), 'dark', 'and p2 dark');
    is($p1->seat_of('light'), 'p1', 'seat_of light');
    is($p1->seat_of('dark'), 'p2', 'seat_of dark');
    my $p2 = Game::Senet->new(seed => 'seats', light => 'p2');
    is($p2->side_of('p2'), 'light', 'light => p2');
    is($p2->seat_of('light'), 'p2', 'and back');
    is($p2->side_of('p1'), 'dark', 'p1 plays dark');
    ok(!eval { Game::Senet->new(seed => 'seats', light => 'p3'); 1 }, 'p3 is not a seat');
};

subtest 'a forfeit the game makes is in the log' => sub {
    my $g = Game::Senet->new(script => [ 1, 2, 3 ], position => 'd........./........../.......l.. l 5');
    my @log = @{ $g->log };
    is(scalar @log, 2, 'light on 28 alone throws a 1 and a 2 and can move with neither');
    is_deeply([ map { [ @{$_}{qw(ply side roll again)} ] } @log ], [ [ 0, 'light', 1, 1 ], [ 1, 'light', 2, 0 ] ],
        'both are light\'s: the 1 keeps the throw, the 2 passes it');
    ok(!defined $log[0]{move}, 'a forfeit has no move');
    is(scalar($g->forfeits_since(1)), 1, 'forfeits_since(1) finds the second');
    is($g->side, 'dark', 'and dark holds the 3, with a move');
    is_deeply([ map { $_->trace } $g->legal ], [ '1>4' ], 'dark\'s 1>4');
};

subtest 'undo returns through forfeits to the last choice' => sub {
    my $g = Game::Senet->new(script => [ 3, 1, 4, 2, 2 ], position => 'l........./........../.....l.d.. l 5');
    is($g->roll, 3, 'light throws a 3');
    my $before = join '|', $g->position, $g->roll, $g->throws, $g->ply;
    $g->play('1-4') or die $g->error->code;
    my @f = $g->forfeits_since(0);
    is_deeply([ map { [ @{$_}{qw(side roll)} ] } @f ], [ [ 'dark', 1 ], [ 'dark', 4 ], [ 'dark', 2 ] ],
        'dark on 28 forfeits a 1, a 4 and a 2, the game making each');
    is($g->side, 'light', 'and light holds the last 2');
    ok($g->undo, 'undo');
    is(join('|', $g->position, $g->roll, $g->throws, $g->ply), $before,
        'back to the throw the move was made with, through three forfeits');
    is(scalar @{ $g->log }, 0, 'and the log with it');
    ok(!$g->undo, 'nothing more to take back');
};

subtest 'the constructor' => sub {
    ok(!eval { Game::Senet->new(rules => 'kendall'); 1 }, 'no seed and no script croaks');
    like($@, qr/a game wants a seed/, '  with a sentence');
    my $g = Game::Senet->new(seed => 'typo', rulez => 'skyruk');
    is($g->variant->name, 'kendall', 'AN UNKNOWN KEY IS DROPPED IN SILENCE: rulez plays kendall (Sugar\'s new)');
    ok(!eval { Game::Senet->new(seed => 's', first => 'grey'); 1 }, 'first grey croaks');
    ok(!eval { Game::Senet->new(seed => 's', position => 'dldldldldl/........../.......... l 7'); 1 },
        'a position with seven a side under five-piece rules croaks');
    like($@, qr/7 pieces a side and the rules 5/, '  saying so');
};

done_testing();
