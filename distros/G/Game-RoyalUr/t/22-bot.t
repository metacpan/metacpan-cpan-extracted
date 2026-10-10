use strict;
use warnings;
use Test::More;

use Game::RoyalUr;
use Game::RoyalUr::Bot;
use Game::RoyalUr::Engine ();
my $B = 'Game::RoyalUr::Bot';
my $G = 'Game::RoyalUr';

sub at_roll {
    my ($position, $roll, $rules) = @_;
    return $G->new(script => [ { roll => $roll } ], position => $position, (defined $rules ? (rules => $rules) : ()));
}

subtest 'the ladders' => sub {
    for my $rules ('finkel', 'masters') {
        my @levels = $B->levels($rules);
        cmp_ok(scalar @levels, '>=', 3, "$rules has " . scalar(@levels) . ' levels');
        is_deeply(\@levels, [ 1 .. scalar @levels ], "$rules: numbered from 1 with none missing");
        is_deeply($B->rung(1, $rules), { greedy => 1 }, "$rules: level 1 does not look ahead");
        my $depth = 0;
        for my $level (@levels[ 1 .. $#levels ]) {
            my $rung = $B->rung($level, $rules);
            ok(!$rung->{greedy}, "$rules: level $level looks ahead");
            cmp_ok($rung->{depth}, '>', $depth, "$rules: level $level looks further than the level below, to depth $rung->{depth}");
            $depth = $rung->{depth};
            ok($rung->{weights}{exposed}, "$rules: and counts what an exposed piece stands to lose");
        }
        ok(!eval { $B->rung(0, $rules); 1 }, "$rules: there is no level 0");
        ok(!eval { $B->rung(@levels + 1, $rules); 1 }, "$rules: nor one past the top");
    }
    ok(!$B->rung(2, 'masters')->{weights}{rosette}, 'under masters no level values holding a rosette: it is not safe there');
    ok($B->rung(2, 'finkel')->{weights}{rosette}, 'under finkel they do');

    my $rung = $B->rung(2, 'finkel');
    $rung->{weights}{exposed} = 0;
    $rung->{depth} = 9;
    is($B->rung(2, 'finkel')->{weights}{exposed}, 16, 'a rung handed out is a copy, weights and all');
    is_deeply([ $B->levels({ route => 'long', safe_rosettes => 1 }) ], [ $B->levels('masters') ],
        'a rule set with no name has the ladder of its route');
    is_deeply([ $B->levels(undef) ], [ $B->levels('finkel') ], 'and no rule set is finkel');
};

subtest 'a bot is a level and a budget' => sub {
    is($B->new->level, undef, 'no level is the top');
    is($B->new->budget, 1_000_000, 'and a million positions a search');
    is($B->new->level_for('finkel'), scalar(() = $B->levels('finkel')), 'which is the top of the game\'s ladder');
    is($B->new(level => 2)->level_for('masters'), 2, 'a level is that level');
    is($B->new(level => 99)->level_for('masters'), scalar(() = $B->levels('masters')), 'and one above the ladder is its top');
    ok(!eval { $B->new(level => $_); 1 }, "level '$_' croaks") for 0, -1, 'top', 1.5;
    ok(!eval { $B->new(budget => $_); 1 }, "budget '$_' croaks") for 0, -5, 'lots', 3_000_000_000;
};

# Level 1 is three preferences in order, each from a position written for it.
subtest 'level 1, without looking ahead' => sub {
    my $bot = $B->new(level => 1);
    my $capture = at_roll('4xx2/l1d3l1/2l1xx2 l 4 0 6 0', 2);
    is(join(' ', map { $_->from . '-' . $_->to } $capture->legal), 'c1-a1 a2-c2 g2-h1', 'a rosette, a capture and a plain move on offer');
    is($bot->choose($capture)->to, 'c2', 'the capture is taken');

    my $rosette = at_roll('4xx2/l5l1/2l1xx2 l 4 0 7 0', 2);
    is($bot->choose($rosette)->to, 'a1', 'with no capture, the rosette');

    my $neither = at_roll('4xx2/l5l1/4xx2 l 5 0 7 0', 1);
    is($bot->choose($neither)->from, 'g2', 'with neither, the piece furthest along');

    my $thought = $bot->think($neither);
    is($thought->{depth}, 0, 'and it says it did not look ahead');
    is($thought->{value}, undef, 'so it has no value to give');
    is($thought->{level}, 1, 'at level 1');
};

subtest 'a level that looks ahead sees what level 1 does not' => sub {
    my $game = at_roll('d3xx2/l5l1/4xx2 l 0 5 6 0', 4);
    is($B->new(level => 1)->choose($game)->from, 'g2', 'level 1 takes g2 home and leaves a2 to be captured');
    for my $level (grep { $_ > 1 } $B->levels('finkel')) {
        my $thought = $B->new(level => $level)->think($game);
        is($thought->{move}->from, 'a2', "level $level moves a2 out of reach");
        cmp_ok($thought->{depth}, '>=', 1, "level $level looked $thought->{depth} deep, at $thought->{nodes} positions");
    }
};

subtest 'what choose answers is one of the game\'s own moves' => sub {
    for my $rules ('finkel', 'masters') {
        my ($choices, @bad) = (0);
        for my $n (1 .. 12) {
            my $game = $G->new(seed => "bot $rules $n", rules => $rules);
            my @bots = map { $B->new(level => $_) } $B->levels($rules);
            my $turn = 0;
            until ($game->is_over || $turn >= 40) {
                my @legal = $game->legal;
                for my $bot (@bots) {
                    my $move = $bot->choose($game);
                    $choices++;
                    push @bad, "level " . $bot->level . " answered something that is not on offer"
                        unless grep { $_->from eq $move->from && $_->to eq $move->to && $_->roll == $move->roll } @legal;
                }
                $game->play($bots[ $turn++ % @bots ]->choose($game)) or push @bad, 'a chosen move was refused: ' . $game->error->code;
            }
        }
        is(scalar @bad, 0, "$rules: $choices choices, every level, every one a legal move") or diag(join "\n", @bad[0 .. ($#bad > 4 ? 4 : $#bad)]);
    }
};

subtest 'choosing changes nothing, and is the same choice twice' => sub {
    my $game = $G->new(seed => 'bot twice', first => 'light');
    $game->play(($game->legal)[0]) for 1 .. 9;
    my $before = join ' | ', $game->position, $game->roll, $game->rolls, $game->ply;
    for my $level ($B->levels('finkel')) {
        my $bot = $B->new(level => $level);
        my $one = $bot->think($game);
        my $two = $bot->think($game);
        is($two->{index}, $one->{index}, "level $level: the same move asked twice");
        is($two->{nodes}, $one->{nodes}, "level $level: at the same cost");
    }
    is(join(' | ', $game->position, $game->roll, $game->rolls, $game->ply), $before, 'and the game is as it was');
};

subtest 'a finished game, and a budget that is too small' => sub {
    my $game = $G->new(seed => 'bot over', first => 'light');
    $game->resign;
    is($B->new->choose($game), undef, 'there is nothing to choose in a finished game');
    is($B->new->think($game), undef, 'and nothing to think');

    my $busy = at_roll('2d1xx2/l1dl1l2/1l2xx2 l 3 0 4 1', 1);
    my $top = $B->new(budget => 10);
    my $thought = $top->think($busy);
    ok($thought->{move}, 'a bot with ten positions to spend still answers');
    is($thought->{depth}, 1, 'from one level');
    ok($thought->{stopped}, 'and says it was cut short');
};

subtest 'two bots finish a game' => sub {
    for my $rules ('finkel', 'masters') {
        my $game = $G->new(seed => "bots finish $rules", rules => $rules);
        my %bot = (light => $B->new(level => 2), dark => $B->new(level => 1));
        my $turns = 0;
        until ($game->is_over) {
            $game->play_or_die($bot{ $game->side }->choose($game));
            die 'this game is not ending' if ++$turns > 3_000;
        }
        is($game->result->how, 'home', "$rules: a game between level 2 and level 1 ends with a side home, in " . $game->ply . ' plies');
    }
};

done_testing();
