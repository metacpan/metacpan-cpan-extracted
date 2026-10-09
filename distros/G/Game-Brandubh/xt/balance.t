#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256);

use Game::Brandubh;
use Game::Brandubh::Bot;

# A SHORT CUT OF THE SIDE-BALANCE MEASUREMENT: the middle level against itself.
#
# IT ASSERTS THAT THE GAMES ARE PLAYED, AND REPORTS WHO WON THEM. It does not
# assert a balance. How often each side wins between two copies of this program
# is a measurement, kept with the plan this distribution was built from; a test
# that failed when the number moved would be a test of the program's opinion of
# the game.
#
#     BRANDUBH_BALANCE_GAMES=200 prove -b xt/balance.t

my $GAMES = $ENV{BRANDUBH_BALANCE_GAMES} || 60;
my $level = (Game::Brandubh::Bot->levels)[1];
my (%winner, %how, $plies);

for my $i (1 .. $GAMES) {
    my $seed = sha256("xt/balance.t game $i");
    my $g = Game::Brandubh->new(seed => $seed, attackers => ($i % 2 ? 'p2' : 'p1'));
    my $guard = 0;
    while ($g->status eq 'active') {
        $g->play_or_die(Game::Brandubh::Bot->choose($g, seed => $seed, level => $level));
        die "game $i did not end" if ++$guard > 500;
    }
    my $r = $g->result;
    $winner{ $r->winner // 'draw' }++;
    $how{ $r->how }++;
    $plies += $r->ply;
}

my $played = 0;
$played += $_ for values %winner;
is($played, $GAMES, "$GAMES games at level $level, each to its end");
cmp_ok($plies / $GAMES, '>', 4, sprintf('a mean of %.0f moves a game', $plies / $GAMES));

my ($att_wins, $def_wins) = map { $winner{$_} // 0 } qw(attackers defenders);
diag(sprintf('attackers %d, defenders %d, drawn %d; the attackers took %s of the decisive games',
    $att_wins, $def_wins, $winner{draw} // 0,
    ($att_wins + $def_wins ? sprintf('%.0f%%', 100 * $att_wins / ($att_wins + $def_wins)) : 'none')));
diag('ended by: ' . join(', ', map { "$_ $how{$_}" } sort keys %how));

done_testing();
