#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(game_with kinds end_of);
use Game::Durak::Card qw(id_of);

#   the game continues after the talon is exhausted until at the end of a
#   bout, only one player has any cards left. This player is the loser (the
#   fool) ... Note that the game can only end at the end of an bout.

# Nobody is out while the talon has cards, however empty a hand gets.
my $early = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S 7C JC QC KC)],
    hand2    => [qw(9S 7D 8D 9D TD)],
    talon    => [qw(JD QD AH)],
);

my @ev = $early->apply(1, { kind => 'attack', card => id_of('8S') });
@ev = $early->apply(2, { kind => 'beat', card => id_of('9S') });

is(kinds(@ev), 'beat bout_end refill', 'the bout ends and both seats draw');
is($early->over, 0, 'nobody is out while there was a talon to draw from');
is($early->count_of(1), 6, 'the attacker drew first and filled its hand');
is($early->count_of(2), 5, 'the defender drew what was left');
is($early->talon_left, 0, 'which was the rest of the talon');

# A defender who has taken cannot be out: it is holding the bout.
my $taking = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(AS KS)],
    hand2    => [qw(7C)],
);

@ev = $taking->apply(1, { kind => 'attack', card => id_of('AS') });
is(kinds(@ev), 'attack bout_end refill',
   'the defender cannot beat an ace with a seven, so it takes');
is(end_of(@ev)->{taken}, 1, 'the bout was taken');
is($taking->count_of(2), 2, 'the defender holds its club and the ace');
is($taking->over, 0, 'so nobody is out and the deal runs on');
is($taking->turn, 1, 'with the same seat attacking again');

# An attacker that plays its last card is not out until the bout closes.
my $last = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(AS)],
    hand2    => [qw(6H 7C)],
);

@ev = $last->apply(1, { kind => 'attack', card => id_of('AS') });
is(kinds(@ev), 'attack', 'the attack is the only event');
is($last->count_of(1), 0, 'the attacker is empty');
is($last->over, 0, 'and still not out, because the bout is open');
is($last->result, undef, 'there is no result yet');
is($last->turn, 2, 'the defender has to answer');

@ev = $last->apply(2, { kind => 'beat', card => id_of('6H') });
is(kinds(@ev), 'beat bout_end refill out game_end',
   'the answer closes the bout, and the deal with it');
is(end_of(@ev)->{how}, 'exhausted', 'the attacker had nothing left to throw');

my ($out) = grep { $_->{kind} eq 'out' } @ev;
is($out->{seat}, 1, 'the seat that ran out is named');
is($last->result->{outcome}, 'fool', 'somebody is the fool');
is($last->result->{fool}, 2, 'the seat still holding a card');
is_deeply($last->result->{places}, { 1 => 1, 2 => 2 }, 'and it places second');

# A defender that beats with its last card is out, and the attacker is left
# holding the deal.
my $spent = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S KH)],
    hand2    => [qw(9S)],
);

is($spent->bout->cap, 1, 'one card in the defending hand, one card of attack');
$spent->apply(1, { kind => 'attack', card => id_of('8S') });
@ev = $spent->apply(2, { kind => 'beat', card => id_of('9S') });

is(kinds(@ev), 'beat bout_end refill out game_end', 'the deal ends on the answer');
is(end_of(@ev)->{how}, 'spent', 'the defender spent its last card');
is($spent->result->{fool}, 1, 'and the attacker, still holding a king, is the fool');
is_deeply($spent->result->{places}, { 1 => 2, 2 => 1 }, 'placing second');
is($spent->phase, 'over', 'the deal is over');
is_deeply($spent->legal(1), [], 'and nothing is legal for either seat');
is_deeply($spent->legal(2), [], 'including the seat that went out');

my $err = $spent->apply(1, { kind => 'attack', card => id_of('KH') });
is($err->code, 'game_over', 'a move after the end is refused');

done_testing();
