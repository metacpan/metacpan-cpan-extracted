#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(seed32 game_with);
use Game::Durak;
use Game::Durak::Bot;
use Game::Durak::Search qw(best LEVELS);
use Game::Durak::Card qw(id_of suit_of power_of);

is(LEVELS, 3, 'three rungs');
is(Game::Durak::Bot->levels, 3, 'and the bot says so too');

# The ladder is a mapping and it is written weakest first, because a hint
# reaches for the top of it and a consumer asserts the order.
is_deeply(\@Game::Durak::Bot::LADDER, [ 1, 1, 2, 3, 3 ],
          'five consumer levels onto three rungs');
is(Game::Durak::Bot->level_for(1), 1, 'level one plays rung one');
is(Game::Durak::Bot->level_for(4), 3, 'level four plays rung three');
is(Game::Durak::Bot->level_for(99), 3, 'a level past the end clamps');
is(Game::Durak::Bot->level_for(0), 1, 'and so does one before it');
is(Game::Durak::Bot->level_for(undef), 1, 'undef plays the floor');

# Every rung answers every position of a whole deal with a move that is in
# legal, and never with undef while there is something to do.
for my $level (1 .. LEVELS) {
    my $game = Game::Durak->build(seed => seed32("durak-bot-$level"));
    my %bot = map {
        $_ => Game::Durak::Bot->new(level => $level, seed => "durak-bot-$level:$_")
    } 1, 2;

    my ($step, @wrong) = (0);
    while (!$game->over) {
        last if ++$step > 600;
        my $seat  = $game->turn;
        my $view  = $game->view($seat);
        my $move  = $bot{$seat}->choose($view);

        unless ($move) {
            push @wrong, "rung $level had no answer at step $step";
            last;
        }

        my $kind = $move->{kind};
        my $card = defined $move->{card} ? $move->{card} : '-';
        push @wrong, "rung $level played $kind $card, which is not legal"
            unless grep {
                $_->{kind} eq $kind
                && (defined $_->{card} ? $_->{card} : '-') eq $card
            } @{ $view->{legal} };

        my @ev = $game->apply($seat, $move);
        if (ref $ev[0] eq 'Game::Durak::Error') {
            push @wrong, "rung $level was refused: " . $ev[0]->code;
            last;
        }
    }

    is_deeply(\@wrong, [], "rung $level played a whole deal legally");
    ok($game->over, "rung $level finished the deal in $step moves");
}

# Two bots of the same rung in one deal must not mirror each other, or the
# whole measurement would be comparing a bot with itself.
{
    my $seed = seed32('durak-bot-mirror');
    my $game = Game::Durak->build(seed => $seed);
    my %bot = map {
        $_ => Game::Durak::Bot->new(level => 1, seed => "$seed:$_")
    } 1, 2;

    my %played = (1 => [], 2 => []);
    my $step = 0;
    while (!$game->over) {
        last if ++$step > 600;
        my $seat = $game->turn;
        my $move = $bot{$seat}->choose($game->view($seat));
        last unless $move;
        push @{ $played{$seat} },
            $move->{kind} . ':' . (defined $move->{card} ? $move->{card} : '-');
        my @ev = $game->apply($seat, $move);
        last if ref $ev[0] eq 'Game::Durak::Error';
    }

    isnt(join('|', @{ $played{1} }), join('|', @{ $played{2} }),
         'the two seats did not play the same sequence');
    cmp_ok(scalar @{ $played{1} }, '>', 5, 'and both of them played');
}

# The same bot, seed and position gives the same move every time.
my $view = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 7S 8D KH)],
    hand2    => [qw(9S TS JS QS)],
    talon    => [qw(7C 8C AH)],
)->view(1);

my $bot = Game::Durak::Bot->new(level => 1, seed => 'fixed');
is_deeply($bot->choose($view), $bot->choose($view), 'rung one repeats itself');

# Rung 2 and rung 3 play the cheapest card, and a plain card before a trump.
my $cheap = Game::Durak::Bot->new(level => 2, seed => 'fixed');
my $move  = $cheap->choose($view);
is($move->{kind}, 'attack', 'rung two opens the bout');
is($move->{card}, id_of('6S'), 'with the lowest plain card it holds');
isnt(suit_of($move->{card}), 'H', 'and never with a trump while it has a choice');

# A hint is the top rung, and it takes no seed.
my $hint = Game::Durak::Bot->hint($view);
is($hint->{kind}, 'attack', 'the hint is a move');
ok(scalar(grep { $_->{kind} eq $hint->{kind} && $_->{card} == $hint->{card} }
          @{ $view->{legal} }), 'and a legal one');

# Nothing legal, nothing chosen.
is($bot->choose({ legal => [] }), undef, 'an empty legal list answers undef');
is($bot->choose(undef), undef, 'and so does no view at all');
is(best({ legal => [] }, 3, 0), undef, 'the search says the same');

# The exchange is taken by every rung above the floor, because it is nearly
# always right and the measurement says the rungs that take it win.
my $swap = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6H 8S 9S TS)],
    hand2    => [qw(7C 8C 9C TC)],
    talon    => [qw(7D 8D AH)],
);
is($swap->can_swap(1), 1, 'the exchange is available');
for my $level (2, 3) {
    my $pick = Game::Durak::Bot->new(level => $level, seed => 'fixed')
                               ->choose($swap->view(1));
    is($pick->{kind}, 'swap', "rung $level exchanges the trump six");
}

done_testing();
