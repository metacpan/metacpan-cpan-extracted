use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use lib 't/lib';

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;
use Game::Xiangqi::Bot;

# ---- WRITTEN DOWN BEFORE THE RUN --------------------------------------------------
#
#   GAMES     a thousand, bot against bot, seeds derived from the index so the whole
#             run is reproducible and any single game can be replayed on its own.
#
#   RUNG      the BOTTOM rung for nine hundred of them and the top rung for a
#             hundred. Not one rung throughout, because game length is what this file
#             measures and a stronger engine plays a different length of game; not an
#             even split, because the top rung costs thirty times as much per move
#             and the measurement this feeds is the site's `limits`, which needs the
#             DISTRIBUTION rather than the best play.
#
#   PLY CAP   six hundred, which is CXQ's own moves cap (three hundred full moves) and
#             therefore not a cap at all: a game that reaches it has been ruled a draw
#             by the judge already. If any game is reported as capped, this file is
#             measuring the cap and the number is not a game length.
#
#   ASSERTED  zero invariant violations, zero refusals, zero croaks, and every game
#             ending. The distributions are REPORTED and not asserted: a threshold on
#             a mean game length is a threshold on the evaluation, which will change.
#
# THE MEASUREMENT THIS EXISTS FOR is the length of a game, because phase 12 writes
# the site's `limits` from it and Bulls and Cows chose its own numbers instead.

my $GAMES   = $ENV{XQ_SOAK_GAMES} || 1000;
my $PLY_CAP = 600;
my $TOP_EVERY = 10;              # every tenth game at the top rung

plan skip_all => 'set RELEASE_TESTING or XQ_SOAK to run the soak: it takes an hour'
    unless $ENV{RELEASE_TESTING} || $ENV{XQ_SOAK};

my $E = 'Game::Xiangqi::Engine';
my $N = 'Game::Xiangqi::Notation';
my $B = 'Game::Xiangqi::Bot';

# ---- the invariants ---------------------------------------------------------------
#
# Checked on EVERY position of EVERY game, not at the end. A board that briefly holds
# two pieces on one point and then tidies up is a board whose undo is wrong, and only
# a per-position check sees it.
sub violations {
    my ($pos) = @_;
    my @bad;
    my (%count, %general);

    for my $pt (map { $E->point_of($_ % 9, int($_ / 9)) } 0 .. 89) {
        my $p = $pos->at($pt);
        next unless $p && $p != EMPTY;
        $count{$pt}++;
        my ($kind, $colour) = (kind_of($p), colour_of($p));
        my $where = chr(97 + $E->file_of($pt)) . $E->rank_of($pt);

        if ($kind == GENERAL) {
            $general{$colour}++;
            push @bad, "a general off its palace at $where"
                unless $E->in_palace($pt, $colour);
        }
        if ($kind == ELEPHANT) {
            push @bad, "an elephant across the river at $where"
                if $E->crossed_river($pt, $colour);
        }
        if ($kind == ADVISOR) {
            push @bad, "an advisor off its palace at $where"
                unless $E->in_palace($pt, $colour);
        }
    }

    my $pieces = scalar keys %count;
    push @bad, "$pieces pieces on the board" if $pieces > 32;
    for my $c (RED, BLACK) {
        my $n = $general{$c} || 0;
        push @bad, sprintf('%s has %d generals', $c == RED ? 'red' : 'black', $n)
            if $n != 1;
    }
    return @bad;
}

# A SOLDIER NEVER MOVES BACKWARD, which is about a move and not a position, so it is
# checked against the move rather than the board.
#
# RETURNS @bad AND NOT A LIST LITERAL, to match `violations`. The first version ended
# `return ('a red soldier moved backward') if ...; return ();` which behaves
# differently in scalar context from its sibling: `return @bad` gives a COUNT, while
# `return ('string')` gives the string and `return ()` gives undef. So
# `scalar(backward(...))` read undef for "no violation" and a string for one, and the
# check that was meant to prove this function works failed on both halves. Same
# family of bug as a PPCODE XSUB in scalar context, in pure Perl.
sub backward {
    my ($pos, $mv) = @_;
    my @bad;
    my ($from, $to) = ($E->move_from($mv), $E->move_to($mv));
    my $p = $pos->at($from);
    return @bad unless $p && kind_of($p) == SOLDIER;
    my ($fr, $tr) = ($E->rank_of($from), $E->rank_of($to));
    push @bad, 'a red soldier moved backward'   if colour_of($p) == RED   && $tr < $fr;
    push @bad, 'a black soldier moved backward' if colour_of($p) == BLACK && $tr > $fr;
    return @bad;
}

diag(sprintf 'soaking %d games, ply cap %d, every %dth at the top rung',
     $GAMES, $PLY_CAP, $TOP_EVERY);

my (@lengths, %reason, %winner, @bad, $capped, $refusals, $croaks);
my ($total_ms, $worst_game_ms, $worst_game) = (0, 0, -1);
my $t_start = Time::HiRes::time();

