#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(id_of name_of points_of);
use Game::Schnapsen::Variant qw(variants exchange_rank);
use Game::Schnapsen::Deck qw(pack_for);
use Game::Schnapsen::Deal ();

# The parts of the exchange and the close that BOTH games agree about, plus the
# conservation invariant carried across them. A swap and a close are the two
# places in this phase where a card moves without being played, which makes them
# the two most likely places to lose or duplicate one.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();
use constant MAX_TRICKS => 30;

sub with_trump {
    my ($suit, $variant) = @_;
    for my $n (1 .. 600) {
        my $d = Game::Schnapsen::Deal->build(
            variant => $variant, seed => seed("ec $suit $n"), number => 1, dealer => 'p1');
        return $d if $d->trump eq $suit;
    }
    return undef;
}

sub give_trick {
    my ($d, $seat) = @_;
    $d->tricks([ @{ $d->tricks },
                 { leader => $seat, lead => 1, follow => 2, winner => $seat } ]);
    return;
}

sub all_cards {
    my ($d) = @_;
    return (@{ $d->hand_of('p1')->cards }, @{ $d->hand_of('p2')->cards },
            @{ $d->talon },
            (defined $d->turn_up ? ($d->turn_up) : ()),
            (defined $d->lead ? ($d->lead) : ()),
            map { ($_->{lead}, $_->{follow}) } @{ $d->tricks });
}

# ---- the exchange, as a swap ---------------------------------------------------------

subtest 'an exchange swaps two cards and creates none' => sub {
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = with_trump('H', $v);
        my $card = id_of(exchange_rank($v) . 'H');
        my $up = $d->turn_up;

        $d->hand_of('p2')->cards([ $card, id_of('AS'), id_of('TS') ]);
        give_trick($d, 'p2');
        my $before = $d->hand_of('p2')->count;
        my $talon = $d->talon_left;

        my @out = $d->apply('p2', { kind => 'exchange' });

        is_deeply(\@out, [ { kind => 'exchange', seat => 'p2' } ],
                  "$v: the exchange reports a seat and nothing else");
        ok($d->hand_of('p2')->has_card($up), "$v: the turn-up is in the hand");
        ok(!$d->hand_of('p2')->has_card($card), "$v: and the low trump is not");
        is($d->turn_up, $card, "$v: which is now the turn-up");
        is($d->hand_of('p2')->count, $before, "$v: the hand is the same size");
        is($d->talon_left, $talon, "$v: and so is the talon");
    }
};

subtest 'the exchange payload names no card, because it cannot need to' => sub {
    # The card is the lowest trump of a suit everybody can see, so the event has
    # nothing to say. A payload that never held it cannot leak it, which is what
    # a consumer keeping hands secret relies on.
    plan tests => scalar @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = with_trump('H', $v);
        $d->hand_of('p2')->cards([ id_of(exchange_rank($v) . 'H'), id_of('AS') ]);
        give_trick($d, 'p2');
        my @out = $d->apply('p2', { kind => 'exchange' });
        is_deeply([ sort keys %{ $out[0] } ], [qw(kind seat)],
                  "$v: the event carries a kind and a seat, and no card");
    }
};

subtest 'the exchange is refused once the talon is closed or spent' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $rank = exchange_rank($v);

        my $closed = with_trump('H', $v);
        $closed->hand_of('p2')->cards([ id_of("${rank}H"), id_of('AS') ]);
        give_trick($closed, 'p2');
        $closed->closed(1);
        $closed->drawn(1);
        is($closed->can_exchange('p2'), undef, "$v: not once the talon is closed");

        my $spent = with_trump('H', $v);
        $spent->hand_of('p2')->cards([ id_of("${rank}H"), id_of('AS') ]);
        give_trick($spent, 'p2');
        $spent->talon([]);
        $spent->turn_up(undef);
        $spent->drawn(1);
        is($spent->can_exchange('p2'), undef, "$v: nor once it is exhausted");

        my $off = with_trump('H', $v);
        $off->hand_of('p1')->cards([ id_of("${rank}H"), id_of('AS') ]);
        give_trick($off, 'p1');
        is(scalar(grep { $_->{kind} eq 'exchange' } @{ $off->legal('p1') }), 0,
           "$v: and never by the seat that is not on lead");
    }
};

# ---- the close, and the snapshot it takes ---------------------------------------------

subtest 'a close records where both players stood at that moment' => sub {
    # Divergence 6 is paid in phase 04, but the snapshot it reads is taken here,
    # unconditionally and in both games. Taking it always costs nothing and
    # means the Schnapsen path is not a special case that exists only sometimes.
    plan tests => 5 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = with_trump('H', $v);
        give_trick($d, 'p2');
        my $taken = { %{ $d->taken } };
        $taken->{p2} = 33;
        $d->taken($taken);

        is($d->close_state, undef, "$v: an open deal has no snapshot");
        $d->apply($d->turn, { kind => 'close' });

        my $s = $d->close_state;
        is($s->{by}, 'p2', "$v: the snapshot names the closer");
        is($s->{p2}{tricks}, 1, "$v: with their tricks");
        is($s->{p2}{points}, 33, "$v: and their points");
        is($s->{p1}{tricks}, 0, "$v: and the same for the opponent");
    }
};

