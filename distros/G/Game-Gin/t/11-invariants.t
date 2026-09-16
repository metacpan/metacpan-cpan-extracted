#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin;
use Game::Gin::Bot;
use Game::Gin::Card qw(CARDS name_of);

# Gin rummy has no perft: no published count of positions that either matches
# or does not. So the weight is carried by invariants, asserted after EVERY
# turn of every game rather than at the end of it.
#
# Fifty-two cards exist. They are in exactly one of four places: a hand, the
# stock, the discard pile, or nowhere because the deal has not happened. A
# game that breaks that is wrong however plausible its score reads, and it is
# the kind of wrong that shows up as a player holding a card their opponent is
# also holding, twenty moves after the bug.

sub seed { return Digest::SHA::sha256("inv:$_[0]") }

# Everything the deal can see, counted once.
sub census {
    my ($deal) = @_;
    my %seen;
    $seen{$_}++ for @{ $deal->hand_of('p1')->cards };
    $seen{$_}++ for @{ $deal->hand_of('p2')->cards };
    $seen{$_}++ for @{ $deal->stock };
    $seen{$_}++ for @{ $deal->discard };
    return \%seen;
}

sub check {
    my ($deal, $where) = @_;
    my $seen = census($deal);
    my @problems;

    my $total = 0;
    $total += $_ for values %$seen;
    push @problems, "$where: $total cards accounted for, not " . CARDS if $total != CARDS;

    my @twice = grep { $seen->{$_} > 1 } sort { $a <=> $b } keys %$seen;
    push @problems, "$where: in two places at once: " . join(' ', map { name_of($_) } @twice)
        if @twice;

    my @missing = grep { !$seen->{$_} } 1 .. CARDS;
    push @problems, "$where: missing " . join(' ', map { name_of($_) } @missing) if @missing;

    # A hand is ten cards, or eleven between a draw and the discard that
    # follows it. Any other number means a draw or a discard went astray.
    for my $seat (qw(p1 p2)) {
        my $n = $deal->hand_of($seat)->count;
        push @problems, "$where: $seat holds $n cards" if $n < 10 || $n > 11;
    }

    # The stock only ever shrinks.
    return @problems;
}

subtest 'the deck is conserved through whole bot games' => sub {
    my $GAMES = $ENV{GIN_INVARIANTS} || 60;
    plan tests => 5;

    # Declared one at a time. `my ($games, $turns, @problems, $grew, $deals)`
    # gives @problems everything after $turns and leaves the two scalars
    # undef, and `is(undef, 0)` then fails while the code under test is
    # perfectly correct. That cost a debugging session in t/10-bot.t already.
    my $games = 0;
    my $turns = 0;
    my $deals = 0;
    my $grew  = 0;
    my @problems;
    for my $n (1 .. $GAMES) {
        my $g = Game::Gin->build(seed => seed($n), dealer => $n % 2 ? 'p1' : 'p2');
        my %bot = (p1 => Game::Gin::Bot->new(level => 2),
                   p2 => Game::Gin::Bot->new(level => ($n % 3 ? 2 : 1)));
        $games++;

        push @problems, check($g->deal, "game $n, before a move") if @problems < 5;
        my ($moves, $stock) = (0, $g->deal->stock_left);

        while (!$g->over && $moves < 8000) {
            my $seat = $g->turn or last;
            my $number = $g->number;
            my $move = $bot{$seat}->choose($g, $seat) or last;
            my @out = $g->apply($seat, $move);
            die "refused: " . $out[0]->code if ref $out[0] eq 'Game::Gin::Error';
            $moves++; $turns++;

            last if $g->over;

            # A new deal resets everything, so the stock check restarts with it.
            if ($g->number != $number) { $stock = $g->deal->stock_left; $deals++; next }

            $grew++ if $g->deal->stock_left > $stock;
            $stock = $g->deal->stock_left;

            push @problems, check($g->deal, "game $n move $moves") if @problems < 5;
        }
    }

    # The counts first and separately. A sweep whose loop never ran conserves
    # the deck perfectly by never looking at it.
    is($games, $GAMES, "$games games were played");
    cmp_ok($turns, '>', 3000, "$turns turns were examined, which is enough to mean something");
    cmp_ok($deals, '>', 100, "$deals deals were dealt");
    is($grew, 0, 'the stock never grew');
    is_deeply(\@problems, [], 'and the deck was whole after every single turn')
        or diag(join "\n", @problems);
};

subtest 'a fresh deal is laid out correctly' => sub {
    plan tests => 4;
    my $g = Game::Gin->build(seed => seed('fresh'), dealer => 'p1');
    my $d = $g->deal;
    is($d->hand_of('p1')->count + $d->hand_of('p2')->count, 20, 'twenty cards dealt');
    is(scalar @{ $d->discard }, 1, 'one upcard');
    is($d->stock_left, CARDS - 21, 'and the rest in the stock');
    is_deeply([ check($d, 'fresh') ], [], 'with the deck whole');
};

done_testing();
