#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(id_of name_of suit_of);
use Game::Schnapsen::Declare qw(marriages_in marriage_value MARRIAGE MARRIAGE_TRUMP);
use Game::Schnapsen::Deal ();

# Marriages. Both rulesets agree about every word of this file, so nothing here
# takes a variant except where it says so.
#
# THE RULE MOST OFTEN GOT WRONG is the last one: "the score does not count until
# the melder has taken a trick". A player who declares forty and never takes a
# trick scores nothing for it. An implementation that adds the points at the
# moment of declaring plays a game that looks right for an entire deal and is
# simply worth more than it should be.

sub seed { return Digest::SHA::sha256($_[0]) }

sub rig {
    # A deal with hands set by hand. Building through Deal->build and then
    # replacing the hands keeps the talon, the trump and the turn order real,
    # which matters because the marriage value depends on the trump suit.
    my (%o) = @_;
    my $d = Game::Schnapsen::Deal->build(
        variant => $o{variant} // 'schnapsen',
        seed    => seed($o{seed} // 'marriage'),
        number  => 1, dealer => 'p1');
    for my $seat (qw(p1 p2)) {
        next unless $o{$seat};
        $d->hand_of($seat)->cards([ map { id_of($_) } @{ $o{$seat} } ]);
    }
    return $d;
}

# Find a deal whose trump is a given suit, so a marriage can be made trump or not.
sub with_trump {
    my ($suit, $variant) = @_;
    for my $n (1 .. 400) {
        my $d = Game::Schnapsen::Deal->build(
            variant => $variant // 'schnapsen', seed => seed("trump $suit $n"),
            number => 1, dealer => 'p1');
        return $d if $d->trump eq $suit;
    }
    return undef;
}

# ---- the arithmetic ------------------------------------------------------------------

subtest 'a marriage is twenty, or forty in trumps' => sub {
    plan tests => 6;
    is(MARRIAGE, 20, 'a plain marriage is twenty');
    is(MARRIAGE_TRUMP, 40, 'a trump marriage is forty');
    is(marriage_value('S', 'H'), 20, 'spades when hearts are trumps');
    is(marriage_value('H', 'H'), 40, 'and hearts when they are');

    my $m = marriages_in([ map { id_of($_) } qw(KS QS AH TD) ], 'H');
    is(scalar @$m, 1, 'one marriage found');
    is_deeply([ $m->[0]{suit}, $m->[0]{value}, $m->[0]{king}, $m->[0]{queen} ],
              [ 'S', 20, id_of('KS'), id_of('QS') ], 'named, valued and with both cards');
};

subtest 'a king or a queen alone is not a marriage' => sub {
    plan tests => 3;
    is_deeply(marriages_in([ map { id_of($_) } qw(KS AH TD JC) ], 'H'), [],
              'a king alone is nothing');
    is_deeply(marriages_in([ map { id_of($_) } qw(QS AH TD JC) ], 'H'), [],
              'and a queen alone is nothing');
    is_deeply(marriages_in([ map { id_of($_) } qw(KS QH AH TD) ], 'H'), [],
              'and a king of one suit with a queen of another is nothing');
};

subtest 'two marriages in one hand are both found' => sub {
    plan tests => 3;
    my $m = marriages_in([ map { id_of($_) } qw(KS QS KH QH) ], 'H');
    is(scalar @$m, 2, 'both of them');
    is_deeply([ map { $_->{suit} } @$m ], [qw(H S)], 'in suit order');
    is_deeply([ map { $_->{value} } @$m ], [ 40, 20 ], 'the trump one worth forty');
};

# ---- declaring, and what it obliges you to do ------------------------------------------

subtest 'only the player on lead may declare, and must then lead one of the two' => sub {
    plan tests => 7;
    my $d = with_trump('H');
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS AD TD JD) ]);
    $d->hand_of('p1')->cards([ map { id_of($_) } qw(AC TC KC QD JC) ]);

    is($d->turn, 'p2', 'the non-dealer is on lead');
    my ($offer) = grep { $_->{kind} eq 'marriage' } @{ $d->legal('p2') };
    is_deeply($offer, { kind => 'marriage', suit => 'S', value => 20 },
              'the marriage is offered, at twenty because spades are not trumps');

    is_deeply([ grep { $_->{kind} eq 'marriage' } @{ $d->legal('p1') } ], [],
              'and the seat not on lead is offered nothing at all');

    my @out = $d->apply('p2', { kind => 'marriage', suit => 'S' });
    is_deeply(\@out, [ { kind => 'marriage', seat => 'p2', suit => 'S', value => 20 } ],
              'declaring reports itself');
    is($d->turn, 'p2', 'and does NOT hand the turn over: a declaration is not a play');

    # MUST LEAD ONE OF THE TWO. Offering them without enforcing it would let a
    # player declare and then lead something else entirely.
    is_deeply([ sort { $a <=> $b } map { $_->{card} }
                grep { $_->{kind} eq 'lead' } @{ $d->legal('p2') } ],
              [ sort { $a <=> $b } (id_of('KS'), id_of('QS')) ],
              'only the king and queen may now be led');

    my $out = ($d->apply('p2', { kind => 'lead', card => id_of('AD') }))[0];
    is(ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted', 'must_lead',
       'and leading anything else is refused');
};

