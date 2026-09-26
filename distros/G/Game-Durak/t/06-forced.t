#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(game_with kinds end_of);
use Game::Durak::Bout ();
use Game::Durak::Card qw(id_of);
use Game::Durak::Rules qw(forced legal_attacks legal_beats);

#   A TURN WITH NO CHOICE COSTS NOBODY A DEADLINE.

# An attacker with nothing legal left to throw does not say so: the bout ends
# inside the move that beat the last card.
my $exhausted = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S KH)],
    hand2    => [qw(7S 9C)],
);

$exhausted->apply(1, { kind => 'attack', card => id_of('6S') });
my @ev = $exhausted->apply(2, { kind => 'beat', card => id_of('7S') });

is(kinds(@ev), 'beat bout_end refill', 'the beat ends the bout by itself');
is(end_of(@ev)->{how}, 'exhausted', 'the attacker was unable, not unwilling');
is(end_of(@ev)->{taken}, 0, 'so it was beaten off');
is(end_of(@ev)->{next_attacker}, 2, 'and the defender attacks next');
is(scalar(grep { $_->{kind} eq 'done' } @{ $exhausted->history }), 0,
   'and no done event was written, because nobody made that move');
is($exhausted->turn, 2, 'the new bout waits on the new attacker');

# A defender who cannot beat the card in front of them does not say so either.
my $take = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(AS KH)],
    hand2    => [qw(6C 7C)],
);

@ev = $take->apply(1, { kind => 'attack', card => id_of('AS') });

is(kinds(@ev), 'attack bout_end refill',
   'the attack ends the bout: the defender cannot beat an ace with two clubs');
is(end_of(@ev)->{taken}, 1, 'the bout was taken');
is(end_of(@ev)->{how}, 'taken', 'and says so');
is(end_of(@ev)->{cards}, 1, 'one card into the hand');
is(end_of(@ev)->{next_attacker}, 1, 'and the attacker attacks again');
is(scalar(grep { $_->{kind} eq 'take' } @{ $take->history }), 0,
   'no take event, because picking up was not a decision');
is($take->count_of(2), 3, 'the defender holds its two clubs and the ace');

# A defender who CAN beat is asked, and taking is a real move.
my $choice = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(AS KH)],
    hand2    => [qw(6H 7C)],
);

$choice->apply(1, { kind => 'attack', card => id_of('AS') });
is(scalar(grep { $_->{kind} eq 'beat' } @{ $choice->legal(2) }), 1,
   'the trump six beats the plain ace');
is(scalar(grep { $_->{kind} eq 'take' } @{ $choice->legal(2) }), 1,
   'and taking it instead is offered');

@ev = $choice->apply(2, { kind => 'take' });
is(kinds(@ev), 'take bout_end refill', 'taken by choice, and the event is written');

# forced() answers the same question with no game at all: a hand, a bout and a
# trump. The exchange is why it takes a fifth argument, and phase 03 supplies
# it.
my $bare = Game::Durak::Bout->build(attacker => 1, defender => 2, cap => 2);
$bare->add_attack(id_of('AS'));

my $defending = [ map { id_of($_) } qw(6C 7C) ];
is_deeply(legal_beats($defending, $bare, 'H'), [],
          'two clubs beat neither the ace of spades nor anything else');
is(forced($defending, $bare, 'H', 'defend', 0), 1,
   'so the position is forced');
is(forced($defending, $bare, 'H', 'defend', 1), 0,
   'unless an exchange is available, and then it is not');

$bare->add_beat(id_of('7C'));

my $attacking = [ id_of('KH') ];
is_deeply(legal_attacks($attacking, $bare), [],
          'a king matches neither the ace nor the seven on the table');
is(forced($attacking, $bare, 'H', 'attack', 0), 1,
   'so that position is forced too');
is(forced($attacking, $bare, 'H', 'attack', 1), 0,
   'and an available exchange unforces it as well');

done_testing();
