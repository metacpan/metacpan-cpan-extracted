#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Digest::SHA ();
use DurakFixture qw(seed32 game_with kinds end_of refill_of);
use Game::Durak;
use Game::Durak::Card qw(id_of CARDS);
use Game::Durak::Deck qw(HAND_SIZE);

#   After a bout is complete, all players who have fewer than six cards must
#   if possible replenish their hands to six by drawing sufficient cards from
#   the top of the talon. The attacker replenishes first ... and finally the
#   defender.

# One card in the talon, and it goes to the seat that attacked.
my $short = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 7S)],
    hand2    => [qw(9S 9D)],
    talon    => [qw(AH)],
);

is($short->talon_left, 1, 'one card to draw');
$short->apply(1, { kind => 'attack', card => id_of('6S') });
my @ev = $short->apply(2, { kind => 'beat', card => id_of('9S') });

is(kinds(@ev), 'beat bout_end refill', 'the bout ends and the refill follows it');
is(end_of(@ev)->{how}, 'exhausted', 'the attacker had no seven to throw');

my $refill = refill_of(@ev);
is($refill->{drawn}{1}, 1, 'the attacker drew the one card there was');
is($refill->{drawn}{2}, 0, 'and the defender drew nothing');
is($refill->{talon}, 0, 'the talon is empty');
is($short->count_of(1), 2, 'the attacker holds two');
is($short->count_of(2), 1, 'and the defender one');

# A defender who has just taken a bout is already over six and draws nothing.
my $taken = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(AS KS QS JS TS 9S)],
    hand2    => [qw(6C 7C 8C 9C TC JC)],
    talon    => [qw(7H KH)],
);

@ev = $taken->apply(1, { kind => 'attack', card => id_of('AS') });
is(kinds(@ev), 'attack bout_end refill',
   'the defender cannot beat the ace of spades with six clubs');
is(end_of(@ev)->{taken}, 1, 'so the bout is taken');

$refill = refill_of(@ev);
is($refill->{drawn}{1}, 1, 'the attacker draws back to six');
is($refill->{drawn}{2}, 0, 'the defender holds seven and draws nothing');
is($refill->{talon}, 1, 'one card left');
is($taken->count_of(1), HAND_SIZE, 'the attacker is full');
is($taken->count_of(2), 7, 'the defender is over full');

# An empty talon still writes the event, because a replay compares streams and
# a stream that drops its no-ops is a different stream.
my $dry = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S 8D)],
    hand2    => [qw(9S 9D)],
);

$dry->apply(1, { kind => 'attack', card => id_of('8S') });
$dry->apply(2, { kind => 'beat',   card => id_of('9S') });
$dry->apply(1, { kind => 'attack', card => id_of('8D') });
@ev = $dry->apply(2, { kind => 'beat', card => id_of('9D') });

is(kinds(@ev), 'beat bout_end refill out out game_end',
   'the refill event is written all the same, before the deal ends');
$refill = refill_of(@ev);
is($refill->{drawn}{1}, 0, 'nobody drew');
is($refill->{drawn}{2}, 0, 'on either side');
is($refill->{talon}, 0, 'from an empty talon');

# A whole deal: the talon empties exactly once, never grows, and every card of
# it reaches a hand.
my $game = Game::Durak->build(seed => seed32('durak-refill-sweep'));
my $talon_at_deal = $game->talon_left;
is($talon_at_deal, CARDS - 2 * HAND_SIZE, 'the talon starts at twenty-four');

my ($step, $drawn, $last, @wrong) = (0, 0, $talon_at_deal);
while (!$game->over) {
    last if ++$step > 400;
    my $seat  = $game->turn;
    my $legal = $game->legal($seat);
    last unless @$legal;
    my $pick = unpack('N', Digest::SHA::sha256("refill:$step")) % scalar @$legal;
    my @out = $game->apply($seat, $legal->[$pick]);
    last if ref $out[0] eq 'Game::Durak::Error';

    for my $e (grep { $_->{kind} eq 'refill' } @out) {
        $drawn += $e->{drawn}{1} + $e->{drawn}{2};
        push @wrong, "the talon grew at step $step" if $e->{talon} > $last;
        push @wrong, "the count disagrees at step $step"
            unless $e->{talon} == $game->talon_left;
        $last = $e->{talon};
    }
}

is_deeply(\@wrong, [], 'the talon only ever falls, and says so truthfully');
is($game->talon_left, 0, 'the deal empties it');
is($drawn, $talon_at_deal, "all $talon_at_deal cards were drawn, and no more");

done_testing();
