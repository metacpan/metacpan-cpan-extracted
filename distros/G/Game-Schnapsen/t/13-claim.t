#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(id_of);
use Game::Schnapsen::Variant qw(variants);
use Game::Schnapsen::Scoring qw(deal_result TARGET_POINTS PENALTY PENALTY_SCHWARZ);
use Game::Schnapsen::Deal ();

# Claiming is a MOVE, and the deal is never ended by arithmetic.
#
# The consequence the design was chosen for: legal() offers `claim` whenever the
# TIMING allows and not only when the player actually holds 66. Offering it only
# when it would succeed makes the penalty unreachable and quietly turns this into
# a different game, so a false claim has to be possible.
#
#   "A claim may be made just after winning a trick or just after declaring a
#    marriage, but not at any other time."

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();

sub fresh {
    my ($v, $n) = @_;
    return Game::Schnapsen::Deal->build(
        variant => $v, seed => seed("claim $v"), number => $n || 1, dealer => 'p1');
}

sub offers { my ($d, $seat, $kind) = @_;
             return scalar grep { $_->{kind} eq $kind } @{ $d->legal($seat) } }

sub give_points {
    my ($d, $seat, $n) = @_;
    my $t = { %{ $d->taken } };
    $t->{$seat} = $n;
    $d->taken($t);
    return;
}

sub give_trick {
    my ($d, $seat) = @_;
    $d->tricks([ @{ $d->tricks },
                 { leader => $seat, lead => 1, follow => 2, winner => $seat } ]);
    return;
}

# ---- when a claim may be made ---------------------------------------------------------

subtest 'nobody may claim before a trick has been played' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        is($d->can_claim('p2'), 0, "$v: not on the opening lead");
        is(offers($d, 'p2', 'claim'), 0, "$v: and it is not offered");
        my $out = ($d->apply('p2', { kind => 'claim' }))[0];
        is(ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted', 'cannot_claim',
           "$v: and apply refuses it");
    }
};

subtest 'a claim may be made just after taking a trick' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $leader = $d->turn;
        $d->apply($leader, { kind => 'lead', card => $d->hand_of($leader)->cards->[0] });
        my $other = $d->turn;

        is($d->can_claim($other), 0, "$v: not in the middle of a trick");
        $d->apply($other, { kind => 'follow', card => $d->legal($other)->[0]{card} });
        my $winner = $d->last_trick->{winner};
        is($d->can_claim($winner), 1, "$v: but yes to whoever took it");
        is($d->can_claim($winner eq 'p1' ? 'p2' : 'p1'), 0,
           "$v: and never to the seat that lost it");
    }
};

subtest 'a claim may be made just after declaring a marriage' => sub {
    # Both pages allow it, and Sixty-Six says so outright: "you can show the
    # marriage and immediately declare 'out'". A declaration that did not open
    # the claim window could not express that, which is why marriages are their
    # own move rather than a rider on the lead.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS AD) ]);
        is($d->can_claim('p2'), 0, "$v: no claim before anything has happened");
        $d->apply('p2', { kind => 'marriage', suit => 'S' });
        is($d->can_claim('p2'), 1, "$v: and a claim once the marriage is shown");
    }
};

subtest 'the claim window closes when a card is on the table' => sub {
    # MUTATION-DRIVEN. Written first as "p2 leads, then p2 cannot claim", which
    # passes for the wrong reason: after p2 leads it is p1's turn, so can_claim
    # refuses on the turn check and never reaches the one being tested. Removing
    # the guard entirely left the whole suite green.
    #
    # So this plays a full trick first, and then asks the seat whose turn it
    # ACTUALLY is, in the middle of the next one.
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $leader = $d->turn;
        $d->apply($leader, { kind => 'lead', card => $d->hand_of($leader)->cards->[0] });
        my $follower = $d->turn;
        $d->apply($follower, { kind => 'follow', card => $d->legal($follower)->[0]{card} });
        $d->apply($d->turn, { kind => 'draw' }) if $d->pending_draw;

        my $on_lead = $d->turn;
        is($d->can_claim($on_lead), 1, "$v: open to the winner of the first trick");

        $d->apply($on_lead, { kind => 'lead', card => $d->hand_of($on_lead)->cards->[0] });
        my $answering = $d->turn;

        # A trick HAS been played, so the tricks check no longer hides anything,
        # and it really is this seat's turn. Only the lead guard can refuse now.
        cmp_ok(scalar @{ $d->tricks }, '>', 0, "$v: a trick has been played");
        is($d->turn, $answering, "$v: and it is the answering seat's move");
        is($d->can_claim($answering), 0,
           "$v: yet they may not claim, because a card is on the table");
    }
};

# ---- a correct claim ----------------------------------------------------------------------

subtest 'a correct claim wins the deal there and then' => sub {
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        give_trick($d, 'p2');
        give_trick($d, 'p1');
        give_points($d, 'p2', 70);
        give_points($d, 'p1', 40);

        my @out = $d->apply('p2', { kind => 'claim' });

        is($out[0]{kind}, 'claim', "$v: the claim reports itself");
        is($out[1]{kind}, 'deal_end', "$v: and ends the deal");
        is($d->over, 1, "$v: which is over");
        is($d->result->{winner}, 'p2', "$v: won by the claimant");
        is($d->result->{how}, 'claim', "$v: by claiming");
        is($d->result->{game_points}, 1, "$v: for one game point, the opponent being over 33");
    }
};

subtest 'a correct claim wins even if the opponent passed 66 first' => sub {
    # "A player who correctly goes out with 66 or more card points wins the deal,
    # even if it turns out that the opponent had reached 66 earlier." This is the
    # reason the engine must not end a deal the moment a total passes 66: it
    # counts, and it never goes out for anybody.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        give_trick($d, 'p2');
        give_trick($d, 'p1');
        give_points($d, 'p1', 80);
        give_points($d, 'p2', 70);

        is($d->over, 0, "$v: a deal where BOTH are past 66 is still running");
        $d->apply('p2', { kind => 'claim' });
        is($d->result->{winner}, 'p2', "$v: and the one who says so wins it");
    }
};

subtest 'sixty-six exactly is enough' => sub {
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        for my $points (TARGET_POINTS, TARGET_POINTS - 1) {
            my $d = fresh($v);
            give_trick($d, 'p2');
            give_trick($d, 'p1');
            give_points($d, 'p2', $points);
            give_points($d, 'p1', 40);
            $d->apply('p2', { kind => 'claim' });
            is($d->result->{winner}, $points >= TARGET_POINTS ? 'p2' : 'p1',
               "$v: $points points is " . ($points >= TARGET_POINTS ? 'a win' : 'a false claim'));
        }
    }
};

subtest 'a counted marriage carries a claim over the line' => sub {
    # The marriage only counts once its owner has taken a trick, so a claim that
    # leans on one is a claim that leans on the fold-in working.
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        give_trick($d, 'p2');
        give_points($d, 'p2', 30);
        $d->hand_of('p2')->cards([ map { id_of($_) } ('K' . $d->trump, 'Q' . $d->trump,
                                                      'A' . ($d->trump eq 'S' ? 'H' : 'S')) ]);

        is($d->can_claim('p2'), 1, "$v: a claim is available on 30, and would be false");
        $d->apply('p2', { kind => 'marriage', suit => $d->trump });
        is($d->points_of('p2'), 70, "$v: the trump marriage takes them to 70");
        $d->apply('p2', { kind => 'claim' });
        is($d->result->{winner}, 'p2', "$v: so the claim is good");
    }
};

done_testing();