for my $i (1 .. $GAMES) {
    my $budget = ($i % $TOP_EVERY == 0) ? $Game::Xiangqi::Bot::LADDER[-1]
                                        : $Game::Xiangqi::Bot::LADDER[0];
    my $seed = substr(sprintf('xq-soak-%08d', $i) . ('.' x 32), 0, 32);
    my $t0 = Time::HiRes::time();

    my $ok = eval {
        my $g = Game::Xiangqi->new(seed => $seed, red => ($i % 2 ? 'p1' : 'p2'));
        die "no game for seed $seed\n" unless $g;

        while ($g->status eq 'active' && @{ $g->log } < $PLY_CAP) {
            push @bad, map { "game $i ply " . scalar(@{ $g->log }) . ": $_" }
                       violations($g->position);

            my $seat = $g->turn;
            my $iccs = do { local $Game::Xiangqi::Bot::LEVEL = $budget;
                            $B->choose($g, $seat) };
            last unless defined $iccs;

            my $mv = $N->move_of_iccs($iccs);
            push @bad, map { "game $i: $_" } backward($g->position, $mv);

            my $refusal = $g->play($iccs);
            if ($refusal) {
                $refusals++;
                push @bad, "game $i: the bot offered $iccs and was refused: " . $refusal->code;
                last;
            }
        }

        push @bad, map { "game $i final: $_" } violations($g->position);
        $capped++ if $g->status eq 'active';
        push @lengths, scalar @{ $g->log };
        $reason{ $g->result->{reason} || 'capped' }++;
        $winner{ defined $g->result->{winner} ? 'decided' : 'drawn' }++;
        1;
    };
    if (!$ok) { $croaks++; push @bad, "game $i croaked: $@" }

    my $ms = (Time::HiRes::time() - $t0) * 1000;
    $total_ms += $ms;
    ($worst_game_ms, $worst_game) = ($ms, $i) if $ms > $worst_game_ms;

    diag(sprintf '  %d games, %.0f s elapsed', $i, Time::HiRes::time() - $t_start)
        if $i % 100 == 0;
}

sub _pct {
    my ($p, @sorted) = @_;
    return 0 unless @sorted;
    my $i = int($p * scalar(@sorted));
    $i = $#sorted if $i > $#sorted;
    return $sorted[$i];
}

my @sorted = sort { $a <=> $b } @lengths;
my $mean = @lengths ? eval { my $s = 0; $s += $_ for @lengths; $s / scalar @lengths } : 0;

subtest 'every game ended, and nothing was refused or croaked' => sub {
    is(scalar @lengths, $GAMES, "all $GAMES games ran to a conclusion");
    is($refusals || 0, 0, 'the bot never offered a move the facade refused');
    is($croaks   || 0, 0, 'and nothing croaked');
    is($capped   || 0, 0, "no game reached the $PLY_CAP ply cap")
        or diag('  a capped game means these lengths are measuring the cap');
};

subtest 'the invariants held on every position of every game' => sub {
    is(scalar @bad, 0, 'zero violations')
        or diag(join "\n", map { "  $_" } @bad[0 .. ($#bad > 19 ? 19 : $#bad)]);
};

subtest 'the invariant check is not vacuous' => sub {
    # PROVE IT. `put` judges nothing, so dropping a second general on the board must
    # make `violations` complain. Without this the subtest above passes on a check
    # that looks at nothing at all, which is the whole subject of
    # index_tests_that_lie.
    my $pos = $E->new;
    is(scalar(violations($pos)), 0, 'the opening is clean');

    my $two = $E->new;
    $two->put($E->point_of(4, 1), RED | GENERAL);
    cmp_ok(scalar(violations($two)), '>', 0, 'a second red general is caught');

    my $out = $E->new;
    $out->lift($E->point_of(4, 0));
    $out->put($E->point_of(0, 0), RED | GENERAL);
    cmp_ok(scalar(violations($out)), '>', 0, 'a general outside its palace is caught');

    my $swim = $E->new;
    $swim->put($E->point_of(2, 7), RED | ELEPHANT);
    cmp_ok(scalar(violations($swim)), '>', 0, 'a red elephant across the river is caught');

    # and the backward-soldier check
    my $back = $E->new;
    my $mv = $E->move($E->point_of(0, 3), $E->point_of(0, 2));
    cmp_ok(scalar(backward($back, $mv)), '>', 0, 'a red soldier stepping back is caught');
    my $fwd = $E->move($E->point_of(0, 3), $E->point_of(0, 4));
    is(scalar(backward($back, $fwd)), 0, '  and stepping forward is not');
};

# ---- THE MEASUREMENT, REPORTED AND NOT ASSERTED ----------------------------------
diag('---- the length of a game, which phase 12 writes `limits` from ----');
diag(sprintf 'games %d   mean %.1f plies   median %d   p95 %d   longest %d   shortest %d',
     scalar @lengths, $mean, _pct(0.50, @sorted), _pct(0.95, @sorted),
     $sorted[-1], $sorted[0]);
diag(sprintf 'wall clock %.0f s total, %.0f ms a game, worst game %.0f ms (game %d)',
     (Time::HiRes::time() - $t_start), $total_ms / ($GAMES || 1), $worst_game_ms, $worst_game);
diag('endings: ' . join(', ', map { "$_ $reason{$_}" } sort keys %reason));
diag('decided ' . ($winner{decided} || 0) . ', drawn ' . ($winner{drawn} || 0));

subtest 'the ending distribution is not degenerate' => sub {
    # NOT a threshold on any one reason, which would be a threshold on the
    # evaluation. What is asserted is that the game is not stuck in one groove: if
    # every game of a thousand ends the same way, the bot is playing one game a
    # thousand times and the soak measures nothing. plan_order_and_chaos measured a
    # 39.5% draw rate that was entirely a missing seat in the tie-break seed.
    cmp_ok(scalar keys %reason, '>=', 3, 'at least three different endings occur');
    my ($most) = sort { $reason{$b} <=> $reason{$a} } keys %reason;
    cmp_ok($reason{$most} / $GAMES, '<', 0.95,
           "no single ending is more than 95% of games (worst: $most)");
    cmp_ok(($winner{decided} || 0), '>', 0, 'some games are decided');
};

done_testing();
