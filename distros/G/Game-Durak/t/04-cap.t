#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(game_with kinds end_of);
use Game::Durak::Bout ();
use Game::Durak::Card qw(id_of rank_of);
use Game::Durak::Rules qw(cap_for);

#   the total number of cards played by the attackers during a bout must never
#   exceed six; if the defender had fewer than six cards BEFORE the bout, the
#   number of cards played by the attackers must not be more than the number
#   of cards in the defender's hand.

is(cap_for(0), 0, 'an empty hand caps at nothing');
is(cap_for(1), 1, 'one card, one attack');
is(cap_for(5), 5, 'five cards, five attacks');
is(cap_for(6), 6, 'six cards, six attacks');
is(cap_for(7), 6, 'seven cards still cap at six');
is(cap_for(12), 6, 'and so does a hand of twelve');

eval { Game::Durak::Bout->build(attacker => 1, defender => 2, cap => 0); 1 };
like($@, qr/cap of one to six/, 'a bout is never opened against an empty hand');
eval { Game::Durak::Bout->build(attacker => 1, defender => 1, cap => 3); 1 };
like($@, qr/two different seats/, 'and never against itself');

# Four sixes against four cards. The cap is four and it stays four while the
# defender's hand falls four, three, two, one.
my @SEQUENCE = (
    [qw(6S 7S)],
    [qw(6H AH)],
    [qw(6D 7D)],
    [qw(6C 7C)],
);

my $game = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 6H 6D 6C)],
    hand2    => [qw(7S AH 7D 7C)],
);

is($game->bout->cap, 4, 'four cards in the defending hand, four cards of attack');

my $bout = $game->bout;
my $left = 4;
for my $pair (@SEQUENCE) {
    my ($attack, $beat) = @$pair;
    is($game->count_of(2), $left, "the defender holds $left");
    my @ev = $game->apply(1, { kind => 'attack', card => id_of($attack) });
    is(ref $ev[0], 'HASH', "$attack is thrown in");
    is($bout->cap, 4, 'and the cap is still four');
    @ev = $game->apply(2, { kind => 'beat', card => id_of($beat) });
    is(ref $ev[0], 'HASH', "$beat answers it");
    is($bout->cap, 4, 'the cap does not follow the hand down');
    $left--;
}

is($game->count_of(2), 0, 'the defender has spent every card');
is($bout->size, 4, 'and beat four attacks with four cards');

# The mutation: a cap recomputed from the hand as it stands.
sub mutant_room {
    my ($bout, $defender_size) = @_;
    return cap_for($defender_size) - $bout->size;
}

my $replay = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 6H 6D 6C)],
    hand2    => [qw(7S AH 7D 7C)],
);

my ($real, $mutant, $stopped) = (0, 0, 0);
for my $pair (@SEQUENCE) {
    my ($attack, $beat) = @$pair;
    my $b = $replay->bout;
    $real++ if $b->room > 0;
    if (!$stopped && mutant_room($b, $replay->count_of(2)) > 0) { $mutant++ }
    else { $stopped = 1 }
    last unless $b->room > 0;
    $replay->apply(1, { kind => 'attack', card => id_of($attack) });
    $replay->apply(2, { kind => 'beat',   card => id_of($beat) }) unless $replay->over;
}

is($real, 4, 'the rules allow four cards of attack');
is($mutant, 2, 'a cap read off the hand as it stands allows two');
is($real - $mutant, 2, 'so the mutation loses two throws and finishes the deal anyway');

# Six cards against a hand that still has something left: capped, not spent.
my $capped = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 6H 6D 6C AS AD)],
    hand2    => [qw(7S AH 7D 7C 9H TH 8C)],
);

is($capped->bout->cap, 6, 'seven cards in hand cap the attack at six');

my @SIX = (
    [qw(6S 7S)],
    [qw(6H AH)],
    [qw(6D 7D)],
    [qw(6C 7C)],
    [qw(AS 9H)],
    [qw(AD TH)],
);

my @last;
for my $pair (@SIX) {
    my ($attack, $beat) = @$pair;
    $capped->apply(1, { kind => 'attack', card => id_of($attack) });
    @last = $capped->apply(2, { kind => 'beat', card => id_of($beat) });
}

is(kinds(@last), 'beat bout_end refill out game_end',
   'the sixth answer ends the bout with no move asked for');
is(end_of(@last)->{how}, 'capped', 'because the attack is as large as it may be');
is(end_of(@last)->{taken}, 0, 'beaten off');
is(end_of(@last)->{cards}, 12, 'twelve cards to the heap');
is($capped->count_of(2), 1, 'and the defender still holds one, so it is not spent');
is($capped->result->{outcome}, 'fool', 'the attacker played out and the deal ends');
is($capped->result->{fool}, 2, 'the seat still holding a card is the durak');
is_deeply($capped->result->{places}, { 1 => 1, 2 => 2 }, 'and it places second');

done_testing();
