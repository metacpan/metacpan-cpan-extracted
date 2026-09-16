#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin::Card qw(id_of name_of);
use Game::Gin::Hand ();
use Game::Gin::Deal ();
use Game::Gin::Deadwood qw(deadwood KNOCK_AT);
use Game::Gin::Scoring qw(best_layoff settle GIN_BONUS UNDERCUT_BONUS BIG_GIN_BONUS);

sub h { return [ map { id_of($_) } @_ ] }
sub names { return join ' ', map { name_of($_) } sort { $a <=> $b } @{ $_[0] } }

# A deal built to order, so a knock can be tested on a hand somebody can read
# rather than on whatever the seed happened to produce.
sub rigged {
    my (%o) = @_;
    return Game::Gin::Deal->new(
        seed    => "\0" x 32,
        number  => 1,
        dealer  => $o{dealer} // 'p1',
        hands   => { p1 => Game::Gin::Hand->new(cards => h(@{ $o{p1} })),
                     p2 => Game::Gin::Hand->new(cards => h(@{ $o{p2} })) },
        stock   => h(@{ $o{stock}   || [qw(2H 3H 4H 5H 6H 7H 8H 9H)] }),
        discard => h(@{ $o{discard} || [qw(KD)] }),
        turn    => $o{turn}  // 'p1',
        phase   => $o{phase} // 'discard',
        taken   => 0,
        result  => undef,
    );
}

# ---- the numbers this dist implements, and which ruleset they are ---------------------------

subtest 'the pinned constants' => sub {
    plan tests => 4;
    # These are the MODERN set, as Wikipedia states it. The older published
    # set (Pagat, "early official rules") is gin 20 and undercut 10. Pinning
    # them here means a change has to be deliberate.
    is(KNOCK_AT,        10, 'knock at ten or less');
    is(GIN_BONUS,       25, 'gin is worth 25');
    is(UNDERCUT_BONUS,  25, 'an undercut is worth 25');
    is(BIG_GIN_BONUS,   31, 'and big gin 31');
};

# ---- lay-offs ---------------------------------------------------------------------------------

subtest 'a lay-off extends the knocker melds and never the other way' => sub {
    plan tests => 5;

    # The knocker has run 5S 6S 7S. The defender holds 8S, which extends it,
    # and KD, which extends nothing.
    my $lay = best_layoff(h(qw(8S KD)), [ h(qw(5S 6S 7S)) ]);
    is(names($lay->{laid}), '8S', 'the eight goes off');
    is($lay->{deadwood}, 10, 'leaving only the king');

    # A set grows to four and no further.
    my $set = best_layoff(h(qw(7C)), [ h(qw(7S 7H 7D)) ]);
    is(names($set->{laid}), '7C', 'the fourth seven goes onto the set');
    is($set->{deadwood}, 0, 'leaving nothing');

    # Nothing to lay off onto is not an error.
    my $none = best_layoff(h(qw(KD)), []);
    is($none->{deadwood}, 10, 'with no melds the deadwood is untouched');
};

subtest 'the lay-off is searched, because a card can extend two melds' => sub {
    plan tests => 2;
    # 9S extends the run 6S 7S 8S. 9H, 9D and 9C are a set already; laying the
    # 9S onto the RUN and keeping the set is worth more than the greedy answer
    # that meets the set first and puts the 9S there instead, leaving the run
    # unextended and a card stranded.
    my $lay = best_layoff(h(qw(9S TS)), [ h(qw(6S 7S 8S)) ]);
    is(names($lay->{laid}), '9S TS', 'both cards extend the run in turn');
    is($lay->{deadwood}, 0, 'and nothing is left');
};

# ---- what a hand was worth --------------------------------------------------------------------

subtest 'a plain knock scores the difference' => sub {
    plan tests => 3;
    my $r = settle(
        knocker => 'p1', defender => 'p2',
        knocker_deadwood => 4,
        knocker_melds    => [ h(qw(5S 6S 7S)) ],
        defender_cards   => h(qw(KD QC 2H)),        # 10 + 10 + 2, nothing melds
    );
    is($r->{kind}, 'knock', 'a knock');
    is($r->{winner}, 'p1', 'to the knocker');
    is($r->{points}, 22 - 4, 'worth the difference in deadwood');
};

subtest 'gin scores 25 and the whole of the other hand' => sub {
    plan tests => 4;
    my $r = settle(
        knocker => 'p1', defender => 'p2', gin => 1,
        knocker_deadwood => 0,
        knocker_melds    => [ h(qw(5S 6S 7S)) ],
        defender_cards   => h(qw(8S KD)),           # the 8S WOULD extend the run
    );
    is($r->{kind}, 'gin', 'gin');
    is($r->{points}, GIN_BONUS + 18, '25 plus the defender count');
    # THE RULE PEOPLE MISPLAY: no lay-offs against gin. The eight of spades
    # extends the knocker's run and still counts against its holder.
    is_deeply($r->{laid_off}, [], 'nothing was laid off');
    is($r->{defender_deadwood}, 18, 'so the eight counts against them');
};

