use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona;
use Game::Fanorona::Engine ':all';
use Game::Fanorona::Rules ();
use Game::Fanorona::Notation qw(format_move);
use FnSolve qw(solve);
my $G = 'Game::Fanorona';
my $R = 'Game::Fanorona::Rules';
my $E = 'Game::Fanorona::Engine';
my $WIN = $R->win_score;

sub game { $G->new(position => $_[0], ($_[1] ? (variant => $_[1]) : ())) }

subtest 'a win that is there to be taken' => sub {
    #  3  w . b       one step and the last stone is gone
    my $found = game('9/9/w1b6/9/9 w')->search(budget => 1);
    is($found->{move}, 'a3-b3A', 'a3-b3 takes the last stone, and a budget of one position finds it');
    cmp_ok($found->{score}, '>', $WIN - 1000, 'and scores it as a win seen to its end');
    is($found->{depth}, 1, 'in one move');

    # A WHOLE MOVE COMES BACK, not its first step: the stone must go on to c3
    #  4  . . b . .
    #  2  . w . b .
    my $chain = game('9/2b6/9/1w1b5/9 w')->search(budget => 200);
    is($chain->{move}, 'b2-c2A-c3A', 'a chain of two that takes everything is returned whole');
    is_deeply([ map { $_->{string} } @{ $chain->{steps} } ], [ 'b2-c2A', 'c2-c3A' ], 'as its two steps');
    is($chain->{stop}, 0, 'with no stop needed after them');
    cmp_ok($chain->{score}, '>', $WIN - 1000, 'and it is a win');

    # A WIN SOONER IS WORTH MORE THAN A WIN LATER: one step away against two
    is($found->{score}, $WIN - 1, 'a win one step away scores one less than a win');
    is($chain->{score}, $WIN - 2, 'and a win two steps away, two less');
};

subtest 'from the middle of a move' => sub {
    my $g = game('9/2b6/9/1w1b5/9 w');
    $g->step('b2-c2A');
    my $found = $g->search(budget => 200);
    is($found->{move}, 'c2-c3A', 'asked in the middle of a chain, the search answers the rest of the move');
    cmp_ok($found->{score}, '>', $WIN - 1000, 'which here wins');
    is($found->{stop}, 0, 'and needs no stop after it');
};

