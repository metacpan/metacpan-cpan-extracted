#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(game_with kinds);
use Game::Durak::Card qw(id_of);
use Game::Durak::Result qw(resign_for);

# Giving up is not in the rules of durak, which is a game people play until
# somebody is left holding cards. It is in every consumer of this engine,
# because a person can close a window, so the engine answers it: the seat that
# gives up is the fool, whatever it was holding.

is_deeply(resign_for(1, [ 1, 2 ]),
          { outcome => 'resign', fool => 1, places => { 1 => 2, 2 => 1 } },
          'the arithmetic is the same shape as an ordinary result');

my $game = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 7S 8S)],
    hand2    => [qw(9S TS JS)],
    talon    => [qw(7C 8C AH)],
);

is($game->turn, 1, 'seat one is on turn');

my @ev = $game->apply(1, { kind => 'resign' });
is(kinds(@ev), 'resign game_end', 'the resignation ends the deal at once');
is($ev[0]{seat}, 1, 'the event names the seat');
is($ev[1]{outcome}, 'resign', 'and the result says how it ended');
is($ev[1]{fool}, 1, 'the seat that gave up is the fool');
is_deeply($ev[1]{places}, { 1 => 2, 2 => 1 }, 'and places second');

is($game->over, 1, 'the deal is over');
is($game->result->{outcome}, 'resign', 'the game keeps the result');
is($game->turn, undef, 'nobody is on turn');
is_deeply($game->legal(1), [], 'and nothing is legal');

my $err = $game->apply(1, { kind => 'resign' });
is($err->code, 'game_over', 'a second resignation is refused');
$err = $game->apply(2, { kind => 'attack', card => id_of('9S') });
is($err->code, 'game_over', 'and so is a move');

# The seat that is NOT on turn may give up, which is the whole point: a person
# who has stopped playing is not waiting for their turn to say so.
my $waiting = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 7S 8S)],
    hand2    => [qw(9S TS JS)],
    talon    => [qw(7C 8C AH)],
);

$waiting->apply(1, { kind => 'attack', card => id_of('6S') });
is($waiting->turn, 2, 'the defender is on turn');

@ev = $waiting->apply(1, { kind => 'resign' });
is(kinds(@ev), 'resign game_end', 'the attacker gives up out of turn');
is($waiting->result->{fool}, 1, 'and is the fool for it');
is($waiting->result->{places}{2}, 1, 'the seat that was waiting places first');

# The cards are left where they lay: a finished deal is worth reading back.
is($waiting->count_of(1), 2, 'the hands are untouched');
is($waiting->bout->size, 1, 'and the open bout is still on the table');

# An unknown move is still an unknown move, on turn or off it.
my $other = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 7S)],
    hand2    => [qw(9S TS)],
);
$err = $other->apply(2, { kind => 'surrender' });
is($err->code, 'not_legal', 'the engine has no surrender, only a resign');
$err = $other->apply(3, { kind => 'resign' });
is($err->code, 'not_your_turn', 'and a seat that does not exist cannot give up');

done_testing();
