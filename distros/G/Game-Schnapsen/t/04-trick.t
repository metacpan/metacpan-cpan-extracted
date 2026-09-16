#!perl
use 5.010; use strict; use warnings;
use Test::More;

use Game::Schnapsen::Card qw(suit_of rank_of name_of id_of points_of CARDS);
use Game::Schnapsen::Trick qw(winner_of value_of);

# winner_of over EVERY ordered pair of distinct cards and every trump suit.
# That is 24 * 23 * 4 = 2208 cases, which is small enough to do exhaustively, so
# sampling would be choosing to test less for no saving.
#
# The oracle is written separately below, from the rules text rather than from
# the implementation. It builds its rank order ASCENDING and by hand, where
# Game::Schnapsen::Card derives power from a descending list: an oracle that
# reached for power_of would agree with the module about any mistake in that
# list, which is the whole failure mode a second opinion exists to catch.

my @ASCENDING = qw(9 J Q K T A);
my %HEIGHT;
@HEIGHT{@ASCENDING} = 0 .. $#ASCENDING;

sub oracle {
    my ($lead, $follow, $trump) = @_;
    my $ls = suit_of($lead);
    my $fs = suit_of($follow);

    if ($fs eq $ls) {
        return $HEIGHT{ rank_of($follow) } > $HEIGHT{ rank_of($lead) } ? $follow : $lead;
    }
    return $follow if $fs eq $trump;
    return $lead;
}

subtest 'every ordered pair of cards, every trump' => sub {
    my (@wrong, $cases, $lead_wins, $follow_wins);
    ($cases, $lead_wins, $follow_wins) = (0, 0, 0);
    for my $trump (qw(S H D C)) {
        for my $lead (1 .. CARDS) {
            for my $follow (1 .. CARDS) {
                next if $follow == $lead;
                $cases++;
                my $got = winner_of($lead, $follow, $trump);
                my $want = oracle($lead, $follow, $trump);
                push @wrong, sprintf('%s beaten by %s at %s: got %s want %s',
                                     name_of($lead), name_of($follow), $trump,
                                     name_of($got), name_of($want))
                    if $got != $want;
                $got == $lead ? $lead_wins++ : $follow_wins++;
            }
        }
    }
    plan tests => 4;
    is($cases, CARDS * (CARDS - 1) * 4, "$cases cases, which is all of them");
    is(scalar @wrong, 0,
       'the engine and a separately written oracle agree about all of them')
        or diag(join "\n", @wrong[0 .. ($#wrong > 9 ? 9 : $#wrong)]);

    # Anti-vacuous: an oracle and an engine that both always answered "the lead"
    # would agree perfectly. Both outcomes have to actually happen.
    cmp_ok($lead_wins, '>', 0, "the lead wins sometimes ($lead_wins)");
    cmp_ok($follow_wins, '>', 0, "and the follow wins sometimes ($follow_wins)");
};

# ---- the rules, one at a time, in case the oracle and the engine share a blind spot ----

subtest 'trump beats a plain suit however small' => sub {
    plan tests => 2;
    is(winner_of(id_of('AS'), id_of('9H'), 'H'), id_of('9H'),
       'the nine of trumps takes the ace of spades');
    is(winner_of(id_of('AS'), id_of('9H'), 'S'), id_of('AS'),
       'and does not when hearts are not trumps');
};

subtest 'a card of neither the led suit nor trump cannot win' => sub {
    plan tests => 2;
    is(winner_of(id_of('9S'), id_of('AH'), 'D'), id_of('9S'),
       'the ace of hearts loses to the nine of spades when diamonds are trumps');
    is(winner_of(id_of('9S'), id_of('AD'), 'D'), id_of('AD'),
       'but the ace of diamonds takes it');
};

subtest 'the ten beats the king, which is the trap in this family' => sub {
    plan tests => 4;
    is(winner_of(id_of('KS'), id_of('TS'), 'H'), id_of('TS'), 'ten over king');
    is(winner_of(id_of('TS'), id_of('KS'), 'H'), id_of('TS'), 'and led it still wins');
    is(winner_of(id_of('TS'), id_of('AS'), 'H'), id_of('AS'), 'the ace is over the ten');
    is(winner_of(id_of('JS'), id_of('TS'), 'H'), id_of('TS'), 'and the ten over the jack');
};

subtest 'trump against trump is the higher trump' => sub {
    plan tests => 2;
    is(winner_of(id_of('JH'), id_of('TH'), 'H'), id_of('TH'), 'the higher trump takes it');
    is(winner_of(id_of('AH'), id_of('TH'), 'H'), id_of('AH'), 'and the lead can be the higher');
};

# ---- the value of a trick ------------------------------------------------------------

subtest 'a trick is worth its two cards' => sub {
    plan tests => 3;
    is(value_of(id_of('AS'), id_of('TS')), 21, 'an ace and a ten are 21');
    is(value_of(id_of('9S'), id_of('9H')), 0, 'two nines are nothing');

    # The whole pack is 120 and a deal is played out in tricks, so the tricks of
    # a complete deal must add to 120. This is the invariant the later files
    # assert after every trick; here it is checked against the card table alone.
    my $total = 0;
    $total += points_of($_) for 1 .. CARDS;
    is($total, 120, 'and every trick in a pack adds to 120');
};

done_testing();
