#!perl
use 5.010; use strict; use warnings;
use Digest::SHA ();
use Test::More;

use Game::Schnapsen ();
use Game::Schnapsen::Bot ();
use Game::Schnapsen::Card qw(id_of name_of);
use Game::Schnapsen::Search qw(best_lead best_follow best_marriage
                               should_claim should_close hand_strength);
use Game::Schnapsen::Variant qw(variants);

# THE POLICY, as opposed to the legality.
#
# t/19 asserts the bot plays legal moves, deterministically, and never claims
# falsely. All of that passed while best_follow was mutated to THROW ITS CARD
# AWAY rather than take a trick it could win, and again when it was mutated to
# win with its dearest card instead of its cheapest. A bot playing either way is
# still legal, still deterministic, still finishes every match - and is simply
# bad, which no assertion in that file can see.
#
# Two mutations that made the bot stop declaring marriages and stop exchanging
# passed for the same reason.
#
# So this file tests what the bot is supposed to DO. It is the same gap phase 02
# found between legal() and apply(): one of the pair was checked and the other
# was not.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();

sub cards { return [ map { id_of($_) } @_ ] }

# ---- best_follow: take the trick, cheaply ----------------------------------------

subtest 'it takes a trick it can win' => sub {
    plan tests => 4;
    my $got = best_follow(cards => cards(qw(AS 9S TH)), led => id_of('KS'), trump => 'H');
    # Both the ace of spades and the ten of trumps would win. It takes the ace,
    # because paying a trump for a trick a plain card wins is waste: measured
    # head to head at 75.5% and 78.8% over 400 matches a side.
    is(name_of($got), 'AS', 'the ace of the led suit beats the king, and no trump is spent');

    $got = best_follow(cards => cards(qw(9S TH)), led => id_of('KS'), trump => 'H');
    is(name_of($got), 'TH', 'and a trump takes it when the suit cannot');

    $got = best_follow(cards => cards(qw(9S QD)), led => id_of('KS'), trump => 'H');
    is(name_of($got), '9S', 'with nothing to win it, the cheapest card goes');

    $got = best_follow(cards => cards(qw(AD QD)), led => id_of('KS'), trump => 'H');
    is(name_of($got), 'QD', 'and the cheapest means the cheapest, not the lowest rank');
};

subtest 'it wins with its CHEAPEST winner, not its dearest' => sub {
    # Spending an ace to beat a jack throws away eleven card points you will want
    # later. The mutation that reversed this passed the whole of t/19.
    plan tests => 4;
    my $got = best_follow(cards => cards(qw(AS TS QS)), led => id_of('JS'), trump => 'H');
    is(name_of($got), 'QS', 'the queen beats the jack and the ace is kept');

    # NOT the nine: the nine is BELOW the jack, so it does not win at all. The
    # first version of this line asserted it did, which is a test that had the
    # rank order backwards rather than a bot that had.
    $got = best_follow(cards => cards(qw(AH TH 9H)), led => id_of('JH'), trump => 'H');
    is(name_of($got), 'TH', 'the ten of trumps is the cheapest card that beats the jack');

    $got = best_follow(cards => cards(qw(AH TH)), led => id_of('KH'), trump => 'H');
    is(name_of($got), 'TH', 'and the ten is preferred to the ace when both would do');

    # A plain winner is taken ahead of a cheaper trump one, which is the rule
    # that is NOT "conserve trumps": the trick is still taken either way.
    $got = best_follow(cards => cards(qw(KS 9H)), led => id_of('QS'), trump => 'H');
    is(name_of($got), 'KS', 'a plain king wins it rather than the nine of trumps');
};

subtest 'it never declines a trick it could take' => sub {
    # THE MUTATION THIS SUBTEST EXISTS FOR. Sweeping every hand of three against
    # every lead: if a winner exists, the chosen card must be one.
    plan tests => 2;
    my (@declined, $chances);
    my @pool = map { id_of($_) } qw(AS TS KS QS JS AH TH KH QH JH AD TD);
    for my $i (0 .. $#pool - 2) {
        for my $led (@pool) {
            my @hand = @pool[ $i .. $i + 2 ];
            next if grep { $_ == $led } @hand;
            my @win = grep {
                Game::Schnapsen::Trick::winner_of($led, $_, 'H') == $_
            } @hand;
            next unless @win;
            $chances++;
            my $got = best_follow(cards => \@hand, led => $led, trump => 'H');
            push @declined, name_of($led) . ' <- ' . name_of($got)
                unless grep { $_ == $got } @win;
        }
    }
    cmp_ok($chances, '>', 40, "$chances positions where a trick was there to take");
    is(scalar @declined, 0, 'and it took it every single time')
        or diag(join ', ', @declined[0 .. 4]);
};

# ---- best_lead: the thing that makes level 2 stronger --------------------------------

subtest 'level 1 leads its cheapest card and level 2 does not' => sub {
    # Measured: the lead choice is essentially ALL of level 2's advantage. With
    # it removed level 2 falls from about 75% against level 1 to about 49%.
    plan tests => 4;
    my $hand = cards(qw(AS TS 9D KH));

    is(name_of(best_lead(cards => $hand, trump => 'H', phase => 1, level => 1)), '9D',
       'level 1 leads the cheapest card it holds');

    is(name_of(best_lead(cards => $hand, trump => 'H', phase => 1, level => 2)), '9D',
       'level 2 leads low too while the talon is open');

    is(name_of(best_lead(cards => $hand, trump => 'H', phase => 2, level => 2)), 'AS',
       'but leads an ace once the talon is gone and the opponent must follow');

    isnt(name_of(best_lead(cards => $hand, trump => 'H', phase => 2, level => 2)),
         name_of(best_lead(cards => $hand, trump => 'H', phase => 2, level => 1)),
         'so the two levels really do lead differently');
};

