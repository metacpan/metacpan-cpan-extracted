#!perl
use 5.010; use strict; use warnings;
use Test::More;

use Game::Schnapsen::Scoring qw(deal_result);

# THE FOUR DIVERGENT ENDINGS, each run against both games from the same state.
#
#   the false claim ....... divergence 12, false_claim_schwarz
#   the beaten closer ..... divergence 13, beaten_closer_flat
#   the successful close .. divergence 6,  close_counts_tricks_at
#   the cards running out . divergence 5,  last_trick_rule
#
# Every expectation below is a quotation. The two pages are close enough that a
# rule read from the wrong one looks entirely plausible, which is the failure
# this whole distribution is arranged against.
#
# deal_result is called directly rather than through a played deal, because these
# are arithmetic over a position and rigging the position is the only way to hit
# the corners at all reliably.

sub result {
    my (%o) = @_;
    return deal_result(
        closed_by => undef, close_state => undef, last_trick => 'p1',
        points => { p1 => 0, p2 => 0 }, tricks => { p1 => 0, p2 => 0 },
        %o);
}

# ---- divergence 12: what a false claim costs --------------------------------------------

subtest 'a false claim pays 3 in schnapsen and a flat 2 in sixtysix' => sub {
    # Schnapsen: "the opponent scores 2 game points, or 3 game points if the
    #             false claim is made before the opponent has taken a trick".
    # Sixty-Six:  "A player goes out prematurely, having fewer than 66 card
    #             points. The other player wins. 2 game points".
    plan tests => 8;

    for my $case ([ 'schnapsen', 3 ], [ 'sixtysix', 2 ]) {
        my ($v, $schwarz) = @$case;

        my $none = result(variant => $v, how => 'claim', by => 'p1',
                          points => { p1 => 50, p2 => 0 },
                          tricks => { p1 => 3, p2 => 0 });
        is($none->{how}, 'false_claim', "$v: fifty is not sixty-six");
        is($none->{winner}, 'p2', "$v: so the opponent takes the deal");
        is($none->{game_points}, $schwarz,
           "$v: worth $schwarz, the opponent having no trick");

        my $some = result(variant => $v, how => 'claim', by => 'p1',
                          points => { p1 => 50, p2 => 20 },
                          tricks => { p1 => 3, p2 => 1 });
        is($some->{game_points}, 2, "$v: and two once the opponent has a trick");
    }
};

# ---- divergence 13: beating a closer ------------------------------------------------------

subtest 'beating a closer pays 2 or 3 in schnapsen and a flat 2 in sixtysix' => sub {
    # Schnapsen: "The same scores of 2 or 3 game points apply in the unusual case
    #             where the opponent of the player who closed reaches 66 and wins
    #             by claiming first."
    # Sixty-Six:  "A player closes the talon, but the other player then wins by
    #             going out with 66 or more points (rare case): 2 game points".
    plan tests => 8;

    for my $case ([ 'schnapsen', 3 ], [ 'sixtysix', 2 ]) {
        my ($v, $schwarz) = @$case;

        # p1 closed; p2 had no trick at that moment; p2 now claims 66 and wins.
        my $r = result(variant => $v, how => 'claim', by => 'p2',
                       points => { p1 => 20, p2 => 70 },
                       tricks => { p1 => 2, p2 => 3 },
                       closed_by => 'p1',
                       close_state => { by => 'p1',
                                        p1 => { points => 20, tricks => 2 },
                                        p2 => { points => 0,  tricks => 0 } });
        is($r->{how}, 'beat_closer', "$v: the closer was beaten to it");
        is($r->{winner}, 'p2', "$v: by their opponent");
        is($r->{game_points}, $schwarz,
           "$v: worth $schwarz, the winner having had no trick when the talon closed");

        my $had = result(variant => $v, how => 'claim', by => 'p2',
                         points => { p1 => 20, p2 => 70 },
                         tricks => { p1 => 2, p2 => 3 },
                         closed_by => 'p1',
                         close_state => { by => 'p1',
                                          p1 => { points => 20, tricks => 1 },
                                          p2 => { points => 14, tricks => 1 } });
        is($had->{game_points}, 2, "$v: and two when they did have one");
    }
};

# ---- divergence 6: whose tricks count after a SUCCESSFUL close -----------------------------

subtest 'a successful close is scored at the close, or at the end' => sub {
    # Sixty-Six: "the score is based on the cards in the opponent's total tricks
    #             taken before and after closing".
    # Schnapsen:  "the score is normally determined by the tricks the opponent
    #             had at the moment of closing".
    #
    # ONE rigged position decides the whole divergence: the opponent had nothing
    # when the talon closed and picked up tricks afterwards. Schnapsen scores
    # them Schwarz for what they had then; Sixty-Six scores them Schneider for
    # what they finished with.
    plan tests => 6;

    my %state = (
        how => 'claim', by => 'p1',
        points => { p1 => 70, p2 => 20 },
        tricks => { p1 => 4, p2 => 2 },
        closed_by => 'p1',
        close_state => { by => 'p1',
                         p1 => { points => 50, tricks => 4 },
                         p2 => { points => 0,  tricks => 0 } },
    );

    for my $case ([ 'schnapsen', 3 ], [ 'sixtysix', 2 ]) {
        my ($v, $want) = @$case;
        my $r = result(variant => $v, %state);
        is($r->{how}, 'closed_out', "$v: the closer went out");
        is($r->{winner}, 'p1', "$v: and won");
        is($r->{game_points}, $want, "$v: for $want");
    }
};

