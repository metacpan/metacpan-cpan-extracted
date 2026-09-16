#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Digest::SHA ();

use Game::Gin;
use Game::Gin::Bot;
use Game::Gin::Search qw(LEVELS);

sub seed { return Digest::SHA::sha256("bot:$_[0]") }

sub play {
    my (%o) = @_;
    my $g = Game::Gin->build(seed => seed($o{n}), dealer => $o{dealer} || 'p1');
    my %bot = (p1 => Game::Gin::Bot->new(level => $o{p1} || 2),
               p2 => Game::Gin::Bot->new(level => $o{p2} || 2));
    # Separately, not `my (@log, $moves) = ((), 0)`: a list assignment gives
    # the array everything and the scalar undef.
    my @log;
    my $moves = 0;
    while (!$g->over && $moves < 8000) {
        my $seat = $g->turn or last;
        my $move = $bot{$seat}->choose($g, $seat) or last;
        push @log, "$seat:$move->{kind}:" . ($move->{card} // '-') . ($move->{knock} ? 'K' : '');
        my @out = $g->apply($seat, $move);
        return ($g, \@log, $moves, $out[0]) if ref $out[0] eq 'Game::Gin::Error';
        $moves++;
    }
    return ($g, \@log, $moves, undef);
}

# ---- it plays, and it plays legally ----------------------------------------------------

subtest 'a bot plays a match out without being refused' => sub {
    plan tests => 4;
    my ($g, $log, $moves, $err) = play(n => 1);
    is($err, undef, 'no move was ever refused');
    ok($g->over, "the match finished in $moves moves");
    ok($g->result->{winner}, 'with a winner');
    cmp_ok(scalar @$log, '>', 50, 'after a real number of moves');
};

subtest 'a bot is offered nothing when it is not its turn' => sub {
    plan tests => 2;
    my $g = Game::Gin->build(seed => seed(2), dealer => 'p1');
    my $bot = Game::Gin::Bot->new(level => 2);
    is($bot->choose($g, 'p1'), undef, 'the dealer has nothing to do on the first turn');
    ok($bot->choose($g, 'p2'), 'and the non-dealer does');
};

# ---- deterministic, which is what makes a bot game replayable ----------------------------

subtest 'the same seed and the same levels play the same game' => sub {
    plan tests => 2;
    my (undef, $a) = play(n => 3);
    my (undef, $b) = play(n => 3);
    is_deeply($a, $b, 'move for move');

    my (undef, $c) = play(n => 4);
    isnt(join('|', @$a), join('|', @$c), 'and a different seed plays differently');
};

subtest 'two bots in one game do not play the same moves' => sub {
    plan tests => 2;
    # Goofspiel shipped bots that reached the same conclusion from the same
    # public position and tied every round, finishing 0-0 for ever. Here the
    # hands differ, so the moves must differ; this is the assertion that says
    # so rather than assuming it.
    my ($g, $log) = play(n => 5);
    my @p1 = grep { /^p1:/ } @$log;
    my @p2 = grep { /^p2:/ } @$log;
    cmp_ok(scalar @p1, '>', 10, 'both seats moved plenty');
    isnt(join('|', map { s/^p1://r } @p1), join('|', map { s/^p2://r } @p2),
         'and they did not make the same moves as each other');
};

# ---- the ladder, MEASURED --------------------------------------------------------------------

subtest 'a higher level beats a lower one' => sub {
    my $N = $ENV{GIN_LADDER} || 40;
    plan tests => 3;

    my ($won, $done, $moves, $deals) = (0, 0, 0, 0);
    my $started = Time::HiRes::time();
    for my $n (1 .. $N) {
        my ($g, undef, $m) = play(n => "ladder$n", p1 => 2, p2 => 1);
        next unless $g->over;
        $done++; $moves += $m; $deals += scalar @{ $g->hands };
        $won++ if $g->result->{winner} eq 'p1';
    }
    my $took = Time::HiRes::time() - $started;

    is($done, $N, "$done matches finished");
    cmp_ok($done, '>', 20, 'which is enough to mean anything at all');

    # MEASURED AND RECORDED, not asserted at a threshold that pretends to a
    # precision this sample does not have. Over 300 matches level 2 beats
    # level 1 by 56%, which is a real edge and a modest one. The assertion
    # here is only wide enough to catch a level 2 that has become broken.
    my $rate = 100 * $won / $done;
    cmp_ok($rate, '>', 35, sprintf('level 2 wins %.0f%% of %d (300-match figure: 56%%)', $rate, $done));

    diag(sprintf('ladder: L2 beat L1 %d-%d (%.0f%%), avg %.0f moves and %.1f deals, %.1fs',
                 $won, $done - $won, $rate, $moves / $done, $deals / $done, $took));
};

# ---- how long a match is, which the overview took a decision about -----------------------------

subtest 'the length of a match, recorded' => sub {
    plan tests => 2;
    my ($moves, $deals, $done) = (0, 0, 0);
    for my $n (1 .. 12) {
        my ($g, undef, $m) = play(n => "len$n", p1 => 2, p2 => 2);
        next unless $g->over;
        $done++; $moves += $m; $deals += scalar @{ $g->hands };
    }
    is($done, 12, 'twelve matches finished');
    my $per_player = $moves / $done / 2;
    cmp_ok($per_player, '>', 20, sprintf('a match is %.0f moves a player over %.1f deals',
                                         $per_player, $deals / $done));

    # This is the number the overview's time-control decision rests on, so it
    # is printed on every run rather than buried in a gate nobody runs.
    diag(sprintf('LENGTH: %.0f moves a match, %.0f a player, %.1f deals. At 3d a move that is %.0f days.',
                 $moves / $done, $per_player, $deals / $done, $per_player * 3));
};

subtest 'the number of levels is what the dist says it is' => sub {
    plan tests => 2;
    is(LEVELS, 2, 'two levels');
    # A level above the top is not an error, it is the top: the site clamps
    # rather than refusing, and this keeps that safe.
    my ($g) = play(n => 6, p1 => 9, p2 => 1);
    ok($g->over, 'a level above the top still plays a match out');
};

done_testing();