subtest 'big gin scores 31' => sub {
    plan tests => 2;
    my $r = settle(
        knocker => 'p1', defender => 'p2', gin => 1, big_gin => 1,
        knocker_deadwood => 0,
        knocker_melds    => [ h(qw(5S 6S 7S)) ],
        defender_cards   => h(qw(KD)),
    );
    is($r->{kind}, 'big_gin', 'big gin');
    is($r->{points}, BIG_GIN_BONUS + 10, '31 plus the defender count');
};

subtest 'an undercut, including on equal counts' => sub {
    plan tests => 6;

    # Strictly lower: clearly an undercut.
    my $under = settle(
        knocker => 'p1', defender => 'p2',
        knocker_deadwood => 9,
        knocker_melds    => [ h(qw(5S 6S 7S)) ],
        defender_cards   => h(qw(2H)),
    );
    is($under->{kind}, 'undercut', 'the defender was lower');
    is($under->{winner}, 'p2', 'so the defender scores');
    is($under->{points}, UNDERCUT_BONUS + (9 - 2), '25 plus the difference');

    # EQUAL COUNTS ARE AN UNDERCUT TOO, which is the detail people
    # misremember: a knock that merely ties does not score.
    my $tie = settle(
        knocker => 'p1', defender => 'p2',
        knocker_deadwood => 2,
        knocker_melds    => [ h(qw(5S 6S 7S)) ],
        defender_cards   => h(qw(2H)),
    );
    is($tie->{kind}, 'undercut', 'equal counts are an undercut');
    is($tie->{winner}, 'p2', 'and the defender takes it');
    is($tie->{points}, UNDERCUT_BONUS + 0, 'for the bonus alone');
};

subtest 'a lay-off can turn a knock into an undercut' => sub {
    plan tests => 3;
    # The knocker knocks on 6. The defender looks worse at 8, but the eight of
    # spades goes onto the run and leaves them on nothing.
    my $r = settle(
        knocker => 'p1', defender => 'p2',
        knocker_deadwood => 6,
        knocker_melds    => [ h(qw(5S 6S 7S)) ],
        defender_cards   => h(qw(8S)),
    );
    is(names($r->{laid_off}), '8S', 'the eight goes off');
    is($r->{defender_deadwood}, 0, 'leaving nothing');
    is($r->{kind}, 'undercut', 'so the knock became an undercut');
};

# ---- through the deal machine --------------------------------------------------------------------

subtest 'knocking through a deal' => sub {
    plan tests => 6;
    # p1 holds eleven: ten that meld completely, plus a king to throw.
    my $d = rigged(
        p1 => [qw(AS 2S 3S 4S 5H 6H 7H 8D 9D TD KC)],
        p2 => [qw(2C 4C 6D 8H TH QS KD 3H 5C 7C)],
        turn => 'p1', phase => 'discard',
    );
    my @offered = grep { $_->{knock} } @{ $d->legal('p1') };
    ok(scalar @offered, 'a knock is on offer');

    my @out = $d->apply('p1', { kind => 'discard', card => id_of('KC'), knock => 1 });
    is($out[0]{kind}, 'discard', 'the discard happened');
    ok($d->over, 'and the hand is over');

    my $r = $d->result;
    is($r->{kind}, 'gin', 'it was gin, detected without being declared');
    is($r->{winner}, 'p1', 'to the knocker');
    is($r->{knocker_deadwood}, 0, 'with nothing left');
};

subtest 'a knock above the threshold is refused' => sub {
    plan tests => 3;
    my $d = rigged(
        p1 => [qw(AS 3S 5S 7S 9H JH KD 2C 4C 6C 8D)],   # nothing melds
        p2 => [qw(2H 4H 6H 8H TC QC KH 3D 5D 7D)],
        turn => 'p1', phase => 'discard',
    );
    my @offered = grep { $_->{knock} } @{ $d->legal('p1') };
    is(scalar @offered, 0, 'no knock is offered on a hand that cannot');

    my $e = $d->apply('p1', { kind => 'discard', card => id_of('KD'), knock => 1 });
    is(ref $e, 'Game::Gin::Error', 'and attempting one is refused');
    is($e->code, 'cannot_knock', 'by name');
};

subtest 'big gin through a deal' => sub {
    plan tests => 4;
    # Eleven cards, all of them melded: four melds of three, two and... no.
    # 4 + 4 + 3 = eleven: two runs of four and a set of three.
    my $d = rigged(
        p1 => [qw(AS 2S 3S 4S 5H 6H 7H 8H 9D 9C 9S)],
        p2 => [qw(2C 4C 6D 8D TH QS KD 3H 5C 7C)],
        turn => 'p1', phase => 'discard',
    );
    is(deadwood($d->hand_of('p1')->cards), 0, 'all eleven cards meld');
    my @offered = grep { $_->{kind} eq 'big_gin' } @{ $d->legal('p1') };
    ok(scalar @offered, 'big gin is offered');

    my @out = $d->apply('p1', { kind => 'big_gin' });
    is($out[0]{kind}, 'big_gin', 'and taken');
    is($d->result->{kind}, 'big_gin', 'and scored as big gin');
};

done_testing();
