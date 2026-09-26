#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(game_with kinds end_of);
use Game::Durak::Card qw(id_of rank_of);

#   each new attack card must be of the same rank as some card already played
#   during the current bout - either an attack card or a card played by the
#   defender

my $game = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 7D)],
    hand2    => [qw(7S AH)],
);

$game->apply(1, { kind => 'attack', card => id_of('6S') });
$game->apply(2, { kind => 'beat',   card => id_of('7S') });

my $bout = $game->bout;
is($bout->size, 1, 'one card of attack');
is_deeply([ sort keys %{ $bout->ranks } ], [ '6', '7' ],
          'the bout holds a six and a seven');
is(rank_of($bout->attacks->[0]), '6', 'the six is the attack card');
is(rank_of($bout->beats->[0]), '7', 'and the seven is the defender own card');

my @attacks = grep { $_->{kind} eq 'attack' } @{ $game->legal(1) };
is(scalar @attacks, 1, 'one card may be thrown in');
is($attacks[0]{card}, id_of('7D'),
   'the seven of diamonds, whose rank came from the card that beat the six');

# The mutation: a rank set built from the attack cards alone.
sub mutant_ranks {
    my ($bout) = @_;
    my %rank;
    $rank{ rank_of($_) } = 1 for @{ $bout->attacks };
    return \%rank;
}

my $mutant = mutant_ranks($bout);
is_deeply([ sort keys %$mutant ], ['6'], 'the mutation sees only the six');
ok(!$mutant->{ rank_of(id_of('7D')) },
   'so it refuses the throw the rules allow, and nothing else changes');

my @ev = $game->apply(1, { kind => 'attack', card => id_of('7D') });
is(kinds(@ev), 'attack', 'the throw-in is made');

@ev = $game->apply(2, { kind => 'beat', card => id_of('AH') });
is(kinds(@ev), 'beat bout_end refill out out game_end',
   'the trump ace ends the bout and empties both hands');
is(end_of(@ev)->{how}, 'spent', 'with the defender spent');
is(end_of(@ev)->{cards}, 4, 'four cards to the heap');

# A rank that is on the table in neither place is refused. The attacker has to
# be left a legal throw as well, or the position is forced and the engine has
# already closed the bout: a refusal is only reachable where there was a
# choice to get wrong.
my $wrong = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 6D 9D)],
    hand2    => [qw(7S AH 8C)],
);

$wrong->apply(1, { kind => 'attack', card => id_of('6S') });
$wrong->apply(2, { kind => 'beat',   card => id_of('7S') });

is($wrong->turn, 1, 'the attacker is still on turn, with a six to throw');
is_deeply([ map { $_->{card} }
            grep { $_->{kind} eq 'attack' } @{ $wrong->legal(1) } ],
          [ id_of('6D') ],
          'the six of diamonds is offered and the nine is not');

my $err = $wrong->apply(1, { kind => 'attack', card => id_of('9D') });
is(ref $err, 'Game::Durak::Error', 'sending the nine anyway is refused');
is($err->code, 'rank_not_in_bout', 'with the code for it');

done_testing();
