#!perl
use 5.010; use strict; use warnings;
use Test::More;

use Game::Schnapsen::Variant qw(variants is_variant check_variant spec_for fields
                                deck_size hand_size ranks exchange_rank
                                exchange_needs_trick
                                marriage_after_close false_claim_schwarz
                                beaten_closer_flat last_trick_rule
                                close_counts_tricks_at close_before_draw
                                exchange_on_close next_dealer
                                match_start match_target match_direction match_over);

# Schnapsen and Sixty-Six share a card point table and differ in THIRTEEN places.
# The table started at ten. Three were found by going back to the source pages at
# the moment of implementing them rather than assuming the two agreed:
#
#   exchange_needs_trick  (phase 03) 66 requires "at least one trick"; Schnapsen
#                                    states no such condition
#   false_claim_schwarz   (phase 04) Schnapsen pays 3 against a trickless
#                                    opponent; 66 pays a flat 2
#   beaten_closer_flat    (phase 04) Schnapsen scores it as any failed close;
#                                    66 caps that one case at 2
# This file is what stops the two of them quietly becoming one game.
#
# The ruleset that results from taking the most popular answer to each question
# separately is one NO PUBLICATION DESCRIBES, and therefore one with no citable
# test vectors. Game::Dominoes says so at length and for the same reason. The
# defence here is structural: every divergence is a field in one table, nothing
# else in the distribution branches on a variant name, and the assertions below
# are about the SHAPE of that table rather than about any one rule.

is_deeply([ variants() ], [qw(schnapsen sixtysix)], 'two variants, and only two');

# ---- the shape of the table -------------------------------------------------------

subtest 'every field in the table is a divergence' => sub {
    # THE INVARIANT THIS FILE EXISTS FOR.
    #
    # There is no entry for anything the two games agree on: card points, the
    # values of a marriage, sixty-six itself and the 1/2/3 scale are shared and
    # live elsewhere. So a field the two variants AGREE on is either a rule that
    # does not belong here, or - much worse - a divergence that was added to one
    # variant and forgotten in the other, which is exactly the bug that merges
    # the two games.
    #
    # Written first as `ok(deck_size('schnapsen') != deck_size('sixtysix'))` and
    # so on, field by field. That passes happily when somebody adds an eleventh
    # field to one spec only, which is the case it needed to catch.
    my $s = spec_for('schnapsen');
    my $x = spec_for('sixtysix');

    is_deeply([ sort keys %$s ], [ sort keys %$x ],
              'the two specs carry exactly the same fields');
    is_deeply([ sort keys %$s ], [ fields() ], 'and fields() agrees with them');

    my @same = grep {
        my $a = $s->{$_};
        my $b = $x->{$_};
        (ref $a eq 'ARRAY' ? "@$a" : $a) eq (ref $b eq 'ARRAY' ? "@$b" : $b);
    } sort keys %$s;
    is_deeply(\@same, [], 'and the two disagree about every one of them')
        or diag('agreed on: ' . join ', ', @same);

    cmp_ok(scalar keys %$s, '>=', 13, 'there are at least thirteen of them ('
           . scalar(keys %$s) . ')');
};

# ---- the thirteen, one at a time, both directions --------------------------------------

# Each row is a divergence from the comparison section of pagat.com/marriage/66.html,
# which enumerates them itself, plus the pack and hand sizes from the two pages.
#
# The point of the table form is mark 2 of the gate: running a row against the
# OTHER variant's expectation must fail. A row where both columns held the same
# value would pass in both directions and prove nothing, which is why the
# subtest above refuses to let one exist.
my @DIVERGENCE = (
    [ 'the pack',                 \&deck_size,              20, 24 ],
    [ 'the hand',                 \&hand_size,               5,  6 ],
    [ 'the exchange card',        \&exchange_rank,         'J', '9' ],
    [ 'a trick before exchanging', \&exchange_needs_trick,  0,  1 ],
    [ 'marriages after a close',  \&marriage_after_close,    1,  0 ],
    [ 'a false claim can pay three', \&false_claim_schwarz,   1,  0 ],
    [ 'beating a closer pays flat',  \&beaten_closer_flat,    0,  1 ],
    [ 'the last trick',           \&last_trick_rule, 'one_point', 'ten_points' ],
    [ 'whose tricks, after a close', \&close_counts_tricks_at, 'close', 'end' ],
    [ 'when the talon may close', \&close_before_draw,       0,  1 ],
    [ 'the exchange on a close',  \&exchange_on_close,       0,  1 ],
    [ 'who deals next',           \&next_dealer,   'alternate', 'winner' ],
    [ 'where the match starts',   \&match_start,             7,  0 ],
    [ 'where the match ends',     \&match_target,            0,  7 ],
);

