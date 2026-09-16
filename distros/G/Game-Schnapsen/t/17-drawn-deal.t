#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen ();
use Game::Schnapsen::Card qw(id_of points_of);
use Game::Schnapsen::Variant qw(match_start next_dealer);

# A DRAWN DEAL, which only Sixty-Six can produce and which has to travel all the
# way out of the engine intact.
#
# Four separate things have to be right, and each is a different way to lose it:
#
#   it must not move the score
#   it must not end the match
#   it must not rotate the dealer
#   it must still advance the deal number
#
# Nothing else on this engine's roster has a result with no winner inside a
# running match, so it is the one most likely to be dropped on the way through -
# and the failure is silent, because a drawn deal scored as a win still plays.

sub seed { return Digest::SHA::sha256($_[0]) }

# Rig the current deal to a dead heat and let the last trick fall.
#
# THE ARITHMETIC, because getting it wrong gives a rig that quietly is not a
# draw and a file full of assertions about an ordinary deal.
#
# The taker wins the last trick, so they collect its two cards AND the ten-point
# bonus. With the ace and ten of trumps on the table that is 21 + 10 = 31. So
# for a dead heat after the bonus:
#
#     taker + 31 == opponent          and      taker + 21 + opponent == 120
#
# which is taker 34 and opponent 65: 34 + 21 + 10 = 65 against 65. A deal rigged
# to 60-60 before the last trick is NOT drawn, because the bonus breaks it, and
# that was the first version of this.
sub rig_draw {
    my ($g, $taker) = @_;
    my $them = $taker eq 'p1' ? 'p2' : 'p1';
    my $d = $g->deal;
    my $trump = $d->trump;

    $d->talon([]);
    $d->turn_up(undef);
    $d->drawn(1);
    $d->closed(0);
    $d->closed_by(undef);
    $d->close_state(undef);
    $d->melds([]);

    # One card each, so the next trick is the last. The taker holds the ace of
    # trumps against the ten of trumps, so the taker takes it.
    $d->hand_of($taker)->cards([ id_of("A$trump") ]);
    $d->hand_of($them)->cards([ id_of("T$trump") ]);
    my $on_table = points_of(id_of("A$trump")) + points_of(id_of("T$trump"));

    $d->tricks([ map { { leader => 'p1', lead => 1, follow => 2, winner => 'p1' } } 1 .. 4 ]);
    $d->taken({ $taker => 120 - $on_table - 65, $them => 65 });
    $d->turn($taker);
    $d->leader($taker);
    $d->lead(undef);
    return $d;
}

sub play_last_trick {
    my ($g) = @_;
    my $leader = $g->turn;
    my @out = $g->apply($leader, { kind => 'lead',
                                   card => $g->deal->hand_of($leader)->cards->[0] });
    my $other = $g->turn;
    push @out, $g->apply($other, { kind => 'follow',
                                   card => $g->legal($other)->[0]{card} });
    return @out;
}

# ---- the rig itself is checked before anything is concluded from it ---------------------

subtest 'the rigged position really is a dead heat' => sub {
    # A rig that quietly does not produce a draw would make every assertion below
    # pass by testing an ordinary deal. So the rig is verified first.
    plan tests => 4;
    my $g = Game::Schnapsen->build(variant => 'sixtysix', seed => seed('draw'));
    rig_draw($g, 'p1');
    my @out = play_last_trick($g);

    my ($end) = grep { $_->{kind} eq 'deal_end' } @out;
    ok($end, 'the deal ended');
    is($end->{points}{p1}, 65, 'p1 finished on 65, the ten included');
    is($end->{points}{p2}, 65, 'and p2 on 65');
    is($end->{how}, 'drawn', 'which the scoring calls drawn');
};

# ---- the four things that must be right ---------------------------------------------------

subtest 'a drawn deal pays nobody' => sub {
    plan tests => 3;
    my $g = Game::Schnapsen->build(variant => 'sixtysix', seed => seed('draw'));
    my $start = match_start('sixtysix');
    rig_draw($g, 'p1');
    play_last_trick($g);

    is($g->scores->{p1}, $start, 'p1 is where they started');
    is($g->scores->{p2}, $start, 'and so is p2');
    is($g->deals->[-1]{game_points}, 0, 'the deal was worth nothing');
};

