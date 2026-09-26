#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(seed32);
use Game::Durak;
use Game::Durak::Bot;
use Game::Durak::Card qw(id_of);

# The move log is the canonical serialisation, not the position. A deal is a
# seed and a list of moves, and everything else in the event stream has to
# come back the same way round.

sub played {
    my ($seed, $levels) = @_;
    my $game = Game::Durak->build(seed => $seed);
    my %bot = map {
        $_ => Game::Durak::Bot->new(level => $levels->{$_}, seed => "$seed:$_")
    } 1, 2;

    my $step = 0;
    while (!$game->over) {
        last if ++$step > 600;
        my $seat = $game->turn;
        my $move = $bot{$seat}->choose($game->view($seat));
        last unless $move;
        my @ev = $game->apply($seat, $move);
        last if ref $ev[0] eq 'Game::Durak::Error';
    }
    return $game;
}

is_deeply([ grep { Game::Durak->is_move($_) }
            qw(attack beat take done swap resign bout_end refill out game_end) ],
          [ qw(attack beat take done swap resign) ],
          'six kinds are moves and the rest are what the table did');

my ($checked, @wrong) = (0);

for my $i (1 .. 25) {
    my $seed = seed32("durak-replay-$i");
    my $game = played($seed, { 1 => 3, 2 => 2 });

    my $moves = Game::Durak->moves_of($game->history);
    my $again = Game::Durak->replay(seed => $seed, moves => $moves);

    if (ref $again eq 'Game::Durak::Error') {
        push @wrong, "deal $i: replay refused with " . $again->code;
        next;
    }

    $checked++;
    push @wrong, "deal $i: the event stream came back different"
        unless eq_hash({ e => $again->{events} }, { e => $game->history });

    push @wrong, "deal $i: the result came back different"
        unless eq_hash({ r => $again->{game}->result }, { r => $game->result });

    push @wrong, "deal $i: the hands came back different"
        unless eq_hash({ h => $again->{game}->hands }, { h => $game->hands });

    push @wrong, "deal $i: the heap came back different"
        unless $again->{game}->discard == $game->discard;
}

is_deeply(\@wrong, [], 'every deal replayed to the same events, result and hands');
is($checked, 25, "$checked deals replayed");

# The comparison has to be able to fail, or it proves nothing.
my $seed  = seed32('durak-replay-1');
my $game  = played($seed, { 1 => 3, 2 => 2 });
my $moves = Game::Durak->moves_of($game->history);

cmp_ok(scalar @$moves, '>', 10, 'the log has moves in it');

my $short = Game::Durak->replay(seed => $seed, moves => [ @{$moves}[ 0 .. $#$moves - 1 ] ]);
isnt(scalar @{ $short->{events} }, scalar @{ $game->history },
     'a log with the last move missing replays to a different stream');

my $other = Game::Durak->replay(seed => seed32('durak-replay-2'), moves => $moves);
ok(ref $other eq 'Game::Durak::Error'
   || !eq_hash({ e => $other->{events} }, { e => $game->history }),
   'and the same log against another seed does not reproduce it');

# A forged move is refused by the rules, which is what makes the log the
# whole truth: a consumer cannot store a move the engine would not have made.
my @forged = map { { %$_ } } @$moves;
my ($first_attack) = grep { $_->{kind} eq 'attack' } @forged;
$first_attack->{card} = $first_attack->{card} == id_of('AS')
                      ? id_of('KS') : id_of('AS');

my $bad = Game::Durak->replay(seed => $seed, moves => \@forged);
isa_ok($bad, 'Game::Durak::Error', 'a forged card');
is($bad->code, 'card_not_held', 'is refused for the card and not for the turn')
    if ref $bad eq 'Game::Durak::Error';

my @swapped = map { { %$_ } } @$moves;
$swapped[0]{seat} = 3 - $swapped[0]{seat};
my $wrong_seat = Game::Durak->replay(seed => $seed, moves => \@swapped);
isa_ok($wrong_seat, 'Game::Durak::Error', 'a move by the wrong seat');
is($wrong_seat->code, 'not_your_turn', 'is refused')
    if ref $wrong_seat eq 'Game::Durak::Error';

# Replay of nothing is a fresh deal, which is the base case a consumer hits
# on the first page load of a game nobody has moved in.
my $fresh = Game::Durak->replay(seed => $seed);
is(ref $fresh, 'HASH', 'an empty log replays');
is_deeply($fresh->{events}, [], 'to no events');
is($fresh->{game}->turn, $game->history->[0]{seat},
   'and the same seat is on turn as opened the real deal');

done_testing();
