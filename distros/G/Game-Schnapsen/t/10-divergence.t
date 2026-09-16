#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(id_of name_of suit_of);
use Game::Schnapsen::Variant qw(exchange_rank);
use Game::Schnapsen::Deal ();

# THE FIVE DIVERGENCES THAT LIVE IN THE DECLARATIONS, each run against BOTH
# games on the same rigged position.
#
#   3.  the exchange card: the trump jack against the trump nine
#   3b. whether the exchange needs a trick first
#   4.  marriages once the talon is closed or exhausted
#   7.  whether the talon may be closed before drawing
#   8.  the exchange at the moment of a close
#
# The rule of this file, and of mark 2 of the gate: A TEST THAT PASSES FOR BOTH
# VARIANTS HAS NOT NOTICED THEY ARE DIFFERENT GAMES. So every assertion below
# names a variant and expects the opposite of what the other one does.

sub seed { return Digest::SHA::sha256($_[0]) }

sub with_trump {
    my ($suit, $variant) = @_;
    for my $n (1 .. 600) {
        my $d = Game::Schnapsen::Deal->build(
            variant => $variant, seed => seed("dv $suit $n"), number => 1, dealer => 'p1');
        return $d if $d->trump eq $suit;
    }
    return undef;
}

sub kinds { return [ sort map { $_->{kind} } @{ $_[0] } ] }
sub offers { my ($d, $seat, $kind) = @_;
             return scalar grep { $_->{kind} eq $kind } @{ $d->legal($seat) } }

# ---- divergence 3: which card is the exchange card ------------------------------------

subtest 'the exchange card is the trump jack, or the trump nine' => sub {
    plan tests => 8;

    is(exchange_rank('schnapsen'), 'J', 'schnapsen exchanges the jack');
    is(exchange_rank('sixtysix'), '9', 'sixtysix exchanges the nine');

    # The same hand, the same trump, in both games. The jack works in one and
    # the nine in the other, and each is refused in the other game.
    for my $case ([ 'schnapsen', 'JH', '9H' ], [ 'sixtysix', '9H', 'JH' ]) {
        my ($v, $right, $wrong) = @$case;
        my $d = with_trump('H', $v);

        # A trick first, so Sixty-Six's precondition is satisfied either way and
        # this subtest is about the CARD alone.
        $d->hand_of('p2')->cards([ map { id_of($_) } ($right, $wrong, 'AS') ]);
        $d->tricks([ { leader => 'p2', lead => 1, follow => 2, winner => 'p2' } ]);

        is($d->can_exchange('p2'), id_of($right),
           "$v: the $right is the card it offers");
        is(offers($d, 'p2', 'exchange'), 1, "$v: and the exchange is on the list");

        $d->hand_of('p2')->cards([ map { id_of($_) } ($wrong, 'AS') ]);
        is($d->can_exchange('p2'), undef,
           "$v: holding only the $wrong, there is nothing to exchange");
    }
};

# ---- divergence 3b: whether a trick is needed first -------------------------------------

subtest 'sixtysix needs a trick before exchanging and schnapsen does not' => sub {
    # Found in phase 03 by going back to both source pages rather than assuming
    # they agreed. Sixty-Six: "provided that he has already won at least one
    # trick". Schnapsen: "This can only be done by the player whose turn it is to
    # lead, just before he leads to the trick", and no more.
    plan tests => 4;

    for my $case ([ 'schnapsen', 'JH', 1 ], [ 'sixtysix', '9H', 0 ]) {
        my ($v, $card, $without_trick) = @$case;
        my $d = with_trump('H', $v);
        $d->hand_of('p2')->cards([ map { id_of($_) } ($card, 'AS', 'TS') ]);

        is($d->can_exchange('p2') ? 1 : 0, $without_trick,
           "$v: with no trick yet, the exchange is "
           . ($without_trick ? 'allowed' : 'refused'));

        $d->tricks([ { leader => 'p2', lead => 1, follow => 2, winner => 'p2' } ]);
        is($d->can_exchange('p2') ? 1 : 0, 1, "$v: and with a trick it is allowed");
    }
};

# ---- divergence 4: marriages after the talon closes or empties ----------------------------

subtest 'schnapsen melds after a close and sixtysix does not' => sub {
    # "In 66, from the moment that the talon is exhausted or the trump is turned
    # down, no further 20's or 40's can be declared. In Schnapsen 20's and 40's
    # can be declared in any trick."
    plan tests => 6;

    for my $case ([ 'schnapsen', 1 ], [ 'sixtysix', 0 ]) {
        my ($v, $after) = @$case;
        my $d = with_trump('H', $v);
        $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS AD) ]);

        is(offers($d, 'p2', 'marriage'), 1, "$v: with the talon open, the meld is offered");

        $d->closed(1);
        $d->drawn(1);
        is(offers($d, 'p2', 'marriage'), $after,
           "$v: with the talon closed it is " . ($after ? 'still offered' : 'gone'));

        my $out = ($d->apply('p2', { kind => 'marriage', suit => 'S' }))[0];
        my $got = ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted';
        is($got, $after ? 'accepted' : 'no_marriage',
           "$v: and apply agrees with legal about it");
    }
};

