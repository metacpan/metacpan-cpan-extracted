#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin::Card qw(id_of name_of);
use Game::Gin::Hand ();
use Game::Gin::Deal ();

# The first turn of a hand is not a normal turn, and it is the part of gin
# rummy that implementations get wrong. Four paths:
#
#   the non-dealer takes the upcard
#   the non-dealer passes and the dealer takes it
#   both pass and the non-dealer draws blind
#   and in that last case the refused card is NOT on offer
#
# Each is a different set of legal moves, which is why the phase is a state
# and not a condition.

sub seed { return Digest::SHA::sha256("turn:$_[0]") }
sub fresh { return Game::Gin::Deal->build(seed => seed($_[0] // 1), number => 1, dealer => 'p1') }
sub kinds { return join ',', sort map { $_->{kind} } @{ $_[0] } }

# ---- the shape a hand starts in ---------------------------------------------------------

subtest 'the deal' => sub {
    plan tests => 6;
    my $d = fresh();
    isa_ok($d, 'Game::Gin::Deal');
    is($d->hand_of('p1')->count, 10, 'ten to the dealer');
    is($d->hand_of('p2')->count, 10, 'ten to the non-dealer');
    is($d->stock_left, 31, 'thirty-one in the stock');
    ok(defined $d->upcard, 'an upcard is turned');
    is($d->turn, 'p2', 'and the NON-dealer has the first say');
};

# ---- the four paths -----------------------------------------------------------------------

subtest 'path one: the non-dealer takes the upcard' => sub {
    plan tests => 4;
    my $d = fresh();
    my $up = $d->upcard;
    is(kinds($d->legal('p2')), 'pass,take', 'take or pass, and nothing else');

    my @out = $d->apply('p2', { kind => 'take' });
    is($out[0]{kind}, 'take', 'taken');
    is($d->hand_of('p2')->count, 11, 'the hand is eleven');
    is($d->phase, 'discard', 'and a discard is owed');
};

subtest 'path two: the non-dealer passes and the dealer takes' => sub {
    plan tests => 4;
    my $d = fresh(2);
    my $up = $d->upcard;
    $d->apply('p2', { kind => 'pass' });
    is($d->turn, 'p1', 'the dealer is asked next');
    is(kinds($d->legal('p1')), 'pass,take', 'with the same two moves');

    $d->apply('p1', { kind => 'take' });
    is($d->hand_of('p1')->count, 11, 'the dealer holds eleven');
    is($d->turn, 'p1', 'and owes the discard');
};

subtest 'path three: both pass, and the non-dealer draws blind' => sub {
    plan tests => 5;
    my $d = fresh(3);
    my $up = $d->upcard;
    $d->apply('p2', { kind => 'pass' });
    $d->apply('p1', { kind => 'pass' });

    is($d->turn, 'p2', 'it comes back to the non-dealer');
    is($d->phase, 'forced_draw', 'in a phase of its own');

    # THE REFUSED CARD IS NOT ON OFFER. Having just declined it, the
    # non-dealer may not change their mind, and the only move is a blind draw.
    is(kinds($d->legal('p2')), 'draw', 'and the only move is to draw');

    $d->apply('p2', { kind => 'draw' });
    is($d->upcard, $up, 'the refused card is still on the pile');
    is($d->hand_of('p2')->count, 11, 'and the hand is eleven from the stock');
};

subtest 'path four: what is refused in the first turn' => sub {
    plan tests => 3;
    my $d = fresh(4);
    my $e = $d->apply('p1', { kind => 'take' });
    is(ref $e, 'Game::Gin::Error', 'the dealer cannot move first');
    is($e->code, 'not_your_turn', 'and is told why');

    $d->apply('p2', { kind => 'pass' });
    $d->apply('p1', { kind => 'pass' });
    my $f = $d->apply('p2', { kind => 'take' });
    is($f->code, 'not_legal', 'and the refused upcard cannot be taken after all');
};

# ---- an ordinary turn ------------------------------------------------------------------------

subtest 'draw, discard, and the turn passes' => sub {
    plan tests => 6;
    my $d = fresh(5);
    $d->apply('p2', { kind => 'take' });
    my $card = $d->hand_of('p2')->cards->[0];
    $d->apply('p2', { kind => 'discard', card => $card });

    is($d->turn, 'p1', 'the turn passes');
    is($d->phase, 'draw', 'to a draw');
    is(kinds($d->legal('p1')), 'draw,take', 'from the stock or the pile');
    is($d->upcard, $card, 'and the discard is on top of the pile');

    my $before = $d->stock_left;
    $d->apply('p1', { kind => 'draw' });
    is($d->stock_left, $before - 1, 'a draw takes one from the stock');
    is($d->hand_of('p1')->count, 11, 'and gives it to the hand');
};

subtest 'you may not put back the card you just took' => sub {
    plan tests => 3;
    my $d = fresh(6);
    my $up = $d->upcard;
    $d->apply('p2', { kind => 'take' });

    my $e = $d->apply('p2', { kind => 'discard', card => $up });
    is(ref $e, 'Game::Gin::Error', 'refused');
    is($e->code, 'just_taken', 'by name');

    # And the rule is in `legal` as well as in `apply`, or a client would
    # offer a move the server then refuses.
    my $offered = grep { ($_->{card} // 0) == $up } @{ $d->legal('p2') };
    is($offered, 0, 'and it was never offered');
};

subtest 'a card you do not hold is refused' => sub {
    plan tests => 2;
    my $d = fresh(7);
    $d->apply('p2', { kind => 'take' });
    my %held = map { $_ => 1 } @{ $d->hand_of('p2')->cards };
    my ($not_held) = grep { !$held{$_} } 1 .. 52;

    my $e = $d->apply('p2', { kind => 'discard', card => $not_held });
    is(ref $e, 'Game::Gin::Error', 'refused');
    is($e->code, 'not_held', 'by name');
};

# ---- the seat off the clock -------------------------------------------------------------------

subtest 'the seat not on turn is offered nothing and refused everything' => sub {
    plan tests => 2;
    my $d = fresh(8);
    is_deeply($d->legal('p1'), [], 'nothing on offer');
    my $e = $d->apply('p1', { kind => 'draw' });
    is($e->code, 'not_your_turn', 'and nothing accepted');
};

done_testing();
