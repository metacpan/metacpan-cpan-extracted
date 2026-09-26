use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# ---- THE NUMBERS, WRITTEN DOWN BEFORE THE RUN ------------------------------------
#
# All four of these were fixed before a single game was played, and none of them is
# to be adjusted afterwards to make a rung pass. That is the whole discipline of
# this file: A RUNG THAT DOES NOT BEAT THE ONE BELOW IS DELETED, NOT EXPLAINED.
#
#   GAMES     sixty per pair, colours alternated, so each rung plays thirty as Red
#             and thirty as Black. Xiangqi gives Red the move and Red is held to
#             score better than even, so a ladder run from one colour would measure
#             the first move rather than the rung.
#
#   THRESHOLD sixty percent, counting a win as one and a draw as a half. The
#             honest arithmetic: the standard deviation of a sixty-game score
#             between two equal players is sqrt(60 * 0.25) / 60, which is 6.45
#             percent, so sixty percent is 1.55 deviations out and a pair of
#             identical engines would clear it about six times in a hundred. That
#             is not a tight test and this comment is here so nobody reads it as
#             one. The reason it is not tighter is wall clock: the pairs below
#             already take the better part of an hour, and the run is quadratic in
#             the number of games only through the judge. A rung that clears by a
#             hair is reported with `diag` so a human can look at it.
#
#   PLY CAP   two hundred plies, after which the game is scored a draw. This is a
#             DEVIATION from the rules the dist implements and it is here for one
#             measured reason: CXQ's own moves cap is three hundred full moves,
#             which is six hundred plies, and the judge costs 204 ms at ply 300
#             (t/18's own measurement of the search, by comparison, is 264 ms at
#             the top rung). A soak that ran to the real cap would spend its whole
#             afternoon in the judge. Games that hit this cap are counted and
#             reported: if that number is large the ladder is measuring the cap.
#
#   RUNGS     the DISTINCT budgets in @LADDER, in order, each against the one
#             below. @LADDER repeats a rung on purpose, because the site's bag
#             draws one per game and a doubled entry makes that opponent twice as
#             likely; a repeat is not a rung to test.

my $GAMES     = 60;
my $THRESHOLD = 0.60;
my $PLY_CAP   = 200;

use Game::Xiangqi;
use Game::Xiangqi::Bot;

plan skip_all => 'set RELEASE_TESTING or XQ_LADDER to play the ladder: it takes the better part of an hour'
    unless $ENV{RELEASE_TESTING} || $ENV{XQ_LADDER};

my $B = 'Game::Xiangqi::Bot';

# One game. `$budget` is keyed by SEAT, so the two seats really are two different
# opponents: the tie-break seed is mixed from the game seed and the seat inside
# `choose`, which is the bug Game::Goofspiel shipped and this file would not see.
sub play_one {
    my ($seed, $budget) = @_;
    my $g = Game::Xiangqi->new(seed => $seed, red => 'p1');
    my %ms = (search => 0, play => 0);

    while ($g->status eq 'active' && @{ $g->log } < $PLY_CAP) {
        my $seat = $g->turn;

        my $t0 = Time::HiRes::time();
        my $mv = do { local $Game::Xiangqi::Bot::LEVEL = $budget->{$seat};
                      $B->choose($g, $seat) };
        $ms{search} += Time::HiRes::time() - $t0;
        return { error => "no move for $seat" } unless $mv;

        my $t1 = Time::HiRes::time();
        my $refusal = $g->play($mv);
        $ms{play} += Time::HiRes::time() - $t1;

        # A BOT THAT OFFERS AN ILLEGAL MOVE IS A FAILED LADDER, not a lost game.
        # The search and the facade share one generator, so this can only fire if
        # the search's own legality test has drifted from `gen_legal`'s.
        return { error => "$seat offered $mv and was refused: " . $refusal->code } if $refusal;
    }

    return {
        plies   => scalar @{ $g->log },
        capped  => ($g->status eq 'active' ? 1 : 0),
        winner  => $g->result->{winner},
        reason  => $g->result->{reason},
        rule    => $g->result->{rule},
        ms      => \%ms,
    };
}

my @rungs = do { my %s; grep { !$s{$_}++ } @Game::Xiangqi::Bot::LADDER };
diag(sprintf 'the distinct rungs are %s, so %d pairs of %d games',
     join(', ', @rungs), $#rungs, $GAMES);

for my $r (1 .. $#rungs) {
    my ($weak, $strong) = @rungs[$r - 1, $r];

    subtest "rung $strong against rung $weak" => sub {
        my ($score, $wins, $draws, $losses, $capped) = (0, 0, 0, 0, 0);
        my (%reason, $search_ms, $play_ms, $plies);

        for my $i (1 .. $GAMES) {
            # colours alternated: the strong rung is Red on the odd games
            my $strong_seat = ($i % 2) ? 'p1' : 'p2';
            my $weak_seat   = ($i % 2) ? 'p2' : 'p1';
            my %budget = ($strong_seat => $strong, $weak_seat => $weak);

            my $seed = sprintf 'xq-ladder-%06d-%06d-%04d', $strong, $weak, $i;
            $seed = substr($seed . ('.' x 32), 0, 32);

            my $out = play_one($seed, \%budget);
            if ($out->{error}) {
                fail("game $i: $out->{error}");
                next;
            }

            $search_ms += $out->{ms}{search} * 1000;
            $play_ms   += $out->{ms}{play} * 1000;
            $plies     += $out->{plies};
            $capped++ if $out->{capped};
            $reason{ $out->{reason} // 'capped' }++;

            if (!defined $out->{winner})              { $score += 0.5; $draws++ }
            elsif ($out->{winner} eq $strong_seat)    { $score += 1;   $wins++ }
            else                                      {                $losses++ }
        }

        my $rate = $score / $GAMES;
        diag(sprintf '%d v %d: %.1f/%d = %.1f%% (%dW %dD %dL), %d capped at %d plies',
             $strong, $weak, $score, $GAMES, $rate * 100, $wins, $draws, $losses,
             $capped, $PLY_CAP);
        diag(sprintf '  mean game: %.0f plies, %.0f ms searching, %.0f ms judging',
             $plies / $GAMES, $search_ms / $GAMES, $play_ms / $GAMES);
        diag('  endings: ' . join(', ', map { "$_ $reason{$_}" } sort keys %reason));

        cmp_ok($rate, '>', $THRESHOLD,
               sprintf 'rung %d beats rung %d, %.1f%% against the %.0f%% written down first',
               $strong, $weak, $rate * 100, $THRESHOLD * 100);

        diag('  THIS CLEARED BY A HAIR. Look at it before believing it.')
            if $rate > $THRESHOLD && $rate < $THRESHOLD + 0.05;
    };
}

done_testing();
