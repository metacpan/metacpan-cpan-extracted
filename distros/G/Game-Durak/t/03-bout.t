#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(game_with kinds end_of);
use Game::Durak::Card qw(id_of);

# Hearts are trumps throughout. Every expected answer below is read off the
# rules and worked out here, never copied from a run.

sub legal_cards {
    my ($legal, $kind) = @_;
    return [ map { $_->{card} } grep { $_->{kind} eq $kind } @$legal ];
}

my $game = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 7S 7D KH 9D AC)],
    hand2    => [qw(TS 9S 6H 9C 8C 7C)],
);

is($game->trump, 'H', 'hearts are trumps');
is($game->phase, 'attack', 'a fresh bout is at the attacking stage');
is($game->turn, 1, 'and seat one is on turn');
is($game->bout->cap, 6, 'six cards against a hand of six');
is_deeply($game->legal(2), [], 'the seat that is not on turn may do nothing');

# An opening attack may be any card, and there is nothing to be done about.
is_deeply(legal_cards($game->legal(1), 'attack'),
          [ map { id_of($_) } qw(7S 6S KH 9D 7D AC) ],
          'every card in hand opens the bout');
is(scalar(grep { $_->{kind} eq 'done' } @{ $game->legal(1) }), 0,
   'a bout cannot be declined before it is opened');

my @ev = $game->apply(1, { kind => 'attack', card => id_of('6S') });
is(kinds(@ev), 'attack', 'the attack is one event and nothing follows it');
is($game->phase, 'defend', 'the defending stage');
is($game->turn, 2, 'and the defender is on turn');

# The six of spades is beaten by a higher spade or by any heart. There is no
# obligation to follow suit.
is_deeply(legal_cards($game->legal(2), 'beat'),
          [ map { id_of($_) } qw(TS 9S 6H) ],
          'two higher spades and the trump six');
is(scalar(grep { $_->{kind} eq 'take' } @{ $game->legal(2) }), 1,
   'and taking is offered, because beating is possible');

@ev = $game->apply(2, { kind => 'beat', card => id_of('9S') });
is(kinds(@ev), 'beat', 'the beat is one event');
is($game->phase, 'attack', 'back to the attacking stage');
is($game->turn, 1, 'with the attacker on turn');

# The bout holds a six and a nine, so only a nine may be thrown in.
is_deeply(legal_cards($game->legal(1), 'attack'), [ id_of('9D') ],
          'the nine of diamonds, by rank');
is(scalar(grep { $_->{kind} eq 'done' } @{ $game->legal(1) }), 1,
   'and the attacker may stop instead');

@ev = $game->apply(1, { kind => 'attack', card => id_of('9D') });
is(kinds(@ev), 'attack', 'the throw-in is one event');
is_deeply(legal_cards($game->legal(2), 'beat'), [ id_of('6H') ],
          'only the trump six answers the nine of diamonds');

@ev = $game->apply(2, { kind => 'take' });
is(kinds(@ev), 'take bout_end refill',
   'taking ends the bout at once, because the attacker has nothing left to throw');

my $end = end_of(@ev);
is($end->{taken}, 1, 'the bout was taken');
is($end->{how}, 'taken', 'and says so');
is($end->{cards}, 3, 'three cards go to the defender');
is($end->{discard}, 0, 'and none to the heap');
is($end->{next_attacker}, 1, 'a successful attacker attacks again');

is($game->count_of(2), 8, 'the defender holds five and picks up three');
is($game->count_of(1), 4, 'the attacker has spent two');
is($game->bout->cap, 6, 'the new cap is six, not eight');
is($game->phase, 'attack', 'and the new bout is open');

# The second bout: beaten off because the attacker chooses to stop.
@ev = $game->apply(1, { kind => 'attack', card => id_of('7S') });
is(kinds(@ev), 'attack', 'the second bout opens');
@ev = $game->apply(2, { kind => 'beat', card => id_of('TS') });
is(kinds(@ev), 'beat', 'and is answered');

is_deeply(legal_cards($game->legal(1), 'attack'), [ id_of('7D') ],
          'the seven of diamonds could be thrown in');

@ev = $game->apply(1, { kind => 'done' });
is(kinds(@ev), 'done bout_end refill', 'saying done ends the bout');
$end = end_of(@ev);
is($end->{taken}, 0, 'beaten off');
is($end->{how}, 'done', 'by the attacker choosing to stop');
is($end->{cards}, 2, 'two cards to the heap');
is($end->{discard}, 2, 'which is what the heap now holds');
is($end->{next_attacker}, 2, 'and the defender attacks next');

is($game->turn, 2, 'the seats have changed round');
is($game->bout->cap, 3, 'the new cap is the three cards seat one holds');

# A defence that uses the defender's last card ends the bout spent.
my $spent = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S 8D)],
    hand2    => [qw(9S 9D)],
);

is($spent->bout->cap, 2, 'a hand of two caps the attack at two');
$spent->apply(1, { kind => 'attack', card => id_of('8S') });
$spent->apply(2, { kind => 'beat',   card => id_of('9S') });
$spent->apply(1, { kind => 'attack', card => id_of('8D') });
@ev = $spent->apply(2, { kind => 'beat', card => id_of('9D') });

is(kinds(@ev), 'beat bout_end refill out out game_end',
   'the last beat ends the bout, and with it the deal');
is(end_of(@ev)->{how}, 'spent', 'the defender has nothing left');
is(end_of(@ev)->{taken}, 0, 'and the attack was beaten off');
is(end_of(@ev)->{cards}, 4, 'four cards to the heap');
is($spent->count_of(2), 0, 'the defender is empty');
is($spent->count_of(1), 0, 'and so is the attacker, so nobody is the fool');
is($spent->result->{outcome}, 'draw', 'the deal is drawn');
is($spent->phase, 'over', 'the stage is over');
is($spent->turn, undef, 'nobody is on turn');
is_deeply($spent->legal(1), [], 'and nothing is legal');

is(scalar @{ $game->history }, 11,
   'eleven events: attack beat attack take bout_end refill, '
   . 'then attack beat done bout_end refill');

done_testing();
