use strict;
use warnings;
use Test::More;

use Game::RoyalUr;
use Game::RoyalUr::Dice qw(throw_for marked roll_of opening_for);
my $G = 'Game::RoyalUr';

my %FINKEL  = (dice => 4, zero_rolls => 0);
my %MASTERS = (dice => 3, zero_rolls => 4);

sub faces { join '', @{ $_[0] } }

subtest 'a new game' => sub {
    my $game = $G->new(seed => 'facade 46', first => 'light');
    is($game->position, '4xx2/8/4xx2 l 7 0 7 0', 'the empty board');
    is($game->first, 'light', 'light was told to move first');
    is($game->variant->name, 'finkel', 'under finkel');
    is($game->seed, 'facade 46', 'the seed is handed back');
    ok(!$game->is_over, 'not over');
    is($game->result, undef, 'no result');
    is($game->error, undef, 'and no error');
    ok(!eval { $G->new; 1 }, 'a game with no seed croaks');
    like($@, qr/wants a seed/, 'and says what it wants');
    ok(!eval { $G->new(seed => ''); 1 }, 'so does an empty one');
    ok(!eval { $G->new(seed => 's', first => 'white'); 1 }, 'and a first that is neither side');
    ok(!eval { $G->new(seed => 's', position => 'junk'); 1 }, 'and a position that is none');
    ok(!eval { $G->new(seed => 's', position => '4xx2/8/4xx2 l 7 0 6 0'); 1 }, 'and one that does not add up');
    like($@, qr/does not hold 7 pieces a side/, 'which is said');
};

