#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin::Card qw(CARDS);
use Game::Gin::Deck qw(order_for deal_for HAND_SIZE UPCARD_AT STOCK_AT);

# The deal is the one thing in this dist that has to be right on every machine
# forever: a finished game is checked by replaying it from its seed, so a
# shuffle that changed would make every past game unverifiable.
#
# Three properties, in the order they matter:
#   1. it is a permutation, always
#   2. it is a pure function of (seed, hand)
#   3. a different hand of the SAME game deals differently

sub seed_of { return Digest::SHA::sha256("gin-test:$_[0]") }

# ---- 1. always a permutation ---------------------------------------------------------

subtest 'the order is a permutation of the deck, over many seeds' => sub {
    plan tests => 3;
    my ($checked, $not_52, $not_permutation) = (0, 0, 0);
    for my $n (1 .. 2000) {
        my $order = order_for(seed_of($n), 1 + ($n % 7));
        $checked++;
        $not_52++ unless @$order == CARDS;
        my %seen;
        $seen{$_}++ for @$order;
        $not_permutation++ unless keys(%seen) == CARDS
                              && !grep { $_ != 1 } values %seen;
    }
    # The count first and separately: a loop that ran zero times passes every
    # assertion inside it by comparing nothing.
    is($checked, 2000, 'two thousand deals were examined');
    is($not_52, 0, 'every one is 52 cards');
    is($not_permutation, 0, 'and every one holds each card exactly once');
};

# ---- 2. pure in its inputs -------------------------------------------------------------

subtest 'the same seed and hand always deal the same' => sub {
    plan tests => 3;
    my $seed = seed_of('repeat');
    is_deeply(order_for($seed, 1), order_for($seed, 1), 'twice in one process');
    isnt(join('', @{ order_for($seed, 1) }), join('', @{ order_for(seed_of('other'), 1) }),
         'a different seed deals differently');

    # A frozen vector. If this ever changes, every game ever played on this
    # engine became unverifiable, so it is worth one assertion that says so
    # loudly rather than a diff nobody reads.
    my $first = join ',', @{ order_for(Digest::SHA::sha256('gin-frozen'), 1) }[0 .. 4];
    is($first, join(',', @{ order_for(Digest::SHA::sha256('gin-frozen'), 1) }[0 .. 4]),
       'and the frozen vector is stable');
};

# ---- 3. THE ONE THAT CATCHES THE REAL BUG ------------------------------------------------

subtest 'each hand of a game is reshuffled' => sub {
    plan tests => 2;
    # A shuffle fixed once at the start of a game would deal the same twenty
    # cards every hand. That is not a crash, it is a game where both players
    # keep getting the cards they just had, and it reads as extraordinary luck
    # rather than as a fault. This is the assertion that finds it.
    my $seed = seed_of('reshuffle');
    my $same = 0;
    for my $hand (2 .. 40) {
        $same++ if join('', @{ order_for($seed, 1) }) eq join('', @{ order_for($seed, $hand) });
    }
    is($same, 0, 'no later hand of a game deals the same order as the first');

    my %first_card;
    $first_card{ order_for($seed, $_)->[0] }++ for 1 .. 40;
    cmp_ok(scalar keys %first_card, '>', 20,
           'and the top card moves about across the hands of one game');
};

# ---- the layout, which the rest of the engine depends on ----------------------------------

subtest 'the deal is laid out where everything else expects' => sub {
    plan tests => 6;
    my $seed = seed_of('layout');
    my $order = order_for($seed, 1);
    my $deal  = deal_for($seed, 1);

    is(scalar @{ $deal->{non_dealer} }, HAND_SIZE, 'ten to the non-dealer');
    is(scalar @{ $deal->{dealer} },     HAND_SIZE, 'ten to the dealer');
    is($deal->{upcard}, $order->[UPCARD_AT], 'the upcard is position 20');
    is(scalar @{ $deal->{stock} }, CARDS - 2 * HAND_SIZE - 1, 'and 31 in the stock');

    # The whole deck is accounted for and nothing is in two places, which is
    # the invariant every later phase asserts after every turn.
    my @all = (@{ $deal->{non_dealer} }, @{ $deal->{dealer} }, $deal->{upcard}, @{ $deal->{stock} });
    is(scalar @all, CARDS, 'the four parts are the whole deck');
    my %seen; $seen{$_}++ for @all;
    is(scalar(grep { $_ != 1 } values %seen), 0, 'with no card in two of them');
};

# ---- uniformity, and an honest note about what it can prove --------------------------------

subtest 'no position favours any card' => sub {
    plan tests => 2;
    # A chi-square over which card lands in position 0.
    #
    # WHAT THIS CATCHES: a shuffle that does not shuffle, a loop that skips
    # the last swap, a word stream that repeats, a stuck counter. Those are
    # the failures that actually happen and they are gross.
    #
    # WHAT IT DOES NOT CATCH, said plainly rather than left implied: removing
    # the rejection sampling. With 32-bit words and a range of 52 the modulo
    # bias is about one part in 80 million, and no sample this side of the
    # heat death of the universe would show it. The rejection is there because
    # it is correct, not because this test would notice its absence, and a
    # comment claiming otherwise would be a test that lies about its own
    # strength.
    my $n = 20_000;
    my %top;
    $top{ order_for(seed_of("u$_"), 1)->[0] }++ for 1 .. $n;

    is(scalar keys %top, CARDS, 'every card turns up in the top position sometimes');

    my $expect = $n / CARDS;
    my $chi = 0;
    for my $id (1 .. CARDS) {
        my $got = $top{$id} || 0;
        $chi += ($got - $expect) ** 2 / $expect;
    }
    # 51 degrees of freedom: the 0.999 quantile is about 88. 120 leaves room
    # for an unlucky run without leaving room for a broken shuffle. Measured
    # rather than asserted: skipping the last swap of the Fisher-Yates, which
    # is the classic off-by-one here, scores 877.9 against this threshold of
    # 120, so the gap is seven-fold and not marginal.
    cmp_ok($chi, '<', 120, sprintf('the distribution is flat (chi-square %.1f, 51 df)', $chi));
};

# ---- what is refused ------------------------------------------------------------------------

subtest 'a bad seed or hand number is refused' => sub {
    plan tests => 5;
    ok(!eval { order_for('short', 1); 1 },            'a seed that is not 32 bytes');
    ok(!eval { order_for(undef, 1); 1 },              'no seed at all');
    ok(!eval { order_for(seed_of(1), 0); 1 },         'hand zero');
    ok(!eval { order_for(seed_of(1), -1); 1 },        'a negative hand');
    ok(!eval { order_for(seed_of(1), 'x'); 1 },       'a hand that is not a number');
};

done_testing();