subtest 'only one marriage may be declared before a lead' => sub {
    plan tests => 3;
    my $d = with_trump('H');
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS KD QD AC) ]);

    is(scalar(grep { $_->{kind} eq 'marriage' } @{ $d->legal('p2') }), 2,
       'both marriages are offered to begin with');
    $d->apply('p2', { kind => 'marriage', suit => 'S' });
    is_deeply([ grep { $_->{kind} eq 'marriage' } @{ $d->legal('p2') } ], [],
              'and none once one has been declared');

    my $out = ($d->apply('p2', { kind => 'marriage', suit => 'D' }))[0];
    is(ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted', 'no_marriage',
       'a second is refused: you cannot lead two cards');
};

subtest 'a marriage you do not hold is refused' => sub {
    plan tests => 2;
    my $d = with_trump('H');
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS AD TD JD) ]);
    for my $suit (qw(D C)) {
        my $out = ($d->apply('p2', { kind => 'marriage', suit => $suit }))[0];
        is(ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted', 'no_marriage',
           "a marriage in $suit, which is not held");
    }
};

# ---- THE RULE: it does not count until you take a trick -----------------------------------

subtest 'the twenty does not count until the melder has taken a trick' => sub {
    plan tests => 6;
    my $d = with_trump('H');
    # p2 declares in spades and leads the king. p1 trumps it, so p2 has no trick.
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS AD TD JD) ]);
    $d->hand_of('p1')->cards([ map { id_of($_) } qw(AH TH KC QC JC) ]);

    $d->apply('p2', { kind => 'marriage', suit => 'S' });
    is($d->points_of('p2'), 0, 'declaring alone scores nothing');

    $d->apply('p2', { kind => 'lead', card => id_of('KS') });
    $d->apply('p1', { kind => 'follow', card => id_of('AH') });
    is($d->last_trick->{winner}, 'p1', 'the trump takes the trick');
    is($d->points_of('p2'), 0, 'and the twenty still has not counted');
    is($d->points_of('p1'), 4 + 11, 'while p1 has the cards they took');

    # Now give p2 a trick, and the pending twenty lands. Rigged rather than
    # searched: an earlier version picked a card and skipped the two assertions
    # when p2 happened not to win, which is an assertion that can quietly stop
    # running.
    $d->apply($d->turn, { kind => 'draw' }) if $d->pending_draw;
    $d->talon([]);
    $d->turn_up(undef);
    $d->drawn(1);
    $d->hand_of('p1')->cards([ map { id_of($_) } qw(JC) ]);
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(TH) ]);

    my $before = $d->points_of('p2');
    $d->apply('p1', { kind => 'lead', card => id_of('JC') });
    $d->apply('p2', { kind => 'follow', card => id_of('TH') });

    is($d->last_trick->{winner}, 'p2', 'p2 trumps the club and takes a trick');
    is($d->points_of('p2'), $before + 20 + 2 + 10,
       'and the twenty lands with it, on top of the cards in the trick');
};

subtest 'a marriage declared after a trick counts at once' => sub {
    plan tests => 2;
    my $d = with_trump('H');
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(AH KS QS AD TD) ]);
    $d->hand_of('p1')->cards([ map { id_of($_) } qw(9H JD KC QC JC) ]);

    # p2 takes a trick with the ace of trumps first.
    $d->apply('p2', { kind => 'lead', card => id_of('AH') });
    $d->apply('p1', { kind => 'follow', card => id_of('9H') });
    is($d->last_trick->{winner}, 'p2', 'p2 has a trick');
    $d->apply($d->turn, { kind => 'draw' }) if $d->pending_draw;

    my $before = $d->points_of('p2');
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS AD TD JD) ]);
    $d->apply('p2', { kind => 'marriage', suit => 'S' });
    is($d->points_of('p2'), $before + 20, 'so the twenty counts immediately');
};

subtest 'a marriage never taken to a trick is never scored' => sub {
    # The whole point, stated as an end-to-end property: p2 declares, loses
    # every trick, and finishes with nothing for the declaration.
    plan tests => 2;
    my $d = with_trump('H');
    $d->hand_of('p2')->cards([ map { id_of($_) } qw(KS QS) ]);
    $d->hand_of('p1')->cards([ map { id_of($_) } qw(AH TH) ]);
    $d->talon([]);
    $d->turn_up(undef);
    $d->drawn(1);

    $d->apply('p2', { kind => 'marriage', suit => 'S' });
    $d->apply('p2', { kind => 'lead', card => id_of('KS') });
    $d->apply('p1', { kind => 'follow', card => id_of('AH') });
    $d->apply('p1', { kind => 'lead', card => id_of('TH') });
    $d->apply('p2', { kind => 'follow', card => id_of('QS') });

    is($d->points_of('p2'), 0, 'p2 scored nothing at all');
    is(scalar(grep { $_->{counted} } @{ $d->melds }), 0, 'the meld was never counted');
};

done_testing();
