use strict;
use warnings;
use Test::More;

use Game::Fanorona;
my $G = 'Game::Fanorona';

# A LEVEL IS A COUNT OF POSITIONS, AND THE COUNT IS KEPT. The search may pass
# its budget by the few steps of settling one position, and by whatever its
# first look at every move costs when the budget is smaller than that.

my @positions = (
    [ 'the set-up',            $G->new ],
    [ 'after two moves',       $G->new(script => [ 'd3-e3A', 'c3-d3W' ]) ],
    [ 'a quiet ending',        $G->new(position => '8b/2b6/9/1w7/w8 w') ],
    [ 'a thicket',             $G->new(position => '1bbbbbbb1/bwbb1bbb1/3b3b1/www1b3w/ww1wb1www w') ],
);

for my $case (@positions) {
    my ($name, $game) = @$case;
    my $first = $game->search(budget => 1);
    like($first->{nodes}, qr/\A[0-9]+\z/, "$name: the count is a string of digits");
    is($first->{depth}, 1, "$name: a budget of one position still finishes its first look");
    ok(length $first->{move}, "$name: and answers with a move, $first->{move}");
    my $one = $first->{nodes};
    for my $budget (500, 5_000, 50_000) {
        my $found = $game->search(budget => $budget);
        my $over = $found->{nodes} - $budget;
        my $allowed = $budget < $one ? $one - $budget + 64 : 64;
        cmp_ok($over, '<=', $allowed, "$name: a budget of $budget looked at $found->{nodes}");
        cmp_ok($found->{depth}, '>=', $first->{depth}, "$name: and got at least as deep, $found->{depth}");
    }
}

# MORE POSITIONS, DEEPER
{
    my $g = $G->new(script => [ 'd3-e3A', 'c3-d3W' ]);
    my @depth = map { $g->search(budget => $_)->{depth} } 300, 3_000, 30_000, 300_000;
    is_deeply(\@depth, [ sort { $a <=> $b } @depth ], "depths @depth for budgets of 300, 3,000, 30,000 and 300,000: never shallower for more");
    cmp_ok($depth[-1], '>', $depth[0], 'and a thousand times the budget does look further');
}

# A DEPTH IS A LIMIT TOO
{
    my $g = $G->new;
    my $shallow = $g->search(budget => 1_000_000, depth => 1);
    is($shallow->{depth}, 1, 'asked to look one move ahead, it looks one move ahead');
    is($shallow->{stopped}, 0, 'and was not cut short');
    cmp_ok($shallow->{nodes}, '<', 2000, "at a cost of $shallow->{nodes} positions, not a million");
    my $two = $g->search(budget => 1_000_000, depth => 2);
    is($two->{depth}, 2, 'two when asked for two');
    cmp_ok($two->{nodes}, '>', $shallow->{nodes}, 'which costs more');
    is($g->search(budget => 500)->{stopped}, 1, 'a budget that runs out part way through a deeper look says so');
    is($g->search(budget => 5)->{stopped}, 0, 'and one too small for anything past the first look was not cut short: it never began a second');
}

done_testing();
