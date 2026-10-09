use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Rules qw(:all);
use Game::Brandubh::Test::Squares qw(unwire roller);
my $R = 'Game::Brandubh::Rules';

# THE SEARCH IS BOUNDED IN NODES AND NEVER IN SECONDS. That is what makes a
# game against it something that can be played again: the same position, the
# same budget and the same seed give the same move on a busy machine as on an
# idle one. This file is that sentence, tested.

# a spread of positions met in play, the same ones every run
sub positions {
    my ($want, $seed) = @_;
    my $roll = roller($seed);
    my @games;
    while (@games < $want) {
        my $g = $R->new(variant => { ply_cap => 80 });
        my $moves = 2 + $roll->(30);
        for (1 .. $moves) {
            last if $g->is_over;
            my @legal = $g->moves;
            $g->play($legal[ $roll->(scalar @legal) ]);
        }
        push @games, $g unless $g->is_over;
    }
    return @games;
}

subtest 'the budget is kept, to within the 1,024 nodes between looks at it' => sub {
    my @games = positions(60, 2020);
    my ($searches, $bad, $over, $worst, %stopped) = (0, 0, 0, 0);
    for my $budget (5_000, 20_000, 60_000) {
        for my $g (@games) {
            my $found = $g->search(budget => $budget);
            $searches++;
            my $spent = $found->{nodes} - $budget;
            $worst = $spent if $spent > $worst;
            $bad++ if $spent > 1024;
            $over++ if $spent > 0;
            $stopped{ $found->{stopped} }++;
        }
    }
    is($searches, 180, 'sixty positions at three budgets');
    is($bad, 0, "no search passed its budget by more than 1,024 (the most was $worst)");
    cmp_ok($over, '>', 50, "$over of them did pass it, by less: the budget is asked about, not enforced on every node");
    cmp_ok($stopped{1} // 0, '>', 100, ($stopped{1} // 0) . ' were stopped part way through an iteration');
};

# The first iteration always finishes, so there is always a move, and a budget
# smaller than that iteration is simply passed by it. Said, and measured.
subtest 'the first iteration always finishes, whatever the budget' => sub {
    my @games = positions(60, 2021);
    my ($most, $bad) = (0, 0);
    for my $g (@games) {
        my $found = $g->search(budget => 1);
        $bad++ unless $found && $found->{depth} >= 1;
        $most = $found->{nodes} if $found->{nodes} > $most;
    }
    is($bad, 0, 'a budget of one node still returns a move, from a finished look one move ahead');
    cmp_ok($most, '<', 20_000, "and the most that look cost, over sixty positions, was $most nodes");
};

# THE MOVE RETURNED IS THE BEST OF THE LAST ITERATION THAT FINISHED. An
# iteration the budget cut short has looked at some moves and not others, and
# its best so far is the best of whichever it happened to reach. So a search
# stopped by its budget must return exactly what a search told to stop at that
# depth returns, with no budget to worry about.
subtest 'a search cut short returns what the last finished iteration found' => sub {
    my @games = positions(60, 2024);
    my ($cut, $bad) = (0, 0);
    for my $g (@games) {
        my $short = $g->search(budget => 6_000, seed => 5);
        next unless $short->{stopped};
        $cut++;
        my $whole = $g->search(budget => 50_000_000, seed => 5, depth => $short->{depth});
        $bad++ unless $whole->{move} == $short->{move} && $whole->{score} == $short->{score};
    }
    cmp_ok($cut, '>', 20, "$cut searches were cut short by a budget of six thousand");
    is($bad, 0, 'and each returned the move and the score of a whole search to the depth it had finished');
};

subtest 'the same position, budget and seed give the same move, fifty times' => sub {
    my @games = positions(6, 2022);
    for my $g (@games) {
        my %seen;
        for (1 .. 50) {
            my $found = $g->search(budget => 8_000, seed => 77);
            $seen{ join ',', @{$found}{qw(move score depth nodes stopped)} }++;
        }
        is(scalar(keys %seen), 1, 'one answer in fifty searches of ' . $g->position);
    }

    my $fresh = $R->new;
    my $first = $fresh->search(budget => 8_000, seed => 77);
    my $twin = $R->new;
    is_deeply($twin->search(budget => 8_000, seed => 77), $first, 'and a second game in the same position gives it too');
    my $clone = $fresh->clone;
    is_deeply($clone->search(budget => 8_000, seed => 77), $first, 'as does a clone');
};

# The seed settles the choice among moves of equal score. If it settled
# nothing it would be decoration, and two programs would play the same game.
subtest 'a different seed gives a different move somewhere, and never a different score' => sub {
    my @games = positions(200, 2023);
    my ($differ, $score_differs) = (0, 0);
    for my $g (@games) {
        my $x = $g->search(budget => 5_000_000, depth => 2, seed => 1);
        my $y = $g->search(budget => 5_000_000, depth => 2, seed => 2);
        $differ++ if $x->{move} != $y->{move};
        $score_differs++ if $x->{score} != $y->{score};
    }
    cmp_ok($differ, '>', 5, "in $differ of two hundred positions the two seeds chose different moves");
    is($score_differs, 0, 'of the same score every time');
    is($R->new->search(budget => 2000, seed => 0)->{move}, $R->new->search(budget => 2000, seed => 1)->{move},
        'a seed of 0 is taken as 1');
    is($R->new->search(budget => 2000)->{move}, $R->new->search(budget => 2000, seed => 1)->{move},
        'and so is no seed');
};

subtest 'a depth limit is kept, and a search it ends was not stopped' => sub {
    my $g = $R->new;
    for my $depth (1 .. 4) {
        my $found = $g->search(budget => 50_000_000, depth => $depth);
        is($found->{depth}, $depth, "asked for depth $depth, finished depth $depth");
        is($found->{stopped}, 0, 'and was not stopped by the budget');
    }
    my $deep = $g->search(budget => 50_000_000, depth => 4);
    my $shallow = $g->search(budget => 50_000_000, depth => 2);
    cmp_ok($deep->{nodes}, '>', $shallow->{nodes}, 'looking further costs more');

    my $won = $R->new(position => '7/7/7/k6/7/7/3a3 d');
    my $found = $won->search(budget => 50_000_000, depth => 6);
    is($found->{depth}, 1, 'a win found one move ahead is not looked for again five moves deeper');
};

subtest 'more budget looks further' => sub {
    my $g = $R->new;
    my @depth = map { $g->search(budget => $_)->{depth} } 1_000, 30_000, 900_000;
    cmp_ok($depth[1], '>=', $depth[0], "depth $depth[0] at a thousand nodes, $depth[1] at thirty thousand");
    cmp_ok($depth[2], '>', $depth[0], "and $depth[2] at nine hundred thousand");
    like($g->search(budget => 30_000)->{nodes}, qr/\A[0-9]+\z/, 'the node count is a string of digits');
};

subtest 'what search will not take' => sub {
    my $g = $R->new;
    for my $case ([ {}, 'no budget' ], [ { budget => 0 }, 'a budget of nothing' ], [ { budget => -5 }, 'a negative budget' ],
                  [ { budget => 'lots' }, 'a budget in words' ], [ { budget => 2.5 }, 'half a node' ],
                  [ { budget => 100, seed => -1 }, 'a negative seed' ], [ { budget => 100, seed => 4294967296 }, 'a seed past 32 bits' ],
                  [ { budget => 100, depth => 'deep' }, 'a depth in words' ], [ { budget => 100, weights => [1] }, 'weights that are not a hash' ]) {
        ok(!eval { $g->search(%{ $case->[0] }); 1 }, "$case->[1] croaks");
    }
    ok($g->search(budget => 100, seed => 4294967295), 'the largest seed is taken');
};

done_testing();