# WHEN THE THING TO DO IS STOP. Found by asking the solved tables for a move
# in which taking once and stopping is strictly better than going on. One
# white stone against three:
#
#   3  . . w b . .      White has two first steps. c3-b3 is a withdrawal from
#   2  . . . . . .      d3, and going on to b2 then takes b1: that wins. But
#   1  b b . . . .      c3-b2 is an approach that takes a1, and from b2 the
#                       stone can go on north to b3, away from b1, and take
#                       that too. Do that and Black's last stone wins the
#                       ending. Stop on b2 and the game is a draw.
subtest 'when the thing to do is stop' => sub {
    my $off = { board => 'sivy', quiet_limit => 0, repeat => 0 };
    my $position = '9/9/2wb5/9/bb7 w';
    my ($value, $next) = solve(\&format_move, $position);
    my %after = map { $_->[0] => ($value->{ $_->[1] } // 'D') } @{ $next->{$position} };
    is_deeply(\%after, { 'c3-b2A' => 'D', 'c3-b2A-b3W' => 'W', 'c3-b3W' => $after{'c3-b3W'}, 'c3-b3W-b2A' => 'L' },
        'the table: of four moves, c3-b3W-b2A wins, c3-b2A and stop draws, and c3-b2A-b3W loses');

    my $g = $G->new(position => $position, variant => $off);
    is($g->search(budget => 3000)->{move}, 'c3-b3W-b2A', 'asked from the start, the search plays the move that wins');

    $g->step('c3-b2A');
    ok($g->can_stop, 'with the other first step made by hand, the move is open: the stone could go on to b3');
    is_deeply([ map { $_->{string} } $g->steps ], [ 'b2-b3W' ], 'and b2-b3 is the one step on offer');
    my $rest = $g->search(budget => 3000);
    is($rest->{move}, '', 'the search answers with no step');
    is_deeply($rest->{steps}, [], 'none at all');
    is($rest->{stop}, 1, 'and a stop: taking the second stone would lose the game');
    cmp_ok(abs($rest->{score}), '<', 100, "which it scores as neither side a stone up ($rest->{score}): one stone each will be left");
};

# THE SOLVED TABLES AS A JUDGE OF THE SEARCH. For every arrangement of two and
# three stones the value by force is known (t/12-tables.t). So the search can
# be asked for a move in a position that is WON and its move looked up: if the
# position it leaves is not lost for the other side, the search has thrown a
# win away. With 3,000 positions to look at it should never turn a win into a
# loss, and should keep nearly every win.
sub positions_of {
    my ($white, $black) = @_;
    my $bd = $E->new(empty => 1);
    my @all = $bd->all_squares;
    my (@out, $place);
    $place = sub {
        my ($from, $left, $stone, $then) = @_;
        if (!$left) { $then->(); return }
        for my $i ($from .. $#all) {
            next if $bd->at($all[$i]) != EMPTY;
            $bd->put($all[$i], $stone);
            $place->($i + 1, $left - 1, $stone, $then);
            $bd->lift($all[$i]);
        }
    };
    $place->(0, $white, WHITE, sub { $place->(0, $black, BLACK, sub { push @out, $bd->to_string }) });
    return @out;
}

for my $case ([ 1, 1, 3, 'one stone against one' ], [ 2, 1, 37, 'two against one' ], [ 1, 2, 37, 'one against two' ]) {
    my ($mine, $theirs, $every, $name) = @$case;
    subtest "the search against the table: $name" => sub {
        my @start = positions_of($mine, $theirs);
        my ($value, $next) = solve(\&format_move, @start);
        my ($n, %tally, @thrown) = (0);
        for my $position (@start) {
            next if $n++ % $every;
            my $v = $value->{$position} // 'D';
            next if $v eq 'L';
            my $game = $R->new(position => $position, variant => { quiet_limit => 0, repeat => 0 });
            next if $game->over;
            my $found = $game->search(budget => 3000);
            my $move = format_move({ from => $found->{steps}[0]{from}, steps => $found->{steps} });
            my ($after) = map { $_->[1] } grep { $_->[0] eq $move } @{ $next->{$position} };
            if (!defined $after) { push @thrown, "$position: $move is not a move of the position"; next }
            my $then = $value->{$after} // 'D';
            if ($v eq 'W') {
                $tally{won}++;
                $tally{kept}++ if $then eq 'L';
                push @thrown, "$position: $move turns a win into a loss" if $then eq 'W';
            }
            else {
                $tally{drawn}++;
                $tally{held}++ if $then ne 'W';
            }
        }
        is(scalar(@thrown), 0, 'no win is turned into a loss, and every move is a move')
            or diag join "\n", @thrown[0 .. ($#thrown < 3 ? $#thrown : 3)];
        if ($tally{won}) {
            cmp_ok($tally{won}, '>=', 20, "$tally{won} won positions asked about");
            cmp_ok($tally{kept} / $tally{won}, '>=', 0.98, sprintf('%d of them kept won: %.1f%%', $tally{kept}, 100 * $tally{kept} / $tally{won}));
        }
        if ($tally{drawn}) {
            cmp_ok($tally{held} / $tally{drawn}, '>=', 0.98, sprintf('%d of %d drawn positions held: %.1f%%', $tally{held}, $tally{drawn}, 100 * $tally{held} / $tally{drawn}));
        }
    };
}

# A GUESS IS NOT A PROOF. At the end of its depth the search plays the largest
# captures out in one line, and where two are as large it takes the first. In
# this position that line ends with White winning and the other capture ends
# with Black winning. The search once reported the first as a win seen to its
# end, stopped looking, and played f3-g3, which loses.
subtest 'an ending met while settling is not a win that has been proved' => sub {
    my $g = $R->new(position => '9/7bw/5w3/9/9 w', variant => { quiet_limit => 0, repeat => 0 });
    my $shallow = $g->search(budget => 1);
    cmp_ok($shallow->{score}, '<', $WIN - 1000, 'one iteration does not claim a proved win');
    my $found = $g->search(budget => 3000);
    my $move = format_move({ from => $found->{steps}[0]{from}, steps => $found->{steps} });
    isnt($move, 'f3-g3', 'with room to look, it does not play f3-g3');
    my ($value, $next) = solve(\&format_move, $g->position);
    my ($after) = map { $_->[1] } grep { $_->[0] eq $move } @{ $next->{ $g->position } };
    is($value->{$after}, 'L', "and $move leaves Black lost, which is what the table says White can do");
    is($value->{ (map { $_->[1] } grep { $_->[0] eq 'f3-g3' } @{ $next->{ $g->position } })[0] }, 'W', 'where f3-g3 leaves Black winning');
};

# A STONE LEFT TO BE TAKEN IS NOT SCORED AS IF IT WERE SAFE. Found by asking
# the engine for a quiet position in which the move that looks best at a
# glance leaves a stone to be taken:
#
#   5  . . . b . . . . .      a1-b2 moves towards the middle and has more room
#   3  . b . . w . . . .      there than anywhere else it could go. And Black's
#   1  w . . . . . . . .      b3 then steps away to b4 and takes it.
#
# Looking ONE move ahead, the search must still not play it: at the end of its
# depth it plays out the captures before it scores.
subtest 'looking one move ahead, a stone is not left to be taken' => sub {
    my $position = '3b5/9/1b2w4/9/w8 w';
    my $g = $G->new(position => $position);
    my %static = map { $_ => $G->new(position => $g->preview($_))->evaluate } $g->legal_strings;
    my ($looks_best) = sort { $static{$b} <=> $static{$a} } keys %static;
    is($looks_best, 'a1-b2', 'at a glance a1-b2 is the best of White\'s moves');
    cmp_ok($static{'a1-b2'}, '>', $static{'a1-a2'}, "scored $static{'a1-b2'} where a1-a2 is $static{'a1-a2'}");
    ok((grep { /[AW]/ } $G->new(position => $g->preview('a1-b2'))->legal_strings), 'and after it Black has a stone to take');
    ok(!(grep { /[AW]/ } $G->new(position => $g->preview('a1-a2'))->legal_strings), 'where after a1-a2 Black has none');

    my $found = $g->search(budget => 100_000, depth => 1);
    is($found->{depth}, 1, 'asked to look one move ahead');
    is($found->{move}, 'a1-a2', 'the search plays a1-a2');
    cmp_ok($found->{score}, '<', $static{'a1-b2'}, 'and does not believe the glance');
};

# THE SETTLING TAKES THE MOST IT CAN. In this position White is going to lose a
# stone whatever it does: b4 can step away from a4 and take it. But after some
# of White's moves Black can take THREE in one move, and after others only that
# one. A search that settled a position by its smallest capture would see every
# move as costing one stone and choose among them by where the stones stand.
subtest 'the settling counts the largest capture, not the smallest' => sub {
    my $g = $G->new(position => '6w2/wb1b3w1/5b2w/4b4/1b7 w');
    my %most;
    for my $move ($g->legal_strings) {
        my $after = $G->new(position => $g->preview($move));
        my ($largest) = sort { $b <=> $a } map { scalar($_->taken) } $after->legal;
        $most{$move} = $largest;
    }
    is($most{'h4-h3'}, 3, 'after h4-h3 Black can take three stones in one move');
    is($most{'i3-h3'}, 3, 'and after i3-h3');
    is($most{'i3-h2'}, 1, 'after i3-h2, one');
    my ($least) = sort { $a <=> $b } values %most;
    is($least, 1, 'and one is the least White can lose');

    my $found = $g->search(budget => 1_000_000, depth => 1);
    is($most{ $found->{move} }, 1, "looking one move ahead the search plays $found->{move}, after which Black takes one");
    isnt($found->{move}, 'h4-h3', 'and not h4-h3');
};

# A WON POSITION IS WON BY PLAYING IT, not only by choosing one good move. A
# search that preferred no win to any other could sit in a won position for
# ever; a win sooner must score higher than a win later.
subtest 'a won position is played out to the win' => sub {
    my $off = { board => 'sivy', quiet_limit => 0, repeat => 0 };
    # THE LAST OF THESE NEEDS THE BIGGER BUDGET, AND THAT IS A FINDING. Two
    # stones against one at opposite ends of the board is won by the table, and
    # a search of 3,000 positions on each side does not win it in eighty moves:
    # it has no plan for closing the distance, only a horizon. At 30,000 it
    # wins in twenty-three.
    for my $case ([ '9/7bw/5w3/9/9 w', 3000 ], [ '9/9/2wb5/9/bb7 w', 3000 ], [ '9/9/w3b4/9/4w4 w', 3000 ], [ '8b/9/9/9/ww7 w', 30_000 ]) {
        my ($position, $budget) = @$case;
        my $g = $G->new(position => $position, variant => $off);
        my ($value) = solve(undef, $position);
        next unless is($value->{$position}, 'W', "$position is won for White by the table");
        my $n = 0;
        until ($g->over || $n++ >= 60) {
            my $found = $g->search(budget => $budget);
            length $found->{move} ? $g->play($found->{move}) : $g->stop;
        }
        ok($g->over, "played by a search of $budget positions on both sides, it ends") or next;
        is($g->winner, 'white', 'and White wins it, in ' . $g->ply . ' moves');
    }
};

# A DRAWN GAME IS WORTH NOTHING TO EITHER SIDE. White is a stone up, and the
# game is capped at one move: whatever White plays, the game is drawn there.
# So the position is worth exactly nothing to White, stone or no stone.
subtest 'a draw is scored as level' => sub {
    my $g = $R->new(position => '8b/9/9/9/ww7 w', variant => { ply_cap => 1, quiet_limit => 0, repeat => 0 });
    cmp_ok($g->evaluate, '>', 50, 'at a glance White is a stone up');
    my $found = $g->search(budget => 10_000);
    is($found->{score}, 0, 'and looking ahead, every move ends in a draw: the score is 0');
    my $black = $R->new(position => '8b/9/9/9/ww7 b', variant => { ply_cap => 1, quiet_limit => 0, repeat => 0 });
    is($black->search(budget => 10_000)->{score}, 0, 'and 0 for Black to move, who is the stone down');
};

subtest 'the same question has the same answer' => sub {
    my $g = $G->new(script => [ 'd3-e3A', 'c3-d3W' ]);
    my @again = map { $g->search(budget => 2000, seed => 7) } 1 .. 3;
    is($again[1]{move}, $again[0]{move}, 'the same position, budget and seed give the same move');
    is($again[2]{move}, $again[0]{move}, 'a third time');
    is_deeply([ map { "$_->{nodes},$_->{depth},$_->{score}" } @again ], [ ("$again[0]{nodes},$again[0]{depth},$again[0]{score}") x 3 ],
        'and the same count, depth and score');

    # THE SEED SETTLES TIES AND NOTHING ELSE: to a fixed depth, every seed
    # finds the same score, whatever move it settles on
    my %score;
    my %move;
    for my $seed (1 .. 12) {
        my $found = $G->new->search(budget => 1_000_000, depth => 2, seed => $seed);
        $score{ $found->{score} }++;
        $move{ $found->{move} }++;
    }
    is(scalar(keys %score), 1, 'twelve seeds, to a depth of two, find one score');
    note('between ' . scalar(keys %move) . ' move(s): ' . join(' ', sort keys %move)
        . '. With room and centre in the evaluation two moves are rarely worth exactly the same, so the seed rarely matters.');
};

subtest 'the search leaves the game alone' => sub {
    my $g = game('9/2b6/9/1w1b5/8b w');
    $g->step('b2-c2A');
    my @before = ($g->position, $g->ply, $g->in_progress, $g->turn, scalar($g->moves));
    $g->search(budget => 5000);
    is_deeply([ $g->position, $g->ply, $g->in_progress, $g->turn, scalar($g->moves) ], \@before,
        'position, ply, the move in progress, the turn and the log are as they were');
    my $before = Game::Fanorona::Rules->live;
    $G->new->search(budget => 3000) for 1 .. 5;
    is(Game::Fanorona::Rules->live, $before, 'and the copies it plays into are all dropped');

    my $over = game('9/9/w1b6/9/9 w');
    $over->play('a3-b3A');
    is($over->search(budget => 100), undef, 'a game that is over has nothing to search');
    # A game ended by the BOARD is refused by the engine underneath as well, so
    # the line above passes with the facade's own check taken out: the
    # packaging phase's mutation total found that. A game ended by a PERSON is
    # one only the facade knows is over.
    my $resigned = Game::Fanorona->new;
    ok($resigned->search(budget => 100), 'a game in progress is searched');
    $resigned->resign('white');
    is($resigned->search(budget => 100), undef, 'and once a side has resigned it is not, though the board could go on');
    my $agreed = Game::Fanorona->new;
    $agreed->offer_draw('white');
    $agreed->accept_draw('black');
    is($agreed->search(budget => 100), undef, 'nor is a game drawn by agreement');
};

subtest 'the evaluation' => sub {
    my $g = $R->new;
    is($g->evaluate, 0, 'the set-up is level');
    is_deeply($R->weights, { stone => 100, strong => 0, centre => 2, room => 2 },
        'four weights: a stone a hundred, room and centre two each, and strong points nothing');
    my $up = $R->new(position => '9/9/4w4/9/8b w');
    is($up->evaluate({ strong => 0, centre => 0, room => 0 }), 0, 'one stone each is level on stones alone');
    is($R->new(position => '9/9/4w4/9/9 b', variant => {})->evaluate({ strong => 0, centre => 0, room => 0 }), 100, 'a white stone is +100');
    is($R->new(position => '9/9/4b4/9/9 w')->evaluate({ strong => 0, centre => 0, room => 0 }), -100, 'a black one is -100: it is scored for White whoever is to move');
    is($up->evaluate({ strong => 5, centre => 0, room => 0 }), 0, 'e3 and i1 are both strong points');
    is($R->new(position => '9/9/4w4/9/7b1 w')->evaluate({ strong => 5, centre => 0, room => 0 }), 5, 'e3 is strong and h1 is not: +5');
    is($up->evaluate({ strong => 0, centre => 1, room => 0 }), 6, 'e3 is six steps nearer the centre than i1');
    is($up->evaluate({ strong => 0, centre => 0, room => 1 }), 5, 'e3 has eight empty points beside it and i1 has three');
    ok(!eval { $up->evaluate({ luck => 1 }); 1 }, 'a weight that is not one croaks');
    like($@, qr/no weight is called 'luck'/, 'naming it');
    ok(!eval { $up->search(colour => 'red'); 1 }, 'and so does an argument to search that is not one');
    ok(!eval { $up->search(budget => 0); 1 }, 'a budget of nothing');
    ok(!eval { $up->search(budget => 10, seed => 'x'); 1 }, 'and a seed that is not a number');
};

done_testing();
