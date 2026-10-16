use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

use Game::Sternhalma;
use Game::Sternhalma::Bot;

# WHAT A MOVE COSTS, REPORTED AND NOT ASSERTED. A rung is a budget of positions
# looked at, never of seconds, so the moves are the same on every machine and
# only this file's numbers change. On the build box, 15 Oct 2026, rung 3 took
# about 36 ms a move.

for my $seats (2, 4) {
    my $g = Game::Sternhalma->new(seats => $seats);
    $g->play(Game::Sternhalma::Bot->choose($g, rung => 1, seed => 3)) for 1 .. 4 * $seats;
    for my $rung (0 .. 3) {
        my ($t0, $n) = (time, 0);
        my $nodes = 0;
        for (1 .. 5) {
            my $t = Game::Sternhalma::Bot->think($g, rung => $rung, seed => $_);
            $nodes += $t->{nodes};
            $n++;
        }
        my $ms = 1000 * (time - $t0) / $n;
        diag sprintf "%d seats, rung %d: %.1f ms a move, %d positions a move", $seats, $rung, $ms, $nodes / $n;
        pass("$seats seats, rung $rung timed");
    }
}

done_testing();
