use strict;
use warnings;
use Test::More;

use Game::Shogi;
use Game::Shogi::Bot;

# A regression check on phase 08's ladder, not a measurement: a few games a
# pair, where 08 played 2,000 (plan_game_shogi/measured-08/). Rung 1 scored
# 95.6% against rung 0 and rung 2 96.5% against rung 1, so 9 of 12 failing by
# chance is under one run in a hundred. Rung 3 is left out: a game at 300,000
# nodes a move takes about twenty seconds.

my @LADDER = @Game::Shogi::Bot::LADDER;
my $GAMES  = 12;

sub play_one {
    my ($strong, $weak, $strong_side, $seed) = @_;
    my $g = Game::Shogi->new;
    while ($g->status eq 'active') {
        my $side = $g->turn;
        if (Game::Shogi::Bot->declares($g, $side)) { $g->declare; last }
        my $nodes = $side eq $strong_side ? $strong : $weak;
        my $mv = Game::Shogi::Bot->choose($g, $side, seed => $seed, nodes => $nodes);
        last unless defined $mv;
        my $refusal = $g->play($mv);
        die "the bot offered $mv and the game refused it: " . $refusal->code . "\n" if $refusal;
    }
    my $w = $g->winner;
    return !defined $w ? 0.5 : $w eq $strong_side ? 1 : 0;
}

for my $rung (1, 2) {
    my ($strong, $weak) = @LADDER[ $rung, $rung - 1 ];
    my $score = 0;
    $score += play_one($strong, $weak, $_ % 2 ? 'w' : 'b', "ladder-$rung-$_") for 1 .. $GAMES;
    cmp_ok($score, '>=', 9, "rung $rung ($strong nodes) beats rung " . ($rung - 1) . " ($weak): $score of $GAMES, each side half the games");
}

done_testing;
