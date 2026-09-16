#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin::Card qw(id_of name_of);
use Game::Gin::Hand ();
use Game::Gin::Deal ();

sub h { return [ map { id_of($_) } @_ ] }

# When the stock runs down, the hand is CANCELLED: nobody scores, and the deal
# passes. Not a win, not a draw worth points, nothing.
#
# The threshold is two cards. It is a boundary, so it is tested either side of
# itself rather than only at it.

sub rigged {
    my (%o) = @_;
    return Game::Gin::Deal->new(
        seed    => "\0" x 32,
        number  => 1,
        dealer  => 'p1',
        hands   => { p1 => Game::Gin::Hand->new(cards => h(@{ $o{p1} })),
                     p2 => Game::Gin::Hand->new(cards => h(@{ $o{p2} })) },
        stock   => h(@{ $o{stock} }),
        discard => h(qw(KD)),
        turn    => 'p1',
        phase   => 'discard',
        taken   => 0,
        result  => undef,
    );
}

# Hands that cannot knock, so the only way out is the stock.
my @P1 = qw(AS 3S 5S 7S 9H JH KC 2C 4C 6D 8D);
my @P2 = qw(2H 4H 6H 8S TC QC KH 3D 5D 7D);

subtest 'three cards left: play goes on' => sub {
    plan tests => 3;
    my $d = rigged(p1 => \@P1, p2 => \@P2, stock => [qw(2D 3C 4D)]);
    $d->apply('p1', { kind => 'discard', card => id_of('KC') });
    ok(!$d->over, 'the hand continues');
    is($d->turn, 'p2', 'and the turn passes');
    is($d->stock_left, 3, 'with three still in the stock');
};

subtest 'two cards left: the hand is cancelled' => sub {
    plan tests => 5;
    my $d = rigged(p1 => \@P1, p2 => \@P2, stock => [qw(2D 3C)]);
    my @out = $d->apply('p1', { kind => 'discard', card => id_of('KC') });

    ok($d->over, 'the hand is over');
    is($out[-1]{kind}, 'cancelled', 'and says so in the outcomes');
    is($d->result->{kind}, 'cancelled', 'the result is a cancellation');
    is($d->result->{winner}, undef, 'nobody won it');
    is($d->result->{points}, 0, 'and nobody scored');
};

subtest 'a knock still settles the hand at two cards' => sub {
    plan tests => 2;
    # The cancellation is checked only when a discard was NOT a knock. A
    # player who can go out on the last possible turn does go out, and the
    # order of those two checks is the whole of this subtest.
    my $d = rigged(
        p1    => [qw(AS 2S 3S 4S 5H 6H 7H 8D 9D TD KC)],
        p2    => [qw(2C 4C 6D 8H TH QS KD 3H 5C 7C)],
        stock => [qw(2D 3C)],
    );
    $d->apply('p1', { kind => 'discard', card => id_of('KC'), knock => 1 });
    isnt($d->result->{kind}, 'cancelled', 'the knock wins over the cancellation');
    is($d->result->{winner}, 'p1', 'and the knocker takes the hand');
};

subtest 'an empty stock cannot be drawn from' => sub {
    plan tests => 2;
    my $d = Game::Gin::Deal->new(
        seed => "\0" x 32, number => 1, dealer => 'p1',
        hands => { p1 => Game::Gin::Hand->new(cards => h(@P2)),
                   p2 => Game::Gin::Hand->new(cards => h(@P2)) },
        stock => [], discard => h(qw(KD)),
        turn => 'p1', phase => 'draw', taken => 0, result => undef,
    );
    my $e = $d->apply('p1', { kind => 'draw' });
    is(ref $e, 'Game::Gin::Error', 'refused rather than returning undef');
    is($e->code, 'not_legal', 'by name');
};

done_testing();
