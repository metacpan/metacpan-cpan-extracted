use strict;
use warnings;
use Test::More;

use Game::Brandubh;
use Game::Brandubh::Bot;
use Digest::SHA qw(sha256);
my $G = 'Game::Brandubh';
my $B = 'Game::Brandubh::Bot';

sub seed_of { sha256("t/21-bot.t seed $_[0]") }

# plays a whole game between two callers of the bot and returns it
sub play_out {
    my (%with) = @_;
    my %bot = (attackers => $with{att} || {}, defenders => $with{def} || {});
    my $g = $G->new(attackers => $with{seat} // 'p1', seed => $with{seed}, variant => { ply_cap => 160 });
    my $guard = 0;
    while ($g->status eq 'active') {
        my $move = $B->choose($g, seed => $with{seed}, %{ $bot{ $g->side_to_move } });
        my $refused = $g->play($move);
        die "the bot's own move $move was refused: " . $refused->code if $refused;
        die 'a game that will not end' if ++$guard > 400;
    }
    return $g;
}

subtest 'the ladder' => sub {
    is_deeply([ $B->levels ], [ 1_000, 10_000, 100_000 ], 'three levels, weakest first');
    is(scalar(@Game::Brandubh::Bot::LADDER), 4, 'and four rungs: the middle one is drawn twice as often');
    is($B->slip_for(1_000), 20, 'the weakest slips one move in five');
    is($B->slip_for(10_000), 0, 'the middle one never');
    is($B->slip_for(100_000), 0, 'nor the strongest');
    is($B->slip_for(12_345), 0, 'a level that is not on the ladder has no slip');
    is($B->slip_for(undef), 0, 'nor has no level');
    is($G->new->bot, $B, 'the game knows the class that plays it');
};

subtest 'the level a seed draws' => sub {
    my %drawn;
    $drawn{ $B->level_for(seed_of($_)) }++ for 1 .. 1000;
    is(join(' ', sort { $a <=> $b } keys %drawn), '1000 10000 100000', 'a thousand seeds draw all three levels and no other');
    cmp_ok($drawn{1_000},   '>', 200, "the weakest $drawn{1000} times in a thousand, about a quarter");
    cmp_ok($drawn{1_000},   '<', 300, 'and not much more');
    cmp_ok($drawn{10_000},  '>', 440, "the middle $drawn{10000} times, about half");
    cmp_ok($drawn{10_000},  '<', 560, 'and not much more');
    cmp_ok($drawn{100_000}, '>', 200, "the strongest $drawn{100000} times, about a quarter");
    cmp_ok($drawn{100_000}, '<', 300, 'and not much more');

    is($B->level_for(seed_of(7)), $B->level_for(seed_of(7)), 'the same seed draws the same level');
    is($B->level_for(undef), 10_000, 'no seed draws the middle of the ladder');
};

subtest 'think shows the working, and choose is its move' => sub {
    my $g = $G->new;
    my $thought = $B->think($g, seed => seed_of(1), level => 10_000);
    is_deeply([ sort keys %$thought ], [qw(depth level move nodes score slipped)], 'six things');
    is($thought->{level}, 10_000, 'the level it was told');
    is($thought->{slipped}, 0, 'no slip at this level');
    cmp_ok($thought->{depth}, '>=', 2, "it looked $thought->{depth} moves ahead");
    like($thought->{nodes}, qr/\A[0-9]+\z/, 'at a cost in nodes');
    ok((grep { $_->{move} eq $thought->{move} } @{ $g->legal }), 'and its move is legal');
    is($B->choose($g, seed => seed_of(1), level => 10_000), $thought->{move}, 'choose returns that move');
    is($g->ply, 0, 'neither changed the game');
};

# A LEVEL IS A BUDGET, and the budget is what is spent. If every level searched
# as much as the strongest, the ladder would be three names for one player.
subtest 'each level spends what it is called' => sub {
    my $g = $G->new;
    my %nodes = map { $_ => $B->think($g, seed => seed_of(2), level => $_, slip => 0)->{nodes} } $B->levels;
    cmp_ok($nodes{1_000}, '<=', 1_000 + 1024, "the weakest looked at $nodes{1000} positions");
    cmp_ok($nodes{10_000}, '<=', 10_000 + 1024, "the middle at $nodes{10000}");
    cmp_ok($nodes{10_000}, '>', $nodes{1_000}, 'which is more');
    cmp_ok($nodes{100_000}, '<=', 100_000 + 1024, "the strongest at $nodes{100000}");
    cmp_ok($nodes{100_000}, '>', 5 * $nodes{10_000}, 'which is several times more again');
};

subtest 'the level: given, pinned, or drawn' => sub {
    my $g = $G->new;
    my $seed = seed_of(3);
    is($B->think($g, seed => $seed)->{level}, $B->level_for($seed), 'with nothing said, the level the seed draws');
    {
        local $Game::Brandubh::Bot::LEVEL = 100_000;
        is($B->think($g, seed => $seed)->{level}, 100_000, '$LEVEL pins it');
        is($B->think($g, seed => $seed, level => 1_000, slip => 0)->{level}, 1_000, 'and a level given outranks the pin');
    }
    is($B->think($g, seed => $seed)->{level}, $B->level_for($seed), 'the pin is gone with its scope');
    ok(!eval { $B->choose($g, level => 'hard'); 1 }, 'a level in words croaks');
    ok(!eval { $B->choose($g, level => 0); 1 }, 'so does a level of nothing');
};

subtest 'the slip' => sub {
    my $g = $G->new;
    my ($slipped, $legal, %moves) = (0, 0);
    for my $i (1 .. 60) {
        my $thought = $B->think($g, seed => seed_of($i), level => 1_000, slip => 100);
        $slipped++ if $thought->{slipped};
        $legal++ if grep { $_->{move} eq $thought->{move} } @{ $g->legal };
        $moves{ $thought->{move} }++;
    }
    is($slipped, 60, 'at a slip of a hundred every move is a slip');
    is($legal, 60, 'and every one of them legal');
    cmp_ok(scalar(keys %moves), '>', 15, 'and they are all over the board: ' . scalar(keys %moves) . ' different moves from sixty seeds');

    $slipped = grep { $B->think($g, seed => seed_of($_), level => 1_000, slip => 0)->{slipped} } 1 .. 60;
    is($slipped, 0, 'at a slip of nothing, none');

    $slipped = grep { $B->think($g, seed => seed_of($_), level => 1_000)->{slipped} } 1 .. 400;
    cmp_ok($slipped, '>', 50, "at the weakest level's own figure, $slipped of four hundred: about one in five");
    cmp_ok($slipped, '<', 115, 'and not much more');
};

# hint must be the STRONGEST level's move, so it is asked in positions where
# the weakest level and the strongest disagree: in a position where every level
# plays the same move, a hint that used the wrong level would look right.
subtest 'hint is the strongest level, and never slips' => sub {
    my $seed = seed_of(9);
    my (@disagree, $looked);
    my $g = $G->new(seed => $seed, variant => { ply_cap => 200 });
    while ($g->status eq 'active' && @disagree < 3 && $looked++ < 80) {
        my $weak   = $B->choose($g, seed => $seed, level => 1_000, slip => 0);
        my $strong = $B->choose($g, seed => $seed, level => 100_000, slip => 0);
        push @disagree, [ $g->as_text, $strong, $weak ] if $weak ne $strong;
        $g->play_or_die($weak);
    }
    is(scalar(@disagree), 3, 'three positions where the weakest and the strongest level choose differently');
    for my $case (@disagree) {
        my ($text, $strong, $weak) = @$case;
        my $at = $G->from_text($text, seed => $seed);
        is($B->hint($at, seed => $seed), $strong, "the hint is the strongest level's move, $strong and not $weak");
        local $Game::Brandubh::Bot::LEVEL = 1_000;
        is($B->hint($at, seed => $seed, slip => 100), $strong, 'whatever the pin says and whatever slip is asked for');
        is($B->hint($at, seed => $seed, level => 1_000), $strong, 'and whatever level it is handed');
    }
};

# The salt is what makes two programs at one table, or one program in two
# games, choose differently among moves it scores alike.
subtest 'the facade\'s search: the salt decides among equals, and nothing else does' => sub {
    my $g = $G->new;
    my (%by_salt, $differ, $positions);
    for (1 .. 40) {
        last unless $g->status eq 'active';
        my $x = $g->search(budget => 5_000_000, depth => 2, salt => 'one');
        my $y = $g->search(budget => 5_000_000, depth => 2, salt => 'two');
        my $again = $g->search(budget => 5_000_000, depth => 2, salt => 'one');
        $positions++;
        $differ++ if $x->{move} ne $y->{move};
        $by_salt{same}++ if $again->{move} eq $x->{move};
        $by_salt{score}++ if $x->{score} == $y->{score};
        $g->play_or_die($x->{move});
    }
    cmp_ok($positions, '>=', 10, "$positions positions");
    is($by_salt{same}, $positions, 'the same salt gives the same move every time');
    is($by_salt{score}, $positions, 'two salts give the same score every time');
    cmp_ok($differ // 0, '>', 0, 'and in ' . ($differ // 0) . ' of them a different move of that score');
    ok(!eval { $g->search(budget => 100, salt => []); 1 }, 'a salt that is not a string croaks');
};

# EVERY LEVEL, FROM BOTH SIDES AND BOTH SEATS, plays a whole game in legal
# moves. The die inside play_out is the assertion; what is counted here is that
# the games happened and ended.
subtest 'every level plays a whole game from both sides' => sub {
    my ($games, %how) = (0);
    for my $level ($B->levels) {
        for my $case ([ 'p1', { level => $level }, { level => 1_000 } ],
                      [ 'p2', { level => $level }, { level => 1_000 } ],
                      [ 'p1', { level => 1_000 }, { level => $level } ],
                      [ 'p2', { level => 1_000 }, { level => $level } ]) {
            my ($seat, $att, $def) = @$case;
            my $g = play_out(seed => seed_of("$level $seat $att->{level}"), seat => $seat, att => $att, def => $def);
            $games++;
            $how{ $g->result->how }++;
            is($g->status, 'finished',
                "level $att->{level} attacking level $def->{level}, attackers at $seat: ended by " . $g->result->how);
        }
    }
    is($games, 12, 'twelve games, every move of them accepted');
};

subtest 'a game against the bot can be played again' => sub {
    my $seed = seed_of('again');
    my $one = play_out(seed => $seed);
    my $two = play_out(seed => $seed);
    is("@{ $two->log }", "@{ $one->log }", 'the same seed plays the same game, move for move');
    is($two->result->how, $one->result->how, 'to the same end');

    my $other = play_out(seed => seed_of('another'));
    isnt("@{ $other->log }", "@{ $one->log }", 'and another seed plays another');
};

subtest 'two bots at one table do not mirror each other' => sub {
    my $seed = seed_of('table');
    my $g = $G->new(seed => $seed);
    my $attackers = $B->think($g, seed => $seed, level => 10_000);
    $g->play_or_die($attackers->{move});
    my $defenders = $B->think($g, seed => $seed, level => 10_000);
    ok($defenders->{move}, 'the second seat, given the same seed, has a move of its own');
    is($g->play($defenders->{move}), 0, 'which is legal for its side');
};

subtest 'when there is nothing to choose' => sub {
    my $g = $G->new(position => '7/7/7/k6/7/7/3a3 d');
    $g->play_or_die('a4a1');
    is($B->choose($g), undef, 'a finished game: undef');
    is($B->think($g), undef, 'from think too');
    is($B->hint($g), undef, 'and from hint');
    ok(!eval { $B->choose('a game'); 1 }, 'something that is not a game croaks');
    ok(!eval { $B->choose(undef); 1 }, 'and so does nothing');
};

# A TEST DOUBLE COMPOSES THE BOT; IT DOES NOT SUBCLASS IT. With the classes of
# this distribution a subclass would be handed back a parent object and its
# override would never run, so a bot that cheats on purpose, written as a
# subclass, would pass every check as the honest bot. This one holds a bot.
{
    package Local::FirstMove;
    sub new { my ($class) = @_; return bless { asked => 0, inner => 'Game::Brandubh::Bot' }, $class }
    sub choose {
        my ($self, $game, %with) = @_;
        $self->{asked}++;
        return undef unless $game->status eq 'active';
        return $game->legal->[0]{move};
    }
    sub inner { $_[0]{inner} }
    sub asked { $_[0]{asked} }
}

subtest 'a double that composes the bot is the one that runs' => sub {
    my $double = Local::FirstMove->new;
    my $seed = seed_of('double');
    my $g = $G->new(seed => $seed, variant => { ply_cap => 120 });
    my $turns = 0;
    while ($g->status eq 'active') {
        my $move = $g->side_to_move eq 'attackers' ? $double->choose($g)
                                                    : $double->inner->choose($g, seed => $seed, level => 10_000);
        $g->play_or_die($move);
        $turns++ if $g->side_to_move && $g->side_to_move eq 'defenders';
    }
    cmp_ok($double->asked, '>', 0, 'the double was asked ' . $double->asked . ' times');
    is(ref $double, 'Local::FirstMove', 'and is still the double: not a parent in its place');
    is($g->result->winner, 'defenders', 'a player who takes the first move offered loses to the middle level');
};

done_testing();