# BETWEEN CALLS: the game is over, or the side to move has a roll and at least
# one move it allows. After new, and after every play.
subtest 'the invariant, over twenty thousand plays a rule set' => sub {
    for my $rules ('finkel', 'masters') {
        my ($plays, $games, $forfeits, $finished, @bad) = (0, 0, 0, 0);
        while ($plays < 20_000) {
            my $game = $G->new(seed => "invariant $rules $games", rules => $rules);
            $games++;
            my $pick = 0;
            while (1) {
                if ($game->is_over) {
                    push @bad, 'a finished game has a side' if defined $game->side;
                    push @bad, 'a finished game has a roll' if defined $game->roll;
                    push @bad, 'a finished game has moves' if $game->legal;
                    $finished++;
                    last;
                }
                my @moves = $game->legal;
                my $roll = $game->roll;
                push @bad, 'no roll' unless defined $roll && $roll =~ /\A[1-4]\z/;
                push @bad, 'a roll with no move' unless @moves;
                push @bad, 'a move for the wrong roll' if grep { $_->roll != $roll } @moves;
                push @bad, 'a move for the wrong side' if grep { $_->side ne $game->side } @moves;
                push @bad, 'the dice are not the roll'
                    unless roll_of(marked($game->throw), $game->variant) == $roll;
                last if $plays >= 20_000;
                $game->play($moves[ $pick++ % @moves ]) or push @bad, 'a legal move was refused: ' . $game->error->code;
                $plays++;
            }
            $forfeits += $game->forfeits_since(0);
            last if @bad > 20;
        }
        is(scalar @bad, 0, "$rules: $plays plays in $games games") or diag(join "\n", @bad[0 .. ($#bad > 5 ? 5 : $#bad)]);
        cmp_ok($finished, '>', 50, "$rules: $finished of them played to the end");
        cmp_ok($forfeits, '>', ($rules eq 'finkel' ? 1_000 : 50), "$rules: with $forfeits turns lost to the roll on the way");
    }
};

subtest 'the roll is thrown once a turn' => sub {
    my $game = $G->new(seed => 'facade 1', first => 'light');
    my ($roll, $rolls, $throw) = ($game->roll, $game->rolls, faces($game->throw));
    $game->roll, $game->legal, $game->throw for 1 .. 5;
    is($game->roll, $roll, 'asked five more times, the roll is the same');
    is($game->rolls, $rolls, 'and no more dice have been thrown');
    is(faces($game->throw), $throw, 'nor have they changed');
    is($rolls, 1, 'one throw so far: this turn\'s');
    is($throw, faces(throw_for('facade 1', 0, 4)), 'and it is throw 0 of the seed');
    my $handed = $game->throw;
    $handed->[0] = 9;
    is(faces($game->throw), $throw, 'the dice handed out are a copy');
};

# 'facade 50' told that light moves first: its rolls are 0, 2, 1, 1, 2. Light's
# first turn is lost before the caller has been asked anything.
subtest 'a game that opens with a throw of nothing' => sub {
    is(join(' ', map { roll_of(marked(throw_for('facade 50', $_, 4)), \%FINKEL) } 0 .. 2), '0 2 1',
        '(the seed throws 0, 2, 1: if this fails the dice changed)');
    my $game = $G->new(seed => 'facade 50', first => 'light');
    is($game->side, 'dark', 'dark is to move');
    is($game->roll, 2, 'with a roll of 2');
    is($game->ply, 1, 'and one ply has been made');
    is($game->rolls, 2, 'in two throws');
    my $log = $game->log;
    is(scalar @$log, 1, 'the log has one entry');
    is_deeply($log->[0], { ply => 0, side => 'light', throw => 0, roll => 0, faces => '0000', move => undef },
        'LIGHT ROLLED NOTHING: it is in the log, and not silently skipped');
    is(scalar($game->forfeits_since(0)), 1, 'forfeits_since(0) hands it over');
    is(scalar($game->forfeits_since(1)), 0, 'and forfeits_since(1) does not');
    is($game->first, 'light', 'light still moved first, as far as the record goes');
};

# 'facade 1' with nobody told: the opening throws are 1011 and 1101 (three
# each, a tie), then 0000 and 0001. Dark moves first, on throw 4.
subtest 'who moves first, when nobody says' => sub {
    my ($first, $used, $throws) = opening_for('facade 1', 4);
    is(join(' ', map { faces($_) } @$throws), '1011 1101 0000 0001', '(the seed opens with a tie and then dark by one)');
    my $game = $G->new(seed => 'facade 1');
    is($game->first, 'dark', 'dark moves first');
    is($game->side, 'dark', 'and is to move');
    is(join(' ', map { faces($_) } @{ $game->opening }), '1011 1101 0000 0001', 'the opening throws are kept');
    is($game->rolls, 5, 'FOUR opening throws and this turn\'s: five');
    is(faces($game->throw), faces(throw_for('facade 1', 4, 4)), 'and this turn is throw 4');
    is($game->ply, 0, 'no ply has been made by throwing for it');
    is(scalar @{ $game->log }, 0, 'and the log is empty');

    my $told = $G->new(seed => 'facade 1', first => 'light');
    is(scalar @{ $told->opening }, 0, 'a game that is told has no opening throws');
    is($told->rolls, 1, 'and its first turn is throw 0');
    is($told->side, 'light', 'for the side it was told');

    my $masters = $G->new(seed => 'opening 8', rules => 'masters');
    is($masters->first, 'dark', 'under masters, light threw nothing and dark one: dark moves first');
};

# 'facade 46' told that light moves first: 2, 0, 0, 1, 1. Light moves, then
# BOTH sides lose a turn, then dark has a choice.
subtest 'undo goes back through lost turns to the last choice' => sub {
    is(join(' ', map { roll_of(marked(throw_for('facade 46', $_, 4)), \%FINKEL) } 0 .. 3), '2 0 0 1',
        '(the seed throws 2, 0, 0, 1)');
    my $game = $G->new(seed => 'facade 46', first => 'light');
    my $before = join ' | ', $game->position, $game->side, $game->roll, $game->rolls, $game->ply;
    is($before, '4xx2/8/4xx2 l 7 0 7 0 | light | 2 | 1 | 0', 'light to move with a 2');

    ok($game->play('hand-c1'), 'light enters on c1');
    is($game->side, 'dark', 'dark is to move');
    is($game->roll, 1, 'with a 1');
    is($game->ply, 3, 'THREE plies on: the move, and two turns lost');
    is($game->rolls, 4, 'in four throws');
    is(join(' ', map { defined $_->{move} ? $_->{move} : $_->{side} . ' lost ' . $_->{roll} } @{ $game->log }),
        'hand-c1 dark lost 0 light lost 0', 'the log says what happened');
    is(scalar($game->forfeits_since(1)), 2, 'and forfeits_since(1) is the two lost turns');

    ok($game->undo, 'undo');
    is(join(' | ', $game->position, $game->side, $game->roll, $game->rolls, $game->ply), $before,
        'everything is as it was when light chose: position, side, roll, throws, ply');
    is(scalar @{ $game->log }, 0, 'and the log is empty again');
    ok(!$game->undo, 'there is nothing more to take back');

    ok($game->play('hand-c1'), 'played again');
    is($game->roll, 1, 'the same dice fall: dark has its 1');
    is($game->rolls, 4, 'on the same throw');
};

# Light has one piece on its last step and six home, and so has dark. Each
# needs exactly a 1, which is four throws in sixteen; every other roll is a
# turn lost. The game must throw until somebody rolls it, and count every one.
subtest 'settle keeps going until somebody can move' => sub {
    my $position = '4xxd1/8/4xxl1 l 0 6 0 6';
    for my $n (1 .. 30) {
        my $seed = "blocked $n";
        my ($side, $throw, $lost) = ('light', 0, 0);
        while (roll_of(marked(throw_for($seed, $throw, 4)), \%FINKEL) != 1) {
            $throw++;
            $lost++;
            $side = $side eq 'light' ? 'dark' : 'light';
        }
        my $game = $G->new(seed => $seed, position => $position);
        is($game->ply, $lost, "$seed: $lost turns lost before anybody could move");
        is($game->side, $side, "$seed: and it is $side who can");
        is($game->rolls, $lost + 1, "$seed: every throw counted");
        is(scalar($game->forfeits_since(0)), $lost, "$seed: every lost turn logged");
        ok($game->play($side eq 'light' ? 'g1-home' : 'g3-home'), "$seed: and the move wins");
        is($game->result->winner, $side, "$seed: for $side");
    }
};

subtest 'what a game answers about itself' => sub {
    my $game = $G->new(seed => 'facade 46', first => 'light');
    $game->play('hand-c1');
    is($game->at('c1'), 'light', 'a light piece on c1');
    is($game->at('d2'), undef, 'nothing on d2');
    ok(!eval { $game->at('e1'); 1 }, 'and e1 is not a square');
    is($game->hand('light'), 6, 'six in light hand');
    is($game->home('dark'), 0, 'none of dark home');
    like($game->key, qr/\A[0-9a-f]{12}\z/, 'a key');
    is(join(' ', map { "$_->[0]:$_->[1]/$_->[2]" } $game->chances), '0:1/16 1:4/16 2:6/16 3:4/16 4:1/16', 'the chances of its dice');
    is(join(' ', map { "$_->[0]:$_->[1]/$_->[2]" } $G->new(seed => 's', rules => 'masters')->chances),
        '1:3/8 2:3/8 3:1/8 4:1/8', 'and of masters dice');
    my $log = $game->log;
    $log->[0]{move} = 'changed';
    is($game->log->[0]{move}, 'hand-c1', 'the log handed out is a copy');
};

subtest 'resigning' => sub {
    my $game = $G->new(seed => 'facade 46', first => 'light');
    ok($game->resign, 'the side to move resigns');
    ok($game->is_over, 'the game is over');
    is($game->result->winner, 'dark', 'dark wins');
    is($game->result->how, 'resign', 'by resignation');
    is($game->result->loser, 'light', 'and light lost');
    ok(!$game->resign, 'nobody resigns a finished game');
    ok(!$game->play('hand-d1'), 'and nobody moves in one');
    is($game->error->code, 'game_over', 'because it is over');
    ok($game->undo, 'a resignation can be taken back');
    ok(!$game->is_over, 'and the game is going again');
    is($game->side, 'light', 'with light to move');

    my $other = $G->new(seed => 'facade 46', first => 'light');
    $other->resign('dark');
    is($other->result->winner, 'light', 'the side not to move may resign too');
    ok(!eval { $other->undo; $other->resign('white'); 1 }, 'but not a side that is neither');
};

subtest 'a game played to the end' => sub {
    my $game = $G->new(seed => 'to the end', rules => 'masters', first => 'dark');
    my $turns = 0;
    until ($game->is_over) {
        my @moves = $game->legal;
        $game->play_or_die($moves[0]);
        die 'this game is not ending' if ++$turns > 5_000;
    }
    my $result = $game->result;
    is($result->how, 'home', 'it ends with a side home');
    is($game->home($result->winner), 7, 'all seven of the winner');
    is($result->home->{ $result->winner }, 7, 'and the result says so');
    is($result->final, $game->position, 'the result carries the last position');
    is($result->plies, $game->ply, 'and the plies');
    ok(!$result->is_draw, 'not a draw');
    ok(!eval { $game->play_or_die('hand-d1'); 1 }, 'play_or_die dies on a finished game');
    like($@, qr/game_over: the game is already over/, 'with the code and the sentence');
};

done_testing();