subtest 'the same divergence when the talon merely runs out' => sub {
    # Sixty-Six forbids it "from the moment that the talon is exhausted OR the
    # trump is turned down", so an empty talon must behave like a closed one.
    # An implementation reading only `closed` passes the subtest above and fails
    # this one.
    plan tests => 2;
    for my $case ([ 'schnapsen', 1 ], [ 'sixtysix', 0 ]) {
        my ($v, $after) = @$case;
        my $d = with_trump('H', $v);
        $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS AD) ]);
        $d->talon([]);
        $d->turn_up(undef);
        $d->drawn(1);
        is(offers($d, 'p2', 'marriage'), $after,
           "$v: with the talon exhausted the meld is "
           . ($after ? 'still offered' : 'gone'));
    }
};

# ---- divergence 7: closing before the draw ------------------------------------------------

subtest 'sixtysix may close before drawing and schnapsen may not' => sub {
    # "In 66 the talon can be closed either before or after drawing from the
    # talon. In Schnapsen it can only be closed after drawing."
    #
    # This is the divergence that shaped the turn order. Schnapsen has no moment
    # at which a draw is outstanding, so the deal draws by itself; Sixty-Six has
    # one, so after a trick the winner is offered `close` or `draw`.
    plan tests => 10;

    for my $case ([ 'schnapsen', 0 ], [ 'sixtysix', 1 ]) {
        my ($v, $before) = @$case;
        my $d = with_trump('H', $v);

        # Play one trick to reach the moment after it and before the draw.
        my $leader = $d->turn;
        $d->apply($leader, { kind => 'lead', card => $d->hand_of($leader)->cards->[0] });
        my $follower = $d->turn;
        $d->apply($follower, { kind => 'follow', card => $d->legal($follower)->[0]{card} });

        is($d->pending_draw, $before,
           "$v: after a trick a draw is " . ($before ? 'outstanding' : 'already settled'));

        if ($before) {
            # `claim` belongs here too: "A claim may be made just after winning a
            # trick", which is this moment, before the draw.
            is_deeply(kinds($d->legal($d->turn)), [qw(claim close draw)],
                      "$v: and the choices are to claim, to close or to draw");
            is($d->can_close($d->turn), 1, "$v: closing before the draw is allowed");
            my @out = $d->apply($d->turn, { kind => 'close' });
            is($d->closed, 1, "$v: and it closes with the hands one card short");
        }
        else {
            is($d->pending_draw, 0, "$v: there is no before-the-draw moment to test");
            is(scalar(grep { $_->{kind} eq 'draw' } @{ $d->legal($d->turn) }), 0,
               "$v: a draw is never a move, because it is never a choice");
            is($d->can_close($d->turn), 1,
               "$v: closing is allowed, but only now that the draw has happened");
        }

        is(Game::Schnapsen::Variant::close_before_draw($v), $before,
           "$v: which is what the variant table says");
    }
};

subtest 'both games may close on a full hand, including before the first trick' => sub {
    # The shared half of divergence 7. Schnapsen's condition is "after drawing a
    # replacement card, when the players have hands of five cards each", and at
    # the start of a deal that is already true.
    plan tests => 4;
    for my $v (qw(schnapsen sixtysix)) {
        my $d = with_trump('H', $v);
        is($d->pending_draw, 0, "$v: a fresh deal has no draw outstanding");
        is($d->can_close($d->turn), 1, "$v: so the non-dealer may close at once");
    }
};

# ---- divergence 8: the exchange at the moment of a close -------------------------------------

subtest 'closing hands sixtysix opponent the exchange, and schnapsen does not' => sub {
    # "In 66 ... the opponent ... may at the moment of closing exchange the 9 for
    # the face up trump, even having won no tricks. In Schnapsen this is not
    # allowed."
    #
    # It is applied automatically rather than offered: the nine is worth nothing
    # and the turn-up is worth between two and eleven, so declining is never
    # right, and the alternative needs the turn to change hands mid-move.
    plan tests => 8;

    for my $case ([ 'schnapsen', 'JH', 0 ], [ 'sixtysix', '9H', 1 ]) {
        my ($v, $card, $swaps) = @$case;
        my $d = with_trump('H', $v);
        my $up = $d->turn_up;

        # The opponent of the closer holds the exchange card and NO trick.
        my $closer = $d->turn;
        my $them = $closer eq 'p1' ? 'p2' : 'p1';
        $d->hand_of($them)->cards([ map { id_of($_) } ($card, 'AS', 'TS') ]);

        my @out = $d->apply($closer, { kind => 'close' });

        is($d->closed, 1, "$v: the talon is closed");
        is(scalar(grep { $_->{kind} eq 'exchange' } @out), $swaps,
           "$v: and the close " . ($swaps ? 'carries' : 'does not carry')
           . ' an exchange for the opponent');
        is($d->hand_of($them)->has_card($up), $swaps,
           "$v: the opponent " . ($swaps ? 'has' : 'does not have') . ' the turn-up');
        is($d->turn_up, $swaps ? id_of($card) : $up,
           "$v: and the turn-up slot holds " . ($swaps ? 'their old card' : 'what it did'));
    }
};

subtest 'the close-time exchange needs the card, whatever the game' => sub {
    # An opponent without the nine changes nothing, which is the assertion that
    # stops the subtest above passing on a close that always swaps something.
    plan tests => 2;
    for my $v (qw(schnapsen sixtysix)) {
        my $d = with_trump('H', $v);
        my $up = $d->turn_up;
        my $closer = $d->turn;
        my $them = $closer eq 'p1' ? 'p2' : 'p1';
        $d->hand_of($them)->cards([ map { id_of($_) } qw(AS TS KS) ]);
        $d->apply($closer, { kind => 'close' });
        is($d->turn_up, $up, "$v: with no exchange card held, the turn-up is untouched");
    }
};

done_testing();
