use strict;
use warnings;
use Test::More;

use Game::Xiangqi;

my $SEED = 'r' x 32;

# REPLAY REBUILDS FROM THE OPENING, EVERY TIME. It never loads a FEN and never
# trusts a stored position: the move log is the canonical serialisation, which
# is what makes a finished game checkable years later and what catches a forged
# one.

sub a_game {
    my $g = Game::Xiangqi->new(seed => $SEED, red => 'p1');
    # b7b3 was the eighth move in the first version of this line and is
    # ILLEGAL after b2b6: the black cannon would jump the red one onto an EMPTY
    # square, and a cannon jumps only to capture. The engine refused it and the
    # line was wrong, not the engine.
    my @line = qw(h2e2 h9g7 h0g2 i9h9 i0h0 b9c7 b2b6 a6a5);
    my $bad = 0;
    for my $m (@line) { $bad++ if $g->play($m) }
    return ($g, \@line, $bad);
}

subtest 'a game replays move for move' => sub {
    my ($g, $line, $bad) = a_game();
    is($bad, 0, 'the line plays with no refusal');
    is(scalar @{ $g->log }, scalar @$line, 'and the log has every move');

    my $again = Game::Xiangqi->replay(seed => $SEED, red => 'p1', moves => $g->log);
    ok($again, 'it replays');
    is($again->signature, $g->signature, '  to the same position, by signature');
    is($again->position->to_fen, $g->position->to_fen, '  and by FEN');
    is_deeply($again->log, $g->log, '  with the same log');
    is($again->turn, $g->turn, '  and the same side to move');
};

subtest 'a truncated log replays to a shorter game, still active' => sub {
    my ($g, $line) = a_game();
    my @short = @{ $g->log }[0 .. 3];
    my $part = Game::Xiangqi->replay(seed => $SEED, red => 'p1', moves => \@short);
    ok($part, 'the first four moves replay');
    is($part->status, 'active', '  and the game is still on');
    isnt($part->signature, $g->signature, '  at a different position');
    is(scalar @{ $part->log }, 4, '  with four moves logged');
};

subtest 'A FORGED LOG IS REFUSED AT THE MOVE THAT WAS ALTERED' => sub {
    my ($g) = a_game();
    my @forged = @{ $g->log };
    $forged[4] = 'a0a5';          # a chariot move that is not available there

    my ($built, $why, $at) = Game::Xiangqi->replay(
        seed => $SEED, red => 'p1', moves => \@forged);
    ok($why, "refused: $why");
    is($at, 4, 'AT the altered move, and not after it');
    is(scalar @{ $built->log }, 4, '  with only the moves before it played');
    isnt($built->signature, $g->signature, '  and it does not reach the position it claims');
};

subtest 'a move that was legal somewhere else is still refused here' => sub {
    my ($g) = a_game();
    my @forged = @{ $g->log };
    # h2e2 is legal as the FIRST move and nowhere later in this line
    $forged[6] = 'h2e2';
    my ($built, $why, $at) = Game::Xiangqi->replay(
        seed => $SEED, red => 'p1', moves => \@forged);
    ok($why, "refused: $why");
    is($at, 6, '  at the move that was moved');
};

subtest 'replay in scalar context gives the game or undef' => sub {
    my ($g) = a_game();
    my $ok = Game::Xiangqi->replay(seed => $SEED, moves => $g->log);
    ok($ok, 'a good log gives a game');
    my $no = Game::Xiangqi->replay(seed => $SEED, moves => [ 'zz99' ]);
    is($no, undef, 'and a bad one gives undef');
};

subtest 'an empty log replays to the opening' => sub {
    my $g = Game::Xiangqi->replay(seed => $SEED, moves => []);
    ok($g, 'it replays');
    is($g->status, 'active', 'active');
    is(scalar @{ $g->legal }, 44, 'and it is the opening position');
    is($g->signature, Game::Xiangqi->new(seed => $SEED)->signature, 'by signature too');
};

subtest 'the seat mapping survives a replay' => sub {
    my $g = Game::Xiangqi->new(seed => $SEED, red => 'p2');
    $g->play('h2e2');
    is($g->turn, 'p1', 'with p2 as Red, p1 moves second');
    my $again = Game::Xiangqi->replay(seed => $SEED, red => 'p2', moves => $g->log);
    is($again->turn, 'p1', '  and the replay agrees');

    # replayed with the OTHER seat as Red, the same moves give the other turn
    my $swapped = Game::Xiangqi->replay(seed => $SEED, red => 'p1', moves => $g->log);
    is($swapped->turn, 'p2', 'and swapping which seat is Red swaps the turn');
    is($swapped->signature, $again->signature, '  while the POSITION is identical');
};

# THE INSTANCE FORM, which phase 08's plan documented and phase 08 did not build.
# It went unnoticed because every test here used the class form, and the way it
# failed was a WARNING from inside the facade rather than a refusal: harmless in a
# test file, and a line in the server's log on every bot move in production.
# t/22-no-io.t is what found it.
subtest 'the instance form replays this game from its own start' => sub {
    my $g = Game::Xiangqi->new(seed => $SEED, red => 'p2');
    $g->play($_) for qw(h2e2 h9g7 b2e2);

    my $again = $g->replay($g->log);
    ok($again, 'a game replays itself');
    is_deeply($again->log, $g->log, '  move for move');
    is($again->signature, $g->signature, '  to the same position');
    is($again->turn, $g->turn, '  and the same turn');

    # IT KEEPS THE SEAT AND THE SEED, or a replayed game is a different game: `red`
    # decides who moves first and the site publishes the seed to prove the log.
    is($again->red, 'p2', 'the seat that is Red is carried over');
    is($again->_held_seed, $SEED, '  and so is the seed');

    # AND FROM THIS GAME'S OWN STARTING POSITION, not from the opening. This is the
    # bug phase 08 found in `_settle` wearing a different hat.
    my $E = 'Game::Xiangqi::Engine';
    # THE GENERALS GO ON DIFFERENT FILES. On the same file with nothing between
    # them they are already facing, which makes the position illegal before the test
    # starts and every move come back `generals_face`. Red's general sits on d0.
    my $pos = $E->new(empty => 1);
    $pos->put($E->point_of(3, 0), Game::Xiangqi::Engine::RED  | Game::Xiangqi::Engine::GENERAL);
    $pos->put($E->point_of(4, 9), Game::Xiangqi::Engine::BLACK | Game::Xiangqi::Engine::GENERAL);
    $pos->put($E->point_of(0, 0), Game::Xiangqi::Engine::RED  | Game::Xiangqi::Engine::CHARIOT);
    $pos->set_side(Game::Xiangqi::Engine::RED);
    my $set = Game::Xiangqi->new(seed => $SEED, red => 'p1', position => $pos);
    is($set->play('a0a5'), 0, 'a constructed game takes a move');
    my $back = $set->replay($set->log);
    ok($back, '  and replays');
    is($back->signature, $set->signature, '  to the same position, not the opening');

    # A caller that misuses it gets undef and NOT a warning.
    is(Game::Xiangqi->replay('odd', 'number', 'of', 'things', 'here'), undef,
       'an odd list is refused');
    my @none = $g->replay([]);
    ok($none[0], 'an empty list replays to the start position');
    is(scalar @{ $none[0]->log }, 0, '  with no moves');
};

done_testing();
