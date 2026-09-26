#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(game_with kinds end_of);
use Game::Durak::Card qw(id_of);

# Phase 02 settled that a position with no choice in it is resolved by the
# engine. An available exchange is a choice, so the same positions must be
# asked rather than resolved, and every branch of the choice must be there:
# a seat is nowhere required to give up the trump six.

sub offered {
    my ($game, $seat) = @_;
    return join ' ', map { $_->{kind} } @{ $game->legal($seat) };
}

# An attacker with nothing to throw, holding the trump six.
my $attack = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6H KS)],
    hand2    => [qw(AS 7C)],
    talon    => [qw(8D 7H)],
);

is($attack->six_owner, 1, 'the attacker was dealt the trump six');
$attack->apply(1, { kind => 'attack', card => id_of('KS') });
my @ev = $attack->apply(2, { kind => 'beat', card => id_of('AS') });

is(kinds(@ev), 'beat', 'the bout stays open, though the attacker cannot throw');
is($attack->turn, 1, 'and the attacker is asked');
is(offered($attack, 1), 'done swap',
   'with both answers: stop, or exchange and see');

# Exchanging for a card that matches nothing leaves the position forced, and
# the engine closes the bout inside the same move.
@ev = $attack->apply(1, { kind => 'swap' });
is(kinds(@ev), 'swap bout_end refill',
   'the seven of hearts throws at nothing, so the bout ends at once');
is(end_of(@ev)->{how}, 'exhausted', 'unable rather than unwilling');

# The six went under the talon and the refill drew it straight back out, which
# makes that seat its owner again by the letter of the rule. It is harmless:
# the six is the last card of the talon after an exchange, so drawing it is
# what empties the talon, and there is nothing left to exchange it for.
is($attack->turn_up_left, 0, 'the turn-up is gone');
is($attack->can_swap(1), 0, 'so no second exchange is available');

# The same position, with a turn-up that does match: the exchange buys a throw.
my $lucky = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6H KS)],
    hand2    => [qw(AS 7C)],
    talon    => [qw(8D AH)],
);

$lucky->apply(1, { kind => 'attack', card => id_of('KS') });
$lucky->apply(2, { kind => 'beat',   card => id_of('AS') });
@ev = $lucky->apply(1, { kind => 'swap' });

is(kinds(@ev), 'swap', 'the exchange leaves the bout open');
is(offered($lucky, 1), 'attack done',
   'because the trump ace matches the ace that beat the king');

# A defender with no beat, holding the trump six: the six is the lowest trump
# and a trump attack is what it cannot answer.
my $defend = game_with(
    trump    => 'H',
    attacker => 2,
    hand1    => [qw(6H 8S)],
    hand2    => [qw(KH 7C)],
    talon    => [qw(8D AH)],
);

is($defend->six_owner, 1, 'the defender was dealt the trump six');
@ev = $defend->apply(2, { kind => 'attack', card => id_of('KH') });

is(kinds(@ev), 'attack', 'the bout stays open, though the defender cannot beat');
is($defend->turn, 1, 'and the defender is asked');
is(offered($defend, 1), 'take swap',
   'to pick the bout up, or to exchange first');

@ev = $defend->apply(1, { kind => 'swap' });
is(kinds(@ev), 'swap', 'the exchange does not end the turn');
is(offered($defend, 1), 'beat take',
   'and the trump ace answers the trump king');

@ev = $defend->apply(1, { kind => 'beat', card => id_of('AH') });
is(kinds(@ev), 'beat bout_end refill',
   'the defence holds, on a card that was under the talon');
is(end_of(@ev)->{how}, 'exhausted',
   'and the attacker, left with a seven, has nothing to throw');
is($defend->turn, 1, 'so the seat that defended attacks next');

# Without the exchange the same defender would have been given no say at all.
my $plain = game_with(
    trump    => 'H',
    attacker => 2,
    hand1    => [qw(6H 8S)],
    hand2    => [qw(KH 7C)],
    talon    => [qw(8D AH)],
    six_owner => undef,
);

@ev = $plain->apply(2, { kind => 'attack', card => id_of('KH') });
is(kinds(@ev), 'attack bout_end refill',
   'with no exchange to make, the take is resolved and costs no move');
is(end_of(@ev)->{taken}, 1, 'the bout was taken');

done_testing();