subtest 'closing stops the drawing without destroying the cards' => sub {
    # `talon_left` counts what is there; `draw_left` counts what may be drawn.
    # A closed talon and an empty one play identically and score differently, so
    # a single number would be right about the play and wrong about the result.
    plan tests => 5 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = with_trump('H', $v);
        my $there = $d->talon_left;

        $d->apply($d->turn, { kind => 'close' });

        is($d->closed, 1, "$v: closed");
        is($d->closed_by, 'p2', "$v: by the non-dealer, who was on lead");
        is($d->draw_left, 0, "$v: nothing more may be drawn");
        is($d->talon_left, $there, "$v: but the cards are all still there");
        is($d->phase, 2, "$v: and the deal is in phase 2");
    }
};

subtest 'the talon cannot be closed twice, or after it empties' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = with_trump('H', $v);
        $d->apply($d->turn, { kind => 'close' });
        is($d->can_close($d->turn), 0, "$v: a closed talon cannot be closed again");
        # `cannot_close` and not `not_legal`: closing IS a move kind that belongs
        # to a seat on lead, so what is refused is this particular close rather
        # than the shape of the move. A consumer wants to tell the two apart.
        my $out = ($d->apply($d->turn, { kind => 'close' }))[0];
        is(ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted', 'cannot_close',
           "$v: and apply refuses it, saying which of the two it was");

        my $spent = with_trump('H', $v);
        $spent->talon([]);
        $spent->turn_up(undef);
        $spent->drawn(1);
        is($spent->can_close($spent->turn), 0, "$v: an exhausted talon cannot be closed");
    }
};

# ---- conservation across every declaration ----------------------------------------------

subtest 'no declaration loses, duplicates or invents a card' => sub {
    # The phase 02 invariant, carried through the moves that move a card without
    # playing it. A swap is the likeliest place in the engine to end up with two
    # of something.
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@leaks, @points, $declared, $checks);
        $declared = 0;
        for my $n (1 .. 60) {
            my $d = Game::Schnapsen::Deal->build(
                variant => $v, seed => seed("conserve-decl $v $n"),
                number => $n, dealer => 'p1');
            my $pack = join ',', @{ pack_for($v) };

            my $look = sub {
                my ($where) = @_;
                $checks++;
                my @all = all_cards($d);
                push @leaks, "$n $where: " . scalar(@all) . ' cards'
                    unless join(',', sort { $a <=> $b } @all) eq $pack;

                my $in_play = 0;
                $in_play += points_of($_)
                    for (@{ $d->hand_of('p1')->cards }, @{ $d->hand_of('p2')->cards },
                         @{ $d->talon },
                         (defined $d->turn_up ? ($d->turn_up) : ()),
                         (defined $d->lead ? ($d->lead) : ()));
                my $melded = 0;
                $melded += $_->{value} for grep { $_->{counted} } @{ $d->melds };
                my $total = $in_play + $d->points_of('p1') + $d->points_of('p2') - $melded;
                push @points, "$n $where: $total" unless $total == 120;
            };

            $look->('start');
            my $spins = 0;
            while (!$d->over && $spins++ < MAX_TRICKS) {
                my $seat = $d->turn;
                my $legal = $d->legal($seat);
                last unless @$legal;

                # Take every declaration that is offered, which is what makes
                # this sweep exercise them at all. Close only occasionally, or
                # every deal ends in phase 2 after one trick.
                my ($pick) = (grep { $_->{kind} eq 'marriage' } @$legal),
                             (grep { $_->{kind} eq 'exchange' } @$legal);
                $pick ||= (grep { $_->{kind} eq 'close' } @$legal)[0] if $n % 7 == 0;
                $pick ||= $legal->[-1];
                $declared++ if $pick->{kind} =~ /\A(marriage|exchange|close)\z/;

                $d->apply($seat, $pick);
                $look->($pick->{kind});
            }
        }
        is(scalar @leaks, 0, "$v: the pack is whole after every move")
            or diag(join "\n", @leaks[0 .. ($#leaks > 3 ? 3 : $#leaks)]);
        is(scalar @points, 0, "$v: and the 120 card points are all accounted for")
            or diag(join "\n", @points[0 .. ($#points > 3 ? 3 : $#points)]);
        cmp_ok($declared, '>', 50,
               "$v: $declared declarations were actually made across $checks positions");
    }
};

done_testing();