for my $d (@DIVERGENCE) {
    my ($what, $fn, $schnapsen, $sixtysix) = @$d;
    is($fn->('schnapsen'), $schnapsen, "schnapsen: $what");
    is($fn->('sixtysix'),  $sixtysix,  "sixtysix: $what");
}

is_deeply(ranks('schnapsen'), [qw(A T K Q J)], 'schnapsen has no nine');
is_deeply(ranks('sixtysix'),  [qw(A T K Q J 9)], 'sixtysix does');

subtest 'the pack size and the rank list agree with each other' => sub {
    # Two fields stating one fact. They can be edited apart, and a deck built
    # from the ranks while a count is read from deck_size would then deal a hand
    # short rather than fail.
    plan tests => 2;
    for my $v (variants()) {
        is(scalar @{ ranks($v) } * 4, deck_size($v), "$v: four suits of "
           . scalar @{ ranks($v) } . ' ranks is ' . deck_size($v));
    }
};

subtest 'the exchange card is the lowest trump in its own pack' => sub {
    # Not a coincidence worth leaving unstated: the jack is the lowest of the
    # twenty-card pack and the nine the lowest of the twenty-four. A variant
    # that gained a rank without moving its exchange card would fail here.
    plan tests => 2;
    for my $v (variants()) {
        my $lowest = ranks($v)->[-1];
        is(exchange_rank($v), $lowest, "$v: the exchange card is the $lowest");
    }
};

# ---- the match, which runs in opposite directions ----------------------------------

subtest 'the score counts in the direction its game counts' => sub {
    plan tests => 10;

    is(match_direction('schnapsen'), -1, 'schnapsen counts down');
    is(match_direction('sixtysix'),   1, 'sixtysix counts up');

    # SCHNAPSEN REACHES ZERO ON PURPOSE. It is the winning score, not the
    # starting one, which is why a consumer guarding a score with a plain truth
    # test breaks at exactly the moment it matters.
    is(match_over('schnapsen', 7), 0, 'schnapsen: a fresh score has not won');
    is(match_over('schnapsen', 1), 0, 'schnapsen: one to go');
    is(match_over('schnapsen', 0), 1, 'schnapsen: zero has won');
    is(match_over('schnapsen', -2), 1, 'schnapsen: past zero has won too');

    is(match_over('sixtysix', 0), 0, 'sixtysix: a fresh score has not won');
    is(match_over('sixtysix', 6), 0, 'sixtysix: one to go');
    is(match_over('sixtysix', 7), 1, 'sixtysix: seven has won');
    is(match_over('sixtysix', 9), 1, 'sixtysix: past seven has won too');
};

subtest 'a match starts where it has not already been won' => sub {
    # A start and a target edited apart would give a game that is over before
    # anybody plays, and every later test would still pass.
    plan tests => 2;
    for my $v (variants()) {
        is(match_over($v, match_start($v)), 0, "$v starts unfinished");
    }
};

# ---- a name that is not a variant ---------------------------------------------------

subtest 'a bad variant is refused rather than defaulted' => sub {
    plan tests => 6;

    ok(is_variant('schnapsen'), 'schnapsen is one');
    ok(!is_variant('bezique'), 'bezique is not');
    ok(!is_variant(undef), 'and neither is undef');

    # THERE IS NO DEFAULT. A typo falling back to Schnapsen would ship the wrong
    # game, and the consumer registering two games from one engine is one typo
    # away from registering the same game twice.
    is(check_variant('schnapsen'), undef, 'a good name checks out clean');
    my $bad = check_variant('bezique');
    isa_ok($bad, 'Game::Schnapsen::Error');
    is($bad->code, 'bad_variant', 'with a code a caller can branch on');
};

subtest 'below the boundary a bad variant is programmer error' => sub {
    # check_variant is the boundary and returns an error. Everything under it
    # dies, because by then the name has been checked once and a bad one is a
    # bug rather than bad input.
    plan tests => 2;
    ok(!eval { deck_size('bezique'); 1 }, 'deck_size dies for a name that is not a variant');
    like($@, qr/bezique/, 'and says which name it was');
};

subtest 'the table cannot be edited through its accessor' => sub {
    plan tests => 2;
    my $r = ranks('schnapsen');
    push @$r, '9';
    is_deeply(ranks('schnapsen'), [qw(A T K Q J)], 'ranks returns a fresh list each time');
    is(deck_size('schnapsen'), 20, 'so the pack is still twenty');
};

done_testing();