subtest 'a FAILED close reads the moment of closing in both games' => sub {
    # The trap beside the divergence above. Both pages say the same thing here,
    # so close_counts_tricks_at must NOT reach this path:
    #
    #   Schnapsen: "2 points to the opponent, or 3 if the opponent had no tricks
    #               when the talon was closed".
    #   Sixty-Six: "2 or 3 game points, depending whether the opponent had any
    #               tricks at the moment of closing".
    #
    # The same position as the subtest above, but nobody claimed and the cards
    # ran out. Both games must now answer 3, where a moment ago they differed.
    plan tests => 6;

    my %state = (
        how => 'exhausted',
        points => { p1 => 50, p2 => 70 },
        tricks => { p1 => 4, p2 => 2 },
        closed_by => 'p1', last_trick => 'p2',
        close_state => { by => 'p1',
                         p1 => { points => 50, tricks => 4 },
                         p2 => { points => 0,  tricks => 0 } },
    );

    for my $v (qw(schnapsen sixtysix)) {
        my $r = result(variant => $v, %state);
        is($r->{how}, 'failed_close', "$v: the close failed");
        is($r->{winner}, 'p2', "$v: so the opponent takes it");
        is($r->{game_points}, 3,
           "$v: for three, because they had no trick AT THE CLOSE, whatever they have now");
    }
};

# ---- divergence 5: the cards running out with no close and no claim --------------------------

subtest 'schnapsen pays the last trick a flat one and sixtysix counts the cards' => sub {
    # Schnapsen: "the player who takes the last trick wins the hand, scoring one
    #             game point, IRRESPECTIVE of the number of card points".
    # Sixty-Six:  "the very last trick is worth 10 card points extra ... the
    #             player with the higher card point total wins".
    #
    # Rigged so the two answers are opposite: p2 holds 90 of the 120 and p1 takes
    # the last trick. Schnapsen gives the deal to p1 for one point; Sixty-Six
    # gives it to p2, whose 90 beats 30 plus the ten.
    plan tests => 6;

    my %state = (
        how => 'exhausted',
        points => { p1 => 30, p2 => 90 },
        tricks => { p1 => 2, p2 => 8 },
        last_trick => 'p1',
    );

    my $s = result(variant => 'schnapsen', %state);
    is($s->{how}, 'last_trick', 'schnapsen: decided by the last trick');
    is($s->{winner}, 'p1', 'schnapsen: won by whoever took it');
    is($s->{game_points}, 1, 'schnapsen: for exactly one, though they hold 30 to 90');

    my $x = result(variant => 'sixtysix', %state);
    is($x->{winner}, 'p2', 'sixtysix: won by the higher card total instead');
    is($x->{points}{p1}, 40, 'sixtysix: the last trick added ten to p1');
    is($x->{game_points}, 1, 'sixtysix: for one, p1 being over 33');
};

subtest 'the last trick bonus can turn the result round' => sub {
    # The bonus is not decoration: at 60-60 before it, the last trick decides.
    plan tests => 4;
    my %state = (
        how => 'exhausted',
        points => { p1 => 60, p2 => 60 },
        tricks => { p1 => 5, p2 => 5 },
    );
    my $a = result(variant => 'sixtysix', %state, last_trick => 'p1');
    my $b = result(variant => 'sixtysix', %state, last_trick => 'p2');
    is($a->{winner}, 'p1', 'the last trick takes it one way');
    is($b->{winner}, 'p2', 'and the other');
    is($a->{points}{p1}, 70, 'ten on top of sixty');
    is($a->{points}{p2}, 60, 'and nothing for the other seat');
};

subtest 'a sixtysix deal can be drawn, and a schnapsen deal cannot' => sub {
    # "If the players have equal card point totals the hand is a draw."
    #
    # Equal AFTER the bonus, so the pre-bonus split has to differ by exactly ten
    # in favour of whoever does NOT take the last trick. 55 and 65, with p1
    # taking the last trick, is 65 each.
    plan tests => 7;

    my %state = (
        how => 'exhausted',
        points => { p1 => 55, p2 => 65 },
        tricks => { p1 => 5, p2 => 5 },
        last_trick => 'p1',
    );

    my $x = result(variant => 'sixtysix', %state);
    is($x->{points}{p1}, 65, 'sixtysix: the bonus makes it 65');
    is($x->{points}{p2}, 65, 'sixtysix: against 65');
    is($x->{how}, 'drawn', 'sixtysix: which is a drawn deal');
    is($x->{drawn}, 1, 'sixtysix: flagged as one');
    is($x->{winner}, undef, 'sixtysix: with nobody winning it');
    is($x->{game_points}, 0, 'sixtysix: and nothing scored');

    my $s = result(variant => 'schnapsen', %state);
    is($s->{how}, 'last_trick',
       'schnapsen: the same position is not drawn, because it never looks at the cards');
};

subtest 'the pack is 120, or 130 once the last trick is paid' => sub {
    plan tests => 2;
    my $x = result(variant => 'sixtysix', how => 'exhausted',
                   points => { p1 => 70, p2 => 50 },
                   tricks => { p1 => 6, p2 => 4 }, last_trick => 'p2');
    is($x->{points}{p1} + $x->{points}{p2}, 130, 'sixtysix totals 130');

    my $s = result(variant => 'schnapsen', how => 'exhausted',
                   points => { p1 => 70, p2 => 50 },
                   tricks => { p1 => 6, p2 => 4 }, last_trick => 'p2');
    is($s->{points}{p1} + $s->{points}{p2}, 120,
       'schnapsen totals 120, because it pays no bonus at all');
};

done_testing();
