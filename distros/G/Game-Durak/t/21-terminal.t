#!perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DurakFixture qw(seed32 game_with);
use Game::Durak::Terminal;
use Game::Durak::Card qw(id_of);

# The terminal is driven through two string handles, which is what `out` and
# `in` are attributes for: everything a person would see can be asserted
# without a person.

sub terminal {
    my (%o) = @_;
    my $said = delete $o{said};
    $said = '' unless defined $said;
    my $shown = '';
    open my $in,  '<', \$said  or die $!;
    open my $out, '>', \$shown or die $!;
    my $terminal = Game::Durak::Terminal->new(
        in => $in, out => $out, ascii => 1, colour => 0, %o,
    );
    return ($terminal, \$shown);
}

my $game = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6S 8S TS KH)],
    hand2    => [qw(7S 9S JS QS)],
    talon    => [qw(7C 8C AH)],
);

my ($term) = terminal();

is($term->card(id_of('6S')), '6S', 'a card is its rank and its suit');
is($term->card(undef), '--', 'and an unanswered attack is a pair of dashes');
is($term->card_suit('H'), 'H', 'a suit on its own');
is($term->cards(1), '1 card', 'one card');
is($term->cards(3), '3 cards', 'and three of them');

my $view = $game->view(1);
is($term->hand_line($view->{hand}), q{1) 10S  2) 8S  3) 6S  4) KH},
   q{the hand is numbered from one, in the order the engine sorted it:}
   . q{ by suit, and within a suit from the ace down});

# THE TEN IS A TEN, not a T. The engine spells it T because a card there is a
# two character id; nobody has ever seen a ten with a T on it, and this is the
# only place in the distribution that draws a card for a person.
is($term->card(id_of('TS')), '10S', 'a ten reads as a ten');
is($term->card(id_of('AS')), 'AS',  'and everything else is unchanged');
is($term->bout_line($view->{bout}), 'nothing on the table',
   'an empty bout says so');

like($term->table($view), qr/trump H \(AH face up\)   talon 3   heap 0   they hold 4/,
     'the table says what is public and nothing else');
unlike($term->table($view), qr/7S|9S|JS|QS/, 'and never the other hand');

is_deeply($term->playable($view), [ 1, 2, 3, 4 ],
          'every card opens a bout');
is($term->prompt_for($view), '[1 2 3 4] a card  r resign  q quit',
   'and the prompt says so, without offering a take or a done');

is($term->move_for($view, "1\n")->{card}, id_of(q{TS}), q{a number is a card});
is($term->move_for($view, "4\n")->{card}, id_of('KH'), 'and so is the last one');
is($term->move_for($view, "5\n"), undef, 'a number past the hand is nothing');
is($term->move_for($view, "0\n"), undef, 'and so is zero');
is($term->move_for($view, "banana\n"), undef, 'and so is a word');
is($term->move_for($view, undef), undef, 'and so is the end of the input');
is($term->move_for($view, "q\n")->{kind}, 'quit', 'q quits');
is($term->move_for($view, "r\n")->{kind}, 'resign', 'r gives up');
is($term->move_for($view, "t\n"), undef, 'and t takes nothing when nothing is offered');

# A defending view: the take appears, and only the cards that beat are
# playable.
$game->apply(1, { kind => 'attack', card => id_of('8S') });
my $defend = $game->view(2);

is($defend->{phase}, 'defend', 'the defender is on turn');
is_deeply($term->playable($defend), [ 1, 2, 3 ],
          q{the queen, jack and nine of spades beat the eight; the seven does not});
is($term->prompt_for($defend), q{[1 2 3] a card  t take  r resign  q quit},
   'and the take is offered beside them');
is($term->move_for($defend, "4\n"), undef, q{a card that does not beat is not a move});
is($term->move_for($defend, "2\n")->{kind}, q{beat}, q{one that does is});
is($term->move_for($defend, "t\n")->{kind}, 'take', 'and t is the take');

# The exchange.
my $swap = game_with(
    trump    => 'H',
    attacker => 1,
    hand1    => [qw(6H 8S 9S TS)],
    hand2    => [qw(7C 8C 9C TC)],
    talon    => [qw(7D 8D AH)],
);
my $swap_view = $swap->view(1);
like($term->prompt_for($swap_view), qr/x exchange/, 'the exchange is offered');
is($term->move_for($swap_view, "x\n")->{kind}, 'swap', 'and x makes it');

# Narration, from both sides of the table.
my ($teller, $told) = terminal();
$teller->narrate({ seat => 1 },
    { kind => 'attack', seat => 1, card => id_of('6S') },
    { kind => 'beat',   seat => 2, card => id_of('7S') },
    { kind => 'take',   seat => 2 },
    { kind => 'swap',   seat => 1 },
    { kind => 'bout_end', taken => 1, cards => 1, next_attacker => 1 },
    { kind => 'bout_end', taken => 0, cards => 4, next_attacker => 2 },
    { kind => 'refill', drawn => { 1 => 2, 2 => 0 }, talon => 9 },
    { kind => 'out', seat => 2 },
    { kind => 'game_end', outcome => 'fool', fool => 1, places => {} },
);

my @lines = grep { /\S/ } split /\n/, $$told;
is_deeply(\@lines, [
    '  you attack with six of spades',
    '  they beat it with seven of spades',
    '  they take the bout',
    '  you exchange the trump six',
    '  they pick up 1 card',
    '  the bout is beaten off, 4 cards',
    '  you draw 2, they draw 0, 9 left',
    '  they are out',
    '  you are the durak',
], 'every event reads as a sentence from seat one');

my ($other, $other_told) = terminal(seat => 2);
$other->narrate({ seat => 2 },
    { kind => 'attack', seat => 1, card => id_of('6S') },
    { kind => 'game_end', outcome => 'draw', fool => undef, places => {} },
);
like($$other_told, qr/they attack with six of spades/, 'and the other way round');
like($$other_told, qr/a draw, and no fool/, 'a drawn deal says so');

# A whole deal through run, with an input that always answers something.
my $said = join q{}, map { "$_\n" } ((1 .. 6, q{t}, q{d}, q{x}) x 120);
my ($player, $shown) = terminal(said => $said, seed => seed32('durak-terminal'), level => 3);
my $result = $player->run;

ok($result, 'the deal ended');
like($$shown, qr/durak: the loser is the fool/, 'the terminal introduced itself');
like($$shown, qr/trump is [SHDC], and seat [12] opens/, 'and said what the trump was');
like($$shown, qr/(you|they) are the durak|a draw, and no fool/,
     'and how it finished');
ok($player->game->over, 'the game is over');

done_testing();
