#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();
use Time::HiRes ();

use Game::Backgammon;
use Game::Backgammon::Board;
use Game::Backgammon::Bot;

sub seed_of { Digest::SHA::sha256($_[0]) }

sub play_out {
    my (%o) = @_;
    my $g = Game::Backgammon->new(seed => seed_of($o{seed}));
    my %bot = (white => Game::Backgammon::Bot->new(level => $o{white} // 3),
               black => Game::Backgammon::Bot->new(level => $o{black} // 3));
    my $i = 0;
    while ($g->status eq 'active' && $i++ < 4000) {
        my $turn = $bot{ $g->turn }->choose($g) or last;
        $g->play($turn) or last;
    }
    return $g;
}

# ---- it plays ---------------------------------------------------------------------

subtest 'the bot always offers a turn the rules accept' => sub {
    plan tests => 3;
    my $g = play_out(seed => 'plays');
    is($g->status, 'finished', 'a bot against a bot finishes a game');
    is($g->board->off($g->result->winner), 15, 'the winner bore off fifteen');
    is_deeply([ $g->board->consistent ], [], 'and the position is still sound');
};

subtest 'it never returns a turn that was not offered' => sub {
    plan tests => 1;
    my $bot = Game::Backgammon::Bot->new(level => 3);
    my $g = Game::Backgammon->new(seed => seed_of('offered'));
    my $bad = 0;
    for (1 .. 40) {
        last if $g->status ne 'active';
        my %legal = map { $_->key => 1 } @{ $g->legal_turns };
        my $turn = $bot->choose($g) or last;
        $bad++ unless $legal{ $turn->key };
        $g->play($turn) or last;
    }
    is($bad, 0, 'every turn it chose was one of the legal ones');
};

# ---- determinism ------------------------------------------------------------------

subtest 'the same seed and level give the same game, twice' => sub {
    plan tests => 3;
    my $a = play_out(seed => 'repro');
    my $b = play_out(seed => 'repro');
    is_deeply($a->to_log, $b->to_log, 'the same turns, in the same order');
    is_deeply($a->board->points, $b->board->points, 'the same final board');
    is($a->result->margin, $b->result->margin, 'and the same margin');
};

subtest 'ties break on the turn, not on enumeration order' => sub {
    plan tests => 1;
    # choose() is called twice on the SAME position: nothing about the
    # generator's order may leak into the answer
    my $g = Game::Backgammon->new(seed => seed_of('ties'));
    my $bot = Game::Backgammon::Bot->new(level => 3);
    is($bot->choose($g)->key, $bot->choose($g)->key, 'the same position gives the same turn');
};

# ---- the levels are really different ----------------------------------------------

subtest 'level 3 beats level 1 over a run' => sub {
    plan tests => 1;
    # The plan asked for 100 games on the assumption the edge would be
    # narrow. Measured, it is not: level 3 wins about 95%, so forty games
    # with a bound at 60% is far outside anything chance will produce and
    # costs a fifth of the time. Backgammon is dice, so the bound is loose
    # on purpose; a tight one would be a flaky test about a game decided by
    # a die.
    my $games = 40;
    my $won = 0;
    for my $n (1 .. $games) {
        my $g = play_out(seed => "match-$n", white => 3, black => 1);
        $won++ if $g->result && $g->result->winner eq 'white';
    }
    cmp_ok($won, '>=', $games * 0.6,
           "level 3 won $won of $games against level 1");
};

subtest 'the levels know different things' => sub {
    plan tests => 3;
    my $three = Game::Backgammon::Bot->new(level => 3);
    my $two   = Game::Backgammon::Bot->new(level => 2);
    my $one   = Game::Backgammon::Bot->new(level => 1);

    ok($three->knows_blots && $three->knows_shape, 'level 3 knows everything');
    ok(!$two->knows_blots && $two->knows_shape, 'level 2 knows shape but not blots');
    ok(!$one->knows_blots && !$one->knows_shape, 'level 1 counts pips and nothing else');
};

# ---- the evaluation says what it should --------------------------------------------

subtest 'blot exposure counts the worst shot, and counts it right' => sub {
    plan tests => 4;
    my $bot = Game::Backgammon::Bot->new(level => 3);

    my $pos = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    $pos->set_point('white', 10, 1);         # a white blot on the 10 point
    $pos->set_point('white', 1, 14);
    $pos->set_point('black', 21, 15);        # black's 21 is white's 4, six behind
    is_deeply([ $pos->consistent ], [], 'the fixture is a legal position');
    is($bot->blot_exposure($pos, 'white'), 17,
       'a blot six in front of a checker is 17 shots');

    my $safe = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    $safe->set_point('white', 10, 2);        # two checkers: not a blot
    $safe->set_point('white', 1, 13);
    $safe->set_point('black', 21, 15);
    is($bot->blot_exposure($safe, 'white'), 0, 'two checkers are not exposed at all');

    # seven away is six shots, which is the difference the pip count cannot see
    my $further = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    $further->set_point('white', 11, 1);
    $further->set_point('white', 1, 14);
    $further->set_point('black', 21, 15);    # white's 4, seven behind the blot
    is($bot->blot_exposure($further, 'white'), 6, 'and seven away is only 6');
};

subtest 'a prime is worth more than the points that make it' => sub {
    plan tests => 2;
    my $bot = Game::Backgammon::Bot->new(level => 3);

    my $scattered = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    $scattered->set_point('white', $_, 2) for 3, 7, 11, 15;
    $scattered->set_point('white', 1, 7);
    $scattered->set_point('black', 2, 15);

    my $primed = Game::Backgammon::Board->new(points => [ (0) x 24 ]);
    $primed->set_point('white', $_, 2) for 4, 5, 6, 7;
    $primed->set_point('white', 1, 7);
    $primed->set_point('black', 2, 15);

    is_deeply([ $primed->consistent ], [], 'the fixture is legal');
    cmp_ok($bot->score($primed, 'white'), '>', $bot->score($scattered, 'white'),
           'four points in a row beat four points scattered');
};

# ---- the budget --------------------------------------------------------------------

subtest 'the worst case is bounded, and small' => sub {
    plan tests => 2;
    # The bot runs inside a database transaction on the site, so this is a
    # constraint rather than a curiosity: the number below is what that
    # transaction has to allow for, and a change that makes it much worse is
    # a change that needs discussing.
    my $bot = Game::Backgammon::Bot->new(level => 3);
    my ($most, $slowest) = (0, 0);

    for my $n (1 .. 6) {
        my $g = Game::Backgammon->new(seed => seed_of("budget-$n"));
        my $i = 0;
        while ($g->status eq 'active' && $i++ < 4000) {
            my $count = scalar @{ $g->legal_turns };
            my $t0 = Time::HiRes::time();
            my $turn = $bot->choose($g) or last;
            my $ms = (Time::HiRes::time() - $t0) * 1000;
            $most = $count if $count > $most;
            $slowest = $ms if $ms > $slowest;
            $g->play($turn) or last;
        }
    }

    # measured at 206 turns and about 40 ms on a double 1 in a crowded
    # position; the bounds are generous so a slower machine does not fail
    cmp_ok($most, '<', 600, "the most legal turns seen was $most");
    cmp_ok($slowest, '<', 2000, sprintf('the slowest choice was %.0f ms', $slowest));
};

done_testing();
