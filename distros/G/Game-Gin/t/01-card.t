#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Gin::Card qw(rank_of suit_of deadwood_of name_of long_name_of id_of CARDS);

# A card is an integer and everything else is derived from it, so what is
# tested here is that the derivation is total and reversible: every id gives a
# rank, a suit, a value and a name, and every name gives its id back.

is(CARDS, 52, 'a deck is 52 cards');

# ---- the derivation is total -------------------------------------------------------

subtest 'every id derives a whole card' => sub {
    plan tests => 4;
    my (%rank, %suit, %name, $bad);
    for my $id (1 .. CARDS) {
        my $r = rank_of($id);
        my $s = suit_of($id);
        $bad++ unless $r >= 1 && $r <= 13;
        $bad++ unless grep { $_ eq $s } qw(S H D C);
        $rank{$r}++; $suit{$s}++;
        $name{ name_of($id) }++;
    }
    is($bad, undef, 'every id gives a rank in 1..13 and one of the four suits');
    is(scalar keys %suit, 4, 'all four suits appear');
    is_deeply([ sort { $a <=> $b } values %suit ], [ 13, 13, 13, 13 ],
              'thirteen cards in each');
    is(scalar keys %name, CARDS, 'and all 52 names are distinct');
};

# ---- names round-trip ---------------------------------------------------------------

subtest 'a name is two characters and parses back' => sub {
    plan tests => 4;
    my ($wrong_length, $wrong_id) = (0, 0);
    for my $id (1 .. CARDS) {
        my $n = name_of($id);
        $wrong_length++ unless length $n == 2;
        $wrong_id++ unless (id_of($n) // 0) == $id;
    }
    is($wrong_length, 0, 'every card is exactly two characters');
    is($wrong_id, 0, 'and every name parses back to its own id');
    is(id_of('as'), id_of('AS'), 'parsing is case insensitive');
    is(id_of('ZZ'), undef, 'and a name that is not a card is undef, not a death');
};

# ---- the one piece of real knowledge -------------------------------------------------

subtest 'deadwood values' => sub {
    plan tests => 6;
    is(deadwood_of(id_of('AS')), 1,  'an ace is 1');
    is(deadwood_of(id_of('2S')), 2,  'a two is 2');
    is(deadwood_of(id_of('9S')), 9,  'a nine is 9');
    is(deadwood_of(id_of('TS')), 10, 'a ten is 10');
    is(deadwood_of(id_of('KS')), 10, 'and a king is 10');

    # 45 for the ace to nine, plus four tens: 85 a suit, 340 a deck. A sum is
    # one assertion covering all 52, and it moves if any single value is wrong.
    my $total = 0;
    $total += deadwood_of($_) for 1 .. CARDS;
    is($total, 340, 'the whole deck counts 340');
};

# ---- the ace is low and only low ------------------------------------------------------

subtest 'the ace is low, which is a rule and not an accident' => sub {
    plan tests => 3;
    is(rank_of(id_of('AS')), 1,  'an ace ranks 1');
    is(rank_of(id_of('KS')), 13, 'and a king 13');

    # Q-K-A is not a run, and the reason is that ranks do not wrap. Asserting
    # the arithmetic here is what stops somebody "fixing" rank_of later to
    # make the ace high and breaking Game::Gin::Meld silently: the meld code
    # only tests consecutiveness, so it would accept Q-K-A the moment an ace
    # could rank 14.
    my @qka = map { rank_of(id_of($_)) } qw(QS KS AS);
    isnt($qka[2], $qka[1] + 1, 'an ace does not follow a king');
};

# ---- what is not a card ----------------------------------------------------------------

subtest 'an id that is not a card is refused' => sub {
    plan tests => 5;
    for my $bad (0, 53, -1, 'x', undef) {
        my $label = defined $bad ? "'$bad'" : 'undef';
        ok(!eval { rank_of($bad); 1 }, "$label is not a card");
    }
};

done_testing();
