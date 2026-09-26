#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(seed32 game_with kinds end_of);
use Game::Durak;
use Game::Durak::Card qw(id_of six_of);

#   If you are dealt the lowest trump (the six) or if you draw it from the
#   talon, you are allowed to exchange it for the face up trump ... The six of
#   trumps can only be exchanged by its original holder; if you acquire it
#   from another player (as one of the cards you pick up when attacked) you
#   cannot exchange it.

sub has_swap {
    my ($game, $seat) = @_;
    return scalar grep { $_->{kind} eq 'swap' } @{ $game->legal($seat) };
}

# Dealt it: seat one owns the six and may exchange on its own turn.
my $game = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6H 8S 9S TS)],
    hand2    => [qw(7C 8C 9C TC)],
    talon    => [qw(7D 8D AH)],
);

is($game->six_owner, 1, 'the seat that was dealt the six owns it');
is($game->can_swap(1), 1, 'and may exchange');
is($game->can_swap(2), 0, 'the other seat may not');
is(has_swap($game, 1), 1, 'the exchange is offered');
is($game->turn, 1, 'to the seat on turn');

my @ev = $game->apply(1, { kind => 'swap' });
is(kinds(@ev), 'swap', 'the exchange is a move of its own');
is($ev[0]{seat}, 1, 'by that seat');
ok(!exists $ev[0]{card}, 'and it carries no card, because both are public');

is($game->trump_card, id_of('6H'), 'the six is the turn-up now');
is($game->talon->[-1], id_of('6H'), 'under the talon');
is(scalar(grep { $_ == id_of('AH') } @{ $game->hand_of(1) }), 1,
   'and the trump ace is in the hand');
is(scalar(grep { $_ == id_of('6H') } @{ $game->hand_of(1) }), 0,
   'in place of the six');
is($game->count_of(1), 4, 'the hand is the same size');
is($game->six_owner, undef, 'and nobody owns the six any more');
is($game->turn, 1, 'the exchange did not end the turn');
is($game->phase, 'attack', 'nor change the stage');

my $err = $game->apply(1, { kind => 'swap' });
is(ref $err, 'Game::Durak::Error', 'a second exchange is refused');
is($err->code, 'not_the_six', 'because the seat no longer holds the six');

# Drawn from the talon: the seat that draws it owns it.
my $drawn = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S 9S TS JS QS)],
    hand2    => [qw(KS 7C 8C 9C TC)],
    talon    => [qw(6H 7D 8D 9D TD AH)],
);

is($drawn->six_owner, undef, 'nobody owns a six that is still in the talon');
$drawn->apply(1, { kind => 'attack', card => id_of('8S') });
@ev = $drawn->apply(2, { kind => 'beat', card => id_of('KS') });
is(kinds(@ev), 'beat bout_end refill', 'the bout ends and both seats draw');
is($drawn->six_owner, 1, 'the seat that drew the six owns it');
is($drawn->turn_up_left, 1, 'the turn-up is still under the talon');
is($drawn->can_swap(1), 1, 'and it may be exchanged');

# Taken from the other seat: nobody owns it after that.
my $stolen = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6H AS)],
    hand2    => [qw(7C 8C)],
    talon    => [qw(7D 8D AH)],
);

is($stolen->six_owner, 1, 'seat one was dealt the six');
@ev = $stolen->apply(1, { kind => 'attack', card => id_of('6H') });
is(kinds(@ev), 'attack bout_end refill',
   'two clubs cannot beat the trump six, so the bout is taken with no move');
is(end_of(@ev)->{taken}, 1, 'the defender takes the bout, six and all');
is(scalar(grep { $_ == id_of('6H') } @{ $stolen->hand_of(2) }), 1,
   'so the six is in the other hand');
is($stolen->six_owner, undef, 'and it may never be exchanged again');
is($stolen->can_swap(2), 0, 'not by the seat that picked it up');
is($stolen->can_swap(1), 0, 'and not by the seat that was dealt it');

# Taken back: your own six is not a six you acquired from anybody.
my $back = game_with(
    trump    => 'H',
    attacker => 2,
    hand1    => [qw(6H 8S 9S TS)],
    hand2    => [qw(6C 6D AS KS QS JS)],
    talon    => [qw(7C 8C 9C AH)],
);

is($back->six_owner, 1, 'seat one holds the six it was dealt');
$back->apply(2, { kind => 'attack', card => id_of('6C') });
$back->apply(1, { kind => 'beat',   card => id_of('6H') });
is($back->can_swap(1), 0, 'while the six is on the table it cannot be exchanged');
is($back->six_owner, 1, 'but the seat still owns it');

@ev = $back->apply(2, { kind => 'attack', card => id_of('6D') });
is(end_of(@ev)->{taken}, 1, 'the defender cannot beat the second six and takes');
is(scalar(grep { $_ == id_of('6H') } @{ $back->hand_of(1) }), 1,
   'picking its own six back up');
is($back->six_owner, 1, 'which it still owns, having acquired it from nobody');
is($back->turn_up_left, 1, 'the turn-up survived the refill');
is($back->can_swap(1), 1, 'so the exchange is available again');
is(has_swap($back, 1), 0, 'though not offered while the other seat is on turn');
is($back->turn, 2, 'which it is');

my $wrong_turn = $back->apply(1, { kind => 'swap' });
is(ref $wrong_turn, 'Game::Durak::Error', 'an exchange out of turn is refused');
is($wrong_turn->code, 'not_your_turn', 'for the turn and not for the card');

$back->apply(2, { kind => 'attack', card => id_of('AS') });
is($back->turn, 1, 'the defender is on turn');
is(has_swap($back, 1), 1, 'and now the exchange is offered');

# The turn-up already drawn: there is nothing to exchange for.
my $shut = game_with(
    trump      => 'H',
    attacker   => 1,
    hand1      => [qw(6H 8S 9S TS)],
    hand2      => [qw(7C 8C 9C TC)],
    talon      => [qw(7D 8D)],
    trump_card => 'AH',
);

is($shut->six_owner, 1, 'the seat still owns the six');
is($shut->turn_up_left, 0, 'but the turn-up has gone');
is($shut->can_swap(1), 0, 'so there is no exchange');
is(has_swap($shut, 1), 0, 'and none is offered');
$err = $shut->apply(1, { kind => 'swap' });
is($err->code, 'talon_shut', 'asking for one says the talon is shut');

# The turn-up IS the six of trumps: one deal in nine, and the exchange never
# arises. Searched rather than pinned, because a seed chosen in advance is a
# seed chosen by running the code.
my ($found, $tried);
for my $i (1 .. 200) {
    $tried = $i;
    my $g = Game::Durak->build(seed => seed32("durak-sixup-$i"));
    next unless $g->trump_card == six_of($g->trump);
    $found = $g;
    last;
}

ok($found, "a deal turning up the trump six was found in $tried seeds");
if ($found) {
    is($found->six_owner, undef, 'nobody was dealt it, so nobody owns it');
    is($found->can_swap(1), 0, 'and neither seat may exchange');
    is($found->can_swap(2), 0, 'for the card it would be exchanged for');
}

done_testing();
