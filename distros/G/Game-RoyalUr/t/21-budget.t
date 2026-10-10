use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

sub board { (($E->of_string($_[0]))[0]) or die "'$_[0]' was refused" }

# A position in the middle of a game, with four moves on a roll of 1.
my $MIDDLE = '2d1xx2/l1dl1l2/1l2xx2 l 3 0 4 1';

subtest 'a search is bounded in positions' => sub {
    my $bd = board($MIDDLE);
    cmp_ok(scalar($bd->moves(1)), '>=', 4, 'a roll of 1 has a choice of four or more');
    my @bad;
    my $deepest = 0;
    for my $budget (0, 1, 2, 5, 10, 50, 200, 1_000, 5_000, 20_000, 100_000) {
        my $found = $bd->search(1, budget => $budget);
        my $moves = scalar $bd->moves(1);
        my $allowed = $budget > $moves ? $budget : $moves;
        push @bad, "a budget of $budget spent $found->{nodes}" if $found->{nodes} > $allowed;
        push @bad, "a budget of $budget finished no level" if $found->{depth} < 1;
        push @bad, "a budget of $budget went shallower than a smaller one" if $found->{depth} < $deepest;
        $deepest = $found->{depth};
        note("budget $budget: depth $found->{depth}, $found->{nodes} positions" . ($found->{stopped} ? ', stopped' : ''));
    }
    is("@bad", '', 'never more than its budget, never less than one level, and never shallower for more');
    cmp_ok($deepest, '>=', 4, "a hundred thousand positions reach depth $deepest");
};

subtest 'the first level always finishes' => sub {
    my $bd = board($MIDDLE);
    my $moves = scalar $bd->moves(1);
    for my $budget (0, 1) {
        my $found = $bd->search(1, budget => $budget);
        is($found->{depth}, 1, "a budget of $budget still answers, from one level");
        is($found->{nodes}, "$moves", "having looked at all $moves moves");
        cmp_ok($found->{index}, '>=', 0, 'and it names one');
    }
    is($bd->search(1, budget => 0)->{index}, $bd->search(1, depth => 1)->{index}, 'the move a search of one level makes');
};

subtest 'a budget that runs out answers from the last level it finished' => sub {
    my $bd = board($MIDDLE);
    my %at;
    $at{$_} = $bd->search(1, depth => $_) for 1 .. 4;
    cmp_ok($at{3}{nodes}, '<', $at{4}{nodes}, "depth 3 costs $at{3}{nodes} positions and depth 4 costs $at{4}{nodes}");

    my $between = $at{3}{nodes} + int(($at{4}{nodes} - $at{3}{nodes}) / 2);
    my $found = $bd->search(1, budget => $between);
    is($found->{depth}, 3, "a budget of $between, between the two, finishes depth 3");
    ok($found->{stopped}, 'is stopped part way through depth 4');
    is($found->{index}, $at{3}{index}, 'and answers with the move of depth 3, not of the level it did not finish');
    is($found->{value}, $at{3}{value}, 'at the value of depth 3');
    cmp_ok($found->{nodes}, '<=', $between, 'having spent no more than it was given');

    my $exact = $bd->search(1, budget => $at{4}{nodes});
    is($exact->{depth}, 4, 'and a budget of exactly what depth 4 costs finishes depth 4');
};

subtest 'depth and budget together' => sub {
    my $bd = board($MIDDLE);
    my $found = $bd->search(1, depth => 2, budget => 1_000_000);
    is($found->{depth}, 2, 'a depth of 2 stops at 2 however large the budget');
    ok(!$found->{stopped}, 'and was not stopped');
    is($bd->search(1, depth => 0, budget => 300)->{depth}, $bd->search(1, budget => 300)->{depth}, 'a depth of 0 is no limit');
};

# The same position, roll and budget give the same move. In this process, and
# in the numbers below, which were written down on 9 October 2026 from another.
subtest 'a search is the same search every time' => sub {
    my $bd = board($MIDDLE);
    my $one = $bd->search(1, depth => 3);
    my $two = $bd->search(1, depth => 3);
    is_deeply($two, $one, 'asked twice');
    is_deeply(board($MIDDLE)->search(1, depth => 3), $one, 'and of another board in the same position');
    is_deeply({ %{ $bd->clone->search(1, depth => 3) } }, $one, 'and of a clone');

    my $masters = board($MIDDLE)->search(1, depth => 3, rules => 'masters');
    isnt($masters->{nodes}, $one->{nodes}, 'another rule set is another search');
};

subtest 'a move with no alternative costs one position' => sub {
    my $found = $E->new->search(3, budget => 1_000_000);
    is($found->{depth}, 1, 'the start, a roll of 3: one move, one level');
    is($found->{nodes}, '1', 'one position');
    is($found->{index}, 0, 'and that move');
};

done_testing();
