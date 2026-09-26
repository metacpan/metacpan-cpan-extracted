#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Digest::SHA ();
use DurakFixture qw(seed32 game_with kinds end_of);
use Game::Durak;
use Game::Durak::Card qw(id_of);
use Game::Durak::Result qw(out_seats result_for);

#   Note that the game can only end at the end of an bout. If after the final
#   attack has been beaten off, no one has any cards left, the game is a draw.

# The arithmetic on its own, which is all a draw is.
is_deeply([ out_seats({ 1 => 0, 2 => 0 }, 0) ], [ 1, 2 ], 'both seats are out');
is_deeply([ out_seats({ 1 => 0, 2 => 3 }, 0) ], [ 1 ], 'one seat is out');
is_deeply([ out_seats({ 1 => 0, 2 => 0 }, 4) ], [],
          'and nobody is out while the talon has cards');

is(result_for({ 1 => 2, 2 => 3 }, 0), undef, 'two hands is not a result');
is(result_for({ 1 => 0, 2 => 3 }, 0)->{outcome}, 'fool', 'one empty hand is');
is(result_for({ 1 => 0, 2 => 0 }, 0)->{outcome}, 'draw', 'two empty hands are a draw');
is(result_for({ 1 => 0, 2 => 0 }, 0)->{fool}, undef, 'with no fool in it');
is_deeply(result_for({ 1 => 0, 2 => 0 }, 0)->{places}, { 1 => 1, 2 => 1 },
          'and a shared first place');

# The written deal. The talon is empty, the attacker has two cards of a rank
# the defender can answer exactly, and both hands run out on the same bout.
my $draw = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S 8D)],
    hand2    => [qw(9S 9D)],
);

is($draw->talon_left, 0, 'there is nothing left to draw');
is($draw->bout->cap, 2, 'and two cards of attack against a hand of two');

$draw->apply(1, { kind => 'attack', card => id_of('8S') });
$draw->apply(2, { kind => 'beat',   card => id_of('9S') });
is($draw->over, 0, 'one card each is not the end of anything');

$draw->apply(1, { kind => 'attack', card => id_of('8D') });
is($draw->count_of(1), 0, 'the attacker is empty with the bout still open');
is($draw->over, 0, 'and the deal is not over, because the bout is not');

my @ev = $draw->apply(2, { kind => 'beat', card => id_of('9D') });

is(kinds(@ev), 'beat bout_end refill out out game_end',
   'the last answer ends the bout, and both seats go out on it');
is(end_of(@ev)->{how}, 'spent', 'the defence was spent, not beaten');

my @out = grep { $_->{kind} eq 'out' } @ev;
is_deeply([ map { $_->{seat} } @out ], [ 1, 2 ], 'both seats, in seat order');

my ($end) = grep { $_->{kind} eq 'game_end' } @ev;
is($end->{outcome}, 'draw', 'the deal is drawn');
is($end->{fool}, undef, 'there is no fool');
is_deeply($end->{places}, { 1 => 1, 2 => 1 }, 'and the places are shared');

is($draw->result->{outcome}, 'draw', 'the game keeps the result');
is($draw->count_of(1), 0, 'neither seat holds anything');
is($draw->count_of(2), 0, 'on either side');
is($draw->discard, 4, 'and the four cards are in the heap');

# Not every spent defence is a draw: the attacker has to be empty too.
my $not_drawn = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(8S KH)],
    hand2    => [qw(9S)],
);

$not_drawn->apply(1, { kind => 'attack', card => id_of('8S') });
$not_drawn->apply(2, { kind => 'beat',   card => id_of('9S') });
is($not_drawn->result->{outcome}, 'fool',
   'a spent defence against a seat still holding cards names a fool');
is($not_drawn->result->{fool}, 1, 'and it is the seat holding them');

# How often it happens, reported and not bounded: a draw is rare and a soak
# that saw none would prove nothing, which is why the written deal above is
# the test and this is a note.
my $drawn_count = 0;
for my $i (1 .. 300) {
    my $game = Game::Durak->build(seed => seed32("durak-draw-$i"));
    my $step = 0;
    while (!$game->over) {
        last if ++$step > 400;
        my $seat  = $game->turn;
        my $legal = $game->legal($seat);
        last unless @$legal;
        my $pick = unpack('N', Digest::SHA::sha256("draw:$i:$step")) % scalar @$legal;
        my @o = $game->apply($seat, $legal->[$pick]);
        last if ref $o[0] eq 'Game::Durak::Error';
    }
    $drawn_count++ if $game->result && $game->result->{outcome} eq 'draw';
}

note("draws in 300 deals of random legal play: $drawn_count");
cmp_ok($drawn_count, '>=', 0, 'the sweep ran');

done_testing();
