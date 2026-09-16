#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(points_of rank_of);
use Game::Schnapsen::Variant qw(variants deck_size hand_size);
use Game::Schnapsen::Deck qw(pack_for order_for deal_for talon_at draw_count);

# Three properties, and they are the ones the whole engine rests on: the order
# is a permutation of the variant's pack, it is a pure function of its key, and
# the key really has all three parts in it.

sub seed { return Digest::SHA::sha256($_[0]) }

my @VARIANTS = variants();
my $SEED = seed("schnapsen t/03");

# ---- a permutation, always ------------------------------------------------------------

subtest 'the order is a permutation of the pack' => sub {
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $want = pack_for($v);
        my (@wrong_size, @not_a_permutation);
        for my $n (1 .. 5000) {
            my $order = order_for(seed("perm $v $n"), 1, $v);
            push @wrong_size, $n unless @$order == deck_size($v);
            push @not_a_permutation, $n
                unless join(',', sort { $a <=> $b } @$order) eq join(',', @$want);
            last if @wrong_size || @not_a_permutation;
        }
        is_deeply(\@wrong_size, [], "$v: every order is " . deck_size($v) . ' cards');
        is_deeply(\@not_a_permutation, [],
                  "$v: with nothing missing and nothing repeated");
    }
};

# ---- pure in all three arguments --------------------------------------------------------

subtest 'the order is a pure function of seed, deal and variant' => sub {
    plan tests => 4;

    is_deeply(order_for($SEED, 1, 'schnapsen'), order_for($SEED, 1, 'schnapsen'),
              'the same three arguments give the same order');

    isnt(join(',', @{ order_for($SEED, 1, 'schnapsen') }),
         join(',', @{ order_for(seed('another'), 1, 'schnapsen') }),
         'a different seed deals differently');

    # THE FIXED-SHUFFLE BUG. A match is several deals, and a shuffle fixed once
    # at the start deals the same cards every deal. It looks like extraordinary
    # luck rather than like a fault, and no other assertion here would catch it.
    isnt(join(',', @{ order_for($SEED, 1, 'schnapsen') }),
         join(',', @{ order_for($SEED, 2, 'schnapsen') }),
         'no later deal of a match repeats the first');

    # This would catch the two variants accidentally sharing a pack, which is
    # worth having. It does NOT catch order_for dropping the variant from its
    # digest key, and the first version of this comment claimed it did.
    #
    # Checked by mutation, which is how the claim was found to be wrong: with
    # the variant removed from the key the whole suite stays green, because the
    # two packs are different sizes and the shuffles therefore diverge at the
    # first swap regardless. The variant is in the key against a later variant
    # that shares a pack size with one of these two, and nothing here can test
    # that until such a variant exists.
    isnt(join(',', @{ order_for($SEED, 1, 'schnapsen') }),
         join(',', grep { rank_of($_) ne '9' } @{ order_for($SEED, 1, 'sixtysix') }),
         'and the two games deal differently from one seed');
};

subtest 'no deal of a long match repeats another' => sub {
    plan tests => scalar @VARIANTS;
    for my $v (@VARIANTS) {
        my %seen;
        $seen{ join ',', @{ order_for($SEED, $_, $v) } }++ for 1 .. 40;
        is(scalar keys %seen, 40, "$v: forty deals are forty different orders");
    }
};

ok(!eval { order_for('short', 1, 'schnapsen'); 1 }, 'a seed that is not 32 bytes is refused');
ok(!eval { order_for($SEED, 0, 'schnapsen'); 1 }, 'a deal number of zero is refused');
ok(!eval { order_for($SEED, 1, 'bezique'); 1 }, 'and a variant that is not one');

# ---- the layout ---------------------------------------------------------------------------

subtest 'the layout, and the turn-up at the end of it' => sub {
    plan tests => 7 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $order = order_for($SEED, 1, $v);
        my $d = deal_for($SEED, 1, $v);
        my $h = hand_size($v);

        is(scalar @{ $d->{non_dealer} }, $h, "$v: the non-dealer gets $h");
        is(scalar @{ $d->{dealer} }, $h, "$v: and so does the dealer");
        is($d->{turn_up}, $order->[-1], "$v: the turn-up is the LAST card of the order");

        # Not decoration. Both rulesets have the turn-up lying under the talon
        # and going to whoever draws last, so putting it at the end makes a draw
        # unconditionally "take the next one" with no special case at the bottom
        # of the pile. That is what lets a draw be derivable from the seed and a
        # count, and therefore never written into a move log.
        is(scalar @{ $d->{talon} } + 1, draw_count($v),
           "$v: the talon plus the turn-up is " . draw_count($v) . ' to draw');

        # Both divide by two, so the draws come out even and the talon empties
        # at the end of a trick rather than in the middle of one.
        is(draw_count($v) % 2, 0, "$v: which is an even number");

        my @all = (@{ $d->{non_dealer} }, @{ $d->{dealer} }, @{ $d->{talon} }, $d->{turn_up});
        is(scalar @all, deck_size($v), "$v: the four parts are the whole pack");
        is(join(',', sort { $a <=> $b } @all), join(',', @{ pack_for($v) }),
           "$v: with nothing missing and nothing duplicated");
    }
};

subtest 'the two games lay out the sizes their rules give' => sub {
    plan tests => 4;
    is(hand_size('schnapsen'), 5, 'schnapsen deals five each');
    is(draw_count('schnapsen'), 10, 'and leaves ten to draw');
    is(hand_size('sixtysix'), 6, 'sixtysix deals six each');
    is(draw_count('sixtysix'), 12, 'and leaves twelve to draw');
};

subtest 'every deal is worth 120 card points' => sub {
    plan tests => scalar @VARIANTS;
    for my $v (@VARIANTS) {
        my @bad;
        for my $n (1 .. 200) {
            my $d = deal_for($SEED, $n, $v);
            my $t = 0;
            $t += points_of($_)
                for (@{ $d->{non_dealer} }, @{ $d->{dealer} }, @{ $d->{talon} }, $d->{turn_up});
            push @bad, "$n:$t" unless $t == 120;
        }
        is_deeply(\@bad, [], "$v: two hundred deals each worth 120");
    }
};

# ---- the shuffle actually shuffles ------------------------------------------------------------

subtest 'no position favours any card' => sub {
    # WHAT THIS CATCHES: a shuffle that does not shuffle, a swap skipped at
    # either end of the loop, a counter that sticks so the same words come back,
    # and a key that is not being varied.
    #
    # WHAT IT DOES NOT CATCH, stated because a test that overstates its own
    # strength stops anybody looking for the check that would work: removing the
    # rejection sampling. With 32-bit words and a range of 24 the modulo bias is
    # about one part in a hundred and seventy million, and no sample anybody will
    # ever run would show it. The rejection is in the code because it is correct,
    # not because this defends it.
    plan tests => scalar @VARIANTS;
    my $DEALS = 20_000;
    for my $v (@VARIANTS) {
        my $size = deck_size($v);
        my %count;
        for my $n (1 .. $DEALS) {
            my $order = order_for($SEED, $n, $v);
            $count{ $order->[0] }++;
        }
        my $expect = $DEALS / $size;
        my $chi = 0;
        $chi += ($count{$_} - $expect) ** 2 / $expect for @{ pack_for($v) };

        # 24 cards is 23 degrees of freedom; 20 cards is 19. A threshold of 120
        # is far above either critical value and far below what a broken
        # shuffle scores, so it does not fail by chance and does not pass a bug.
        cmp_ok($chi, '<', 120, "$v: the first card is flat across the pack (chi $chi)");
    }
};

done_testing();
