#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(suit_of name_of);
use Game::Schnapsen::Variant qw(variants hand_size);
use Game::Schnapsen::Deal ();

# Phase 1, where the rules are that there are none: "There is no requirement to
# follow suit, nor to try to win the trick."
#
# The failure worth guarding is the phase-2 cascade leaking into phase 1. A deal
# played that way is legal, replayable and entirely plausible, and is simply a
# different game. Nothing but a test that counts what is on offer would notice.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();

sub fresh {
    my ($v, $n) = @_;
    return Game::Schnapsen::Deal->build(
        variant => $v, seed => seed("phase1 $v"), number => $n || 1, dealer => 'p1');
}

subtest 'a deal starts where both rulesets say it does' => sub {
    plan tests => 7 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        isa_ok($d, 'Game::Schnapsen::Deal');
        is($d->turn, 'p2', "$v: the non-dealer leads to the first trick");
        is($d->leader, 'p2', "$v: and is the leader");
        is($d->lead, undef, "$v: with nothing led yet");
        is($d->hand_of('p1')->count, hand_size($v), "$v: the dealer holds " . hand_size($v));
        is($d->phase, 1, "$v: the talon is open");
        is($d->trump, suit_of($d->turn_up), "$v: the turn-up sets the trump suit");
    }
};

subtest 'the leader may lead any card in hand' => sub {
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        # Filtered to leads: since the declarations exist, legal() also carries
        # whatever marriage, exchange or close the position offers.
        my @legal = grep { $_->{kind} eq 'lead' } @{ $d->legal('p2') };
        is(scalar @legal, hand_size($v), "$v: every card is a legal lead");
        is_deeply([ sort { $a <=> $b } map { $_->{card} } @legal ],
                  $d->hand_of('p2')->sorted, "$v: and they are exactly the hand");
    }
};

subtest 'the follower may answer with any card in hand' => sub {
    # THE ASSERTION THIS FILE EXISTS FOR. Rigged so that the phase-2 cascade
    # would give a different answer: the follower is made to hold at least one
    # card of the led suit, so a cascade leaking into phase 1 would offer only
    # those and this count would drop.
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($d, $lead, $suited);
        for my $n (1 .. 60) {
            $d = fresh($v, $n);
            my $their = $d->hand_of('p1')->cards;
            ($lead) = grep {
                my $s = suit_of($_);
                scalar grep { suit_of($_) eq $s } @$their;
            } @{ $d->hand_of('p2')->cards };
            if (defined $lead) {
                $suited = scalar grep { suit_of($_) eq suit_of($lead) } @$their;
                last;
            }
        }
        ok(defined $lead, "$v: found a deal where the follower holds the suit led");
        cmp_ok($suited, '<', hand_size($v),
               "$v: and does not hold only that suit, so the two rules differ here");

        $d->apply('p2', { kind => 'lead', card => $lead });
        is(scalar @{ $d->legal('p1') }, hand_size($v),
           "$v: the whole hand answers the " . name_of($lead));
    }
};

subtest 'a lead leaves the hand and puts the other seat on move' => sub {
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $card = $d->hand_of('p2')->cards->[0];
        my @out = $d->apply('p2', { kind => 'lead', card => $card });

        is_deeply(\@out, [ { kind => 'lead', seat => 'p2', card => $card } ],
                  "$v: a lead reports itself and nothing else");
        is($d->lead, $card, "$v: the card is on the table");
        is($d->hand_of('p2')->count, hand_size($v) - 1, "$v: and out of the hand");
        is($d->turn, 'p1', "$v: the other seat is to answer");
    }
};

subtest 'what apply refuses' => sub {
    plan tests => 6;
    my $d = fresh('schnapsen');
    my $mine = $d->hand_of('p2')->cards->[0];
    my $theirs = $d->hand_of('p1')->cards->[0];

    my $code = sub {
        my $out = ($d->apply(@_))[0];
        return ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted';
    };

    is($code->('p1', { kind => 'lead', card => $theirs }), 'not_your_turn',
       'a move out of turn');
    is($code->('p2', { kind => 'follow', card => $mine }), 'not_legal',
       'following when nobody has led');
    is($code->('p2', { kind => 'nonsense', card => $mine }), 'not_legal',
       'a move that is not one');
    is($code->('p2', {}), 'not_legal', 'a move with no kind');
    is($code->('p2', { kind => 'lead', card => $theirs }), 'not_held',
       'leading a card from the other hand');
    is($code->('p2', { kind => 'lead' }), 'not_held', 'leading no card at all');
};

subtest 'a bad deal is refused rather than built' => sub {
    plan tests => 4;
    for my $bad ([ variant => 'bezique' ], [ seed => 'short' ], [ number => 0 ]) {
        my %o = (variant => 'schnapsen', seed => seed('x'), number => 1, @$bad);
        my $d = Game::Schnapsen::Deal->build(%o);
        isa_ok($d, 'Game::Schnapsen::Error', "$bad->[0] => $bad->[1]");
    }
    is(Game::Schnapsen::Deal->build(variant => 'bezique', seed => seed('x'))->code,
       'bad_variant', 'and the variant is named as the problem');
};

done_testing();
