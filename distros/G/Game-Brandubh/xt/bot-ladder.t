#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256);

use Game::Brandubh;
use Game::Brandubh::Bot;

# EACH LEVEL AGAINST THE ONE BELOW, FROM BOTH SIDES. A level that only beat the
# one below it as the defenders would be showing that the defenders win, not
# that it is stronger, so every pairing is played both ways round and the two
# are added.
#
# An author test, and slow: it plays whole games at the strongest level.
#
#     BRANDUBH_LADDER_GAMES=40 prove -b xt/bot-ladder.t
#
# The bar is 3 sigma above an even split of the decisive games, which at the
# default of 40 games a pairing a side is about three games in four.

my $GAMES = $ENV{BRANDUBH_LADDER_GAMES} || 40;
my @levels = Game::Brandubh::Bot->levels;

sub play {
    my ($i, $att, $def) = @_;
    my $seed = sha256("xt/bot-ladder.t game $i $att $def");
    my $g = Game::Brandubh->new(seed => $seed, attackers => ($i % 2 ? 'p2' : 'p1'));
    while ($g->status eq 'active') {
        my $level = $g->side_to_move eq 'attackers' ? $att : $def;
        $g->play_or_die(Game::Brandubh::Bot->choose($g, seed => $seed, level => $level));
    }
    return $g->result->winner // 'draw';
}

for my $k (1 .. $#levels) {
    my ($strong, $weak) = ($levels[$k], $levels[ $k - 1 ]);
    my ($wins, $losses, $draws) = (0, 0, 0);
    for my $i (1 .. $GAMES) {
        my $as_attackers = play($i, $strong, $weak);
        my $as_defenders = play($i, $weak, $strong);
        $as_attackers eq 'attackers' ? $wins++ : $as_attackers eq 'draw' ? $draws++ : $losses++;
        $as_defenders eq 'defenders' ? $wins++ : $as_defenders eq 'draw' ? $draws++ : $losses++;
    }
    my $decisive = $wins + $losses;
    my $sigma = $decisive ? ($wins / $decisive - 0.5) / (0.5 / sqrt($decisive)) : 0;
    diag(sprintf('level %d against level %d: won %d, lost %d, drew %d; %+.1f sigma', $strong, $weak, $wins, $losses, $draws, $sigma));
    cmp_ok($sigma, '>=', 3, "level $strong beats level $weak by at least 3 sigma over both sides");
}

done_testing();
