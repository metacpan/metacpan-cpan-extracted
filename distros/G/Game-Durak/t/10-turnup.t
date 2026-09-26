#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Digest::SHA ();
use DurakFixture qw(seed32 game_with kinds);
use Game::Durak;
use Game::Durak::Card qw(id_of name_of suit_of);

#   The turn-up remains part of the talon and is drawn as the last card.

my $game = Game::Durak->build(seed => seed32('durak-turnup'));

is($game->talon->[-1], $game->trump_card, 'the turn-up is the talon last card');
is(suit_of($game->trump_card), $game->trump, 'and its suit is the trump');
is($game->turn_up_left, 1, 'it is there to be drawn');

# Played out: the turn-up is the last card to leave the talon, whoever takes
# it, and nothing special happens when it does.
my ($step, $seen_without, @wrong) = (0, 0);
while (!$game->over) {
    last if ++$step > 400;
    my $before = $game->turn_up_left;
    my $left   = $game->talon_left;

    my $seat  = $game->turn;
    my $legal = $game->legal($seat);
    last unless @$legal;
    my $pick = unpack('N', Digest::SHA::sha256("turnup:$step")) % scalar @$legal;
    my @out  = $game->apply($seat, $legal->[$pick]);
    last if ref $out[0] eq 'Game::Durak::Error';

    push @wrong, "the turn-up went back into the talon at step $step"
        if $game->turn_up_left && !$before;

    push @wrong, "the turn-up left the talon at step $step with $left cards in it"
        if $before && !$game->turn_up_left && $left > 1;

    $seen_without++ unless $game->turn_up_left;
}

is_deeply(\@wrong, [], 'the turn-up leaves the talon last and never returns');
is($game->talon_left, 0, 'the talon empties');
cmp_ok($seen_without, '>', 0, 'and the deal ran on after it was drawn');

# The turn-up is in somebody's hand, on the table or in the heap, but it is
# not lost.
my $up = $game->trump_card;
my $held = grep { $_ == $up } @{ $game->hand_of(1) }, @{ $game->hand_of(2) };
ok($held || $game->discard, 'the turned up trump ended up somewhere real');

# An exchange replaces it, and the accessor follows the card rather than the
# position.
my $swap = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6H 8S 9S TS)],
    hand2    => [qw(7C 8C 9C TC)],
    talon    => [qw(7D 8D AH)],
);

is($swap->trump_card, id_of('AH'), 'the turn-up is the trump ace');
is($swap->six_owner, 1, 'and seat one was dealt the trump six');
is($swap->turn_up_left, 1, 'the turn-up is in the talon');

my @ev = $swap->apply(1, { kind => 'swap' });
is(kinds(@ev), 'swap', 'the exchange is one event and the turn does not move');
is($swap->trump_card, id_of('6H'), 'the turn-up is now the trump six');
is($swap->talon->[-1], id_of('6H'), 'which is the last card of the talon');
is($swap->turn_up_left, 1, 'so there is still a turn-up to draw last');
is($swap->trump, 'H', 'and the trump suit has not moved');

done_testing();