subtest 'a drawn deal ends nothing' => sub {
    plan tests => 3;
    my $g = Game::Schnapsen->build(variant => 'sixtysix', seed => seed('draw'));
    rig_draw($g, 'p1');
    play_last_trick($g);

    is($g->over, 0, 'the match is still running');
    is($g->winner, undef, 'with nobody having won it');
    ok(defined $g->turn, 'and somebody to move in the next deal');
};

subtest 'a drawn deal leaves the dealer where they were' => sub {
    # Sixty-Six gives the deal to the winner, and a drawn deal has no winner, so
    # there is nobody to give it to. Neither page raises the question; this is an
    # inference and is recorded as one.
    plan tests => 2;
    is(next_dealer('sixtysix'), 'winner', 'sixtysix deals to the winner');

    my $g = Game::Schnapsen->build(variant => 'sixtysix', seed => seed('draw'));
    my $was = $g->dealer;
    rig_draw($g, 'p1');
    play_last_trick($g);
    is($g->dealer, $was, 'so a drawn deal deals again from the same seat');
};

subtest 'a drawn deal still advances the deal number' => sub {
    plan tests => 3;
    my $g = Game::Schnapsen->build(variant => 'sixtysix', seed => seed('draw'));
    is($g->number, 1, 'deal one');
    rig_draw($g, 'p1');
    play_last_trick($g);
    is($g->number, 2, 'and deal two follows it');
    is(scalar @{ $g->deals }, 1, 'with the drawn one recorded');
};

subtest 'the match carries on past a draw and finishes normally' => sub {
    # The end-to-end version: a drawn deal in the middle must not leave the match
    # in a state it cannot get out of.
    plan tests => 3;
    my $g = Game::Schnapsen->build(variant => 'sixtysix', seed => seed('draw'));
    rig_draw($g, 'p1');
    play_last_trick($g);
    is($g->over, 0, 'still going after the draw');

    my $moves = 0;
    while (!$g->over && $moves++ < 2000) {
        my $seat = $g->turn or last;
        my $legal = $g->legal($seat);
        last unless @$legal;
        my ($move) = ((grep { $_->{kind} eq 'draw' } @$legal),
                      (grep { $_->{kind} eq 'lead' } @$legal),
                      (grep { $_->{kind} eq 'follow' } @$legal));
        last unless $move;
        $g->apply($seat, $move);
    }
    is($g->over, 1, 'and it finishes');
    ok(defined $g->winner, 'with a winner');
};

# ---- schnapsen cannot do this at all ---------------------------------------------------------

subtest 'the same position in schnapsen is not drawn' => sub {
    # Divergence 5 from the other side. Schnapsen pays the last trick a flat one
    # and never looks at the cards, so a dead heat on card points is not a thing
    # that can happen to it.
    plan tests => 4;
    my $g = Game::Schnapsen->build(variant => 'schnapsen', seed => seed('draw'));
    rig_draw($g, 'p1');
    my @out = play_last_trick($g);

    my ($end) = grep { $_->{kind} eq 'deal_end' } @out;
    is($end->{how}, 'last_trick', 'schnapsen decides it on the last trick');
    is($end->{winner}, 'p1', 'won by whoever took it');
    is($end->{game_points}, 1, 'for exactly one');
    isnt($g->scores->{p1}, match_start('schnapsen'), 'and the score moved');
};

subtest 'a drawn deal never appears in a schnapsen match' => sub {
    # A sweep rather than a rig: if schnapsen could draw at all, a few dozen
    # matches would find it.
    plan tests => 2;
    my ($drawn, $deals) = (0, 0);
    for my $n (1 .. 20) {
        my $g = Game::Schnapsen->build(variant => 'schnapsen', seed => seed("nodraw $n"));
        my $moves = 0;
        while (!$g->over && $moves++ < 2000) {
            my $seat = $g->turn or last;
            my $legal = $g->legal($seat);
            last unless @$legal;
            my ($move) = ((grep { $_->{kind} eq 'draw' } @$legal),
                          (grep { $_->{kind} eq 'lead' } @$legal),
                          (grep { $_->{kind} eq 'follow' } @$legal));
            last unless $move;
            $g->apply($seat, $move);
        }
        $deals += scalar @{ $g->deals };
        $drawn += scalar grep { $_->{drawn} } @{ $g->deals };
    }
    cmp_ok($deals, '>', 60, "$deals schnapsen deals played");
    is($drawn, 0, 'and not one of them was drawn');
};

done_testing();
