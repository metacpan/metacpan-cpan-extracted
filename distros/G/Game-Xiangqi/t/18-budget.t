use strict;
use warnings;
use Test::More;
use Time::HiRes ();

use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Bot;

my $E = 'Game::Xiangqi::Engine';

# THE BUDGET IS CHECKED EVERY 1024 NODES, so the count may overshoot by up to one
# whole interval and never by more. A check on every node would cost more than the
# interval saves; a check every 4096 would make the smallest rung meaningless.
my $INTERVAL = 1024;

# A dozen positions off a self-played game, so they are positions with pieces off
# the board and the middlegame's branching factor rather than twelve openings.
sub positions {
    my $b = $E->new;
    my @out;
    for my $ply (1 .. 36) {
        push @out, $b->clone if $ply % 3 == 0;
        my ($mv) = $b->search(2_000, $ply);
        last unless $mv;
        $b->do_move($mv);
    }
    return @out;
}

my @POS = positions();
is(scalar @POS, 12, 'a dozen positions to measure against');

subtest 'the node count never exceeds the budget by more than one interval' => sub {
    my $worst = 0;
    for my $i (0 .. $#POS) {
        for my $budget (100, 1_000, @Game::Xiangqi::Bot::LADDER, 100_000) {
            my (undef, $nodes) = $POS[$i]->search($budget, $i);
            my $over = $nodes - $budget;
            $worst = $over if $over > $worst;
            cmp_ok($nodes, '<=', $budget + $INTERVAL,
                   "position $i, budget $budget: $nodes nodes")
                or diag("  over by $over, which is more than $INTERVAL");
        }
    }
    diag("the worst overshoot over the whole sweep was $worst nodes, of $INTERVAL allowed");
};

subtest 'a budget of zero still comes back with a legal move' => sub {
    # A search that returned nothing would make the site's move transaction fail
    # on a busy box, and a bot seat that hangs a game is much worse than one that
    # plays badly.
    #
    # THE PLAN ASKED FOR MORE THAN THIS AND THE PLAN WAS WRONG. It said the first
    # iteration always completes, and the obvious way to promise that is to gate
    # the budget check off until the root has one iteration in hand. That HUNG THE
    # SEARCH: `quiesce` is bounded by the budget and by nothing else, so a budget
    # that can be switched off is not a budget. The contract is therefore the
    # weaker one asserted here, and it is made worth having by the root list being
    # SHUFFLED BY THE SEED BEFORE ANYTHING IS SEARCHED: a budget too small to
    # finish depth 1 hands back a move the seed drew, not whatever the generator
    # happened to put first.
    my %by_depth;
    for my $i (0 .. $#POS) {
        my %legal = map { $_ => 1 } $POS[$i]->legal;
        my ($mv, $nodes, $depth) = $POS[$i]->search(0, $i);
        ok($legal{$mv}, "position $i: a budget of zero played a legal move")
            or diag('  fen: ' . $POS[$i]->to_fen);
        $by_depth{$depth}++;
    }
    diag('a budget of zero reached: ' . join(', ', map { "depth $_ x$by_depth{$_}" }
                                                 sort keys %by_depth));

    my ($mv) = $POS[0]->search(1, 0);
    ok($mv, 'and so does a budget of one');

    # AND THE SEED IS WHAT SEPARATES EQUAL MOVES, which is the shuffle seen from
    # the outside. At the opening, where genuinely equal moves exist, twenty seeds
    # do not all answer the same.
    #
    # THE FIRST VERSION OF THIS ASSERTION WAS WRONG and asserted it of a
    # middlegame position at a budget of zero. Zero still completes depth 1 there,
    # depth 1 has one best move, and every seed rightly agreed: the test was
    # demanding that the search be random where it should be decided.
    my %drawn = map { scalar($E->new->search(0, $_ * 104729)) => 1 } 1 .. 20;
    cmp_ok(scalar keys %drawn, '>', 1,
           'at the opening, twenty seeds do not all play the same move');
};

subtest 'the worst single move at each rung, in milliseconds' => sub {
    # THE NUMBERS ARE NOT ASSERTED HERE and that is deliberate: a smoker on slow
    # hardware would fail a threshold this file has no business setting. What is
    # asserted is that a move ANSWERS. The measurement is phase 11's, and it is
    # the one that decides which rungs the site's bag can afford: Game::Oware's
    # top two rungs came in at 0.86 and 5.9 seconds and were cut for it.
    my @rungs = do { my %s; grep { !$s{$_}++ } @Game::Xiangqi::Bot::LADDER };

    for my $budget (@rungs) {
        my ($worst, $where, $total) = (0, -1, 0);
        for my $i (0 .. $#POS) {
            my $t0 = Time::HiRes::time();
            my ($mv) = $POS[$i]->search($budget, $i);
            my $ms = (Time::HiRes::time() - $t0) * 1000;
            $total += $ms;
            ($worst, $where) = ($ms, $i) if $ms > $worst;
            ok($mv, "rung $budget, position $i answered");
        }
        diag(sprintf 'rung %6d: worst %7.1f ms (position %d), mean %6.1f ms',
             $budget, $worst, $where, $total / scalar @POS);
    }
};

subtest 'a bigger budget never searches less deeply' => sub {
    # Iterative deepening, from the outside: depth is monotone in the budget. A
    # search that spent its budget on a deeper first iteration instead of
    # finishing a shallow one would break this, and would also hand back a move
    # chosen from half a ply.
    for my $i (0 .. $#POS) {
        my @d;
        for my $budget (1_000, 10_000, 100_000) {
            my (undef, undef, $depth) = $POS[$i]->search($budget, $i);
            push @d, $depth;
        }
        ok($d[0] <= $d[1] && $d[1] <= $d[2],
           "position $i: depths @d for budgets 1k, 10k, 100k");
    }
};

done_testing();