subtest 'level 2 keeps its trumps back while the talon is open' => sub {
    plan tests => 2;
    my $hand = cards(qw(9H JH AS));
    is(name_of(best_lead(cards => $hand, trump => 'H', phase => 1, level => 2)), 'AS',
       'the plain ace goes before either trump');
    my $only = cards(qw(9H JH));
    is(name_of(best_lead(cards => $only, trump => 'H', phase => 1, level => 2)), '9H',
       'and with nothing but trumps it leads the cheapest of them');
};

# ---- the declarations --------------------------------------------------------------------

subtest 'the dearest marriage is the one declared' => sub {
    plan tests => 3;
    my @m = ({ suit => 'S', value => 20 }, { suit => 'H', value => 40 });
    is(best_marriage(marriages => \@m), 'H', 'forty before twenty');
    is(best_marriage(marriages => [ { suit => 'S', value => 20 } ]), 'S', 'or the only one');
    is(best_marriage(marriages => []), undef, 'and undef when there are none');
};

subtest 'should_claim is exactly the target and never below it' => sub {
    plan tests => 4;
    is(should_claim(my_points => 66, target => 66), 1, 'sixty-six claims');
    is(should_claim(my_points => 65, target => 66), 0, 'sixty-five does not');
    is(should_claim(my_points => 99, target => 66), 1, 'and anything above does');
    is(should_claim(my_points => 0,  target => 66), 0, 'nothing at all does not');
};

subtest 'hand_strength values trumps and aces above their card points' => sub {
    plan tests => 3;
    my $plain = hand_strength(cards => cards(qw(KS)), trump => 'H');
    my $trump = hand_strength(cards => cards(qw(KH)), trump => 'H');
    cmp_ok($trump, '>', $plain, 'the same king is worth more in trumps');
    cmp_ok(hand_strength(cards => cards(qw(AS)), trump => 'H'), '>',
           hand_strength(cards => cards(qw(TS)), trump => 'H'),
           'and an ace above a ten, though the card points are close');
    is(hand_strength(cards => [], trump => 'H'), 0, 'an empty hand is worth nothing');
};

# ---- and the bot actually uses all of it ---------------------------------------------------

sub sweep {
    my ($v, $matches) = @_;
    my %missed = (marriage => 0, exchange => 0);
    my %took;
    for my $n (1 .. $matches) {
        my $s = seed("policy $v $n");
        my $g = Game::Schnapsen->build(variant => $v, seed => $s, dealer => 'p1');
        my %bot = (p1 => Game::Schnapsen::Bot->new(level => 2, seed => $s . 'p1'),
                   p2 => Game::Schnapsen::Bot->new(level => 2, seed => $s . 'p2'));
        my $i = 0;
        while (!$g->over && $i++ < 4000) {
            my $seat = $g->turn or last;
            my $legal = $g->legal($seat);
            my $move = $bot{$seat}->choose($g, $seat) or last;
            # A miss is only a miss if the bot went on to PLAY A CARD with the
            # declaration still on offer. Taking an exchange while a marriage is
            # also available is not passing the marriage up: declarations do not
            # consume the turn, so it is still there on the next call.
            for my $kind (qw(marriage exchange)) {
                next unless grep { $_->{kind} eq $kind } @$legal;
                $missed{$kind}++ if $move->{kind} eq 'lead' || $move->{kind} eq 'follow';
            }
            $took{ $move->{kind} }++;
            $g->apply($seat, $move);
        }
    }
    return (\%took, \%missed);
}

subtest 'the bot takes every marriage and every exchange it is offered' => sub {
    # Declaring is never worse than not declaring, and swapping the lowest trump
    # for the turn-up is never worse than keeping it. Both mutations that made
    # the bot skip them passed the whole of t/19.
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($took, $missed) = sweep($v, 25);
        cmp_ok($took->{marriage} // 0, '>', 5,
               "$v: it declared " . ($took->{marriage} // 0) . ' marriages');
        is($missed->{marriage}, 0, "$v: and never passed one up");
        cmp_ok($took->{exchange} // 0, '>', 5,
               "$v: it exchanged " . ($took->{exchange} // 0) . ' times');
        is($missed->{exchange}, 0, "$v: and never passed one up");
    }
};

subtest 'the bot plays every kind of move the game has' => sub {
    # A bot that quietly never does one of these is a bot a player never sees do
    # it. `draw` is Sixty-Six only, which is itself worth pinning.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($took) = sweep($v, 25);
        my @want = qw(lead follow marriage exchange claim close);
        my @never = grep { !$took->{$_} } @want;
        is_deeply(\@never, [], "$v: it used " . join(', ', sort keys %$took));
        is(($took->{draw} // 0) > 0 ? 1 : 0, $v eq 'sixtysix' ? 1 : 0,
           "$v: and a draw is a move in sixtysix only");
    }
};

done_testing();
