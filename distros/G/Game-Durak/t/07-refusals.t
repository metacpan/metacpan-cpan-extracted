#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(seed32 game_with);
use Game::Durak;
use Game::Durak::Error ();
use Game::Durak::Card qw(id_of);

sub refused {
    my ($out, $code, $why) = @_;
    is(ref $out, 'Game::Durak::Error', "$why is refused");
    is($out->code, $code, "with $code") if ref $out eq 'Game::Durak::Error';
    return;
}

# The dealing errors.
refused(Game::Durak->build(seed => 'too short'), 'no_seed', 'a seed of the wrong length');
refused(Game::Durak->build(seed => undef), 'no_seed', 'no seed at all');
refused(Game::Durak->build(seed => seed32('durak'), number => 0),
        'bad_deal', 'a deal number of zero');
refused(Game::Durak->build(seed => seed32('durak'), seats => 3),
        'bad_seats', 'three seats');

my $game = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 6D 9D KH)],
    hand2    => [qw(7S AH 8C 9C)],
);

refused($game->apply(2, { kind => 'attack', card => id_of('7S') }),
        'not_your_turn', 'a move by the seat that is not on turn');
refused($game->apply(3, { kind => 'attack', card => id_of('6S') }),
        'not_your_turn', 'a move by a seat that does not exist');
refused($game->apply(1, { kind => 'shuffle' }),
        'not_legal', 'a move this engine does not have');
refused($game->apply(1, {}),
        'not_legal', 'a move with no kind');
refused($game->apply(1, { kind => 'beat', card => id_of('6S') }),
        'wrong_phase', 'beating when there is nothing to beat');
refused($game->apply(1, { kind => 'take' }),
        'wrong_phase', 'taking a bout that has not been attacked');
refused($game->apply(1, { kind => 'done' }),
        'must_attack', 'saying done before the bout is opened');
refused($game->apply(1, { kind => 'attack', card => id_of('AH') }),
        'card_not_held', 'attacking with a card in the other hand');
refused($game->apply(1, { kind => 'attack', card => undef }),
        'card_not_held', 'attacking with no card');
refused($game->apply(1, { kind => 'attack', card => 'AS' }),
        'card_not_held', 'attacking with a name instead of an id');

$game->apply(1, { kind => 'attack', card => id_of('6S') });
is($game->phase, 'defend', 'the bout is open');

refused($game->apply(1, { kind => 'attack', card => id_of('6D') }),
        'not_your_turn', 'the attacker cannot throw while the card is unanswered');
refused($game->apply(2, { kind => 'attack', card => id_of('7S') }),
        'wrong_phase', 'and the defender cannot attack');
refused($game->apply(2, { kind => 'beat', card => id_of('8C') }),
        'beats_nothing', 'a club does not beat a spade');

$game->apply(2, { kind => 'beat', card => id_of('7S') });
refused($game->apply(1, { kind => 'attack', card => id_of('9D') }),
        'rank_not_in_bout', 'a nine against a six and a seven');

# The deal is over, and so is every move in it.
my $over = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S 8D)],
    hand2    => [qw(9S 9D)],
);
$over->apply(1, { kind => 'attack', card => id_of('8S') });
$over->apply(2, { kind => 'beat',   card => id_of('9S') });
$over->apply(1, { kind => 'attack', card => id_of('8D') });
$over->apply(2, { kind => 'beat',   card => id_of('9D') });
is($over->over, 1, 'the deal has ended');
refused($over->apply(1, { kind => 'attack', card => id_of('8S') }),
        'game_over', 'a move after the end');

# bout_full cannot be reached by playing: legal() never offers a throw into a
# full attack, and the engine closes a full bout before anybody is asked. It
# is reachable only by handing the engine a position it would not have made,
# which is what a consumer with a stale move does, so it stays a refusal
# rather than the die that an impossible derivation gets.
my $full = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 6D)],
    hand2    => [qw(7S AH)],
    cap      => 1,
);
$full->bout->add_attack(id_of('6S'));
$full->bout->add_beat(id_of('7S'));

is($full->phase, 'attack', 'the constructed position waits on the attacker');
is($full->bout->room, 0, 'with no room left in the attack');
is_deeply([ grep { $_->{kind} eq 'attack' } @{ $full->legal(1) } ], [],
          'so nothing is offered');
refused($full->apply(1, { kind => 'attack', card => id_of('6D') }),
        'bout_full', 'and a throw sent anyway');

# Every code the engine has, so that a new one is noticed here first.
is_deeply([ Game::Durak::Error->codes ],
    [ sort qw(no_seed bad_deal bad_seats game_over not_your_turn wrong_phase
              not_legal card_not_held beats_nothing rank_not_in_bout bout_full
              must_attack not_the_six talon_shut) ],
    'the code table is the one the consumer maps');

is(Game::Durak::Error->new_code('never_heard_of_it')->message, 'never_heard_of_it',
   'an unknown code is its own message rather than undef');

done_testing();
