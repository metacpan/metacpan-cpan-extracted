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

# THE TWO LEVEL NUMBERS ARE DIFFERENT AND BOTH ARE PUBLIC. `levels` is the
# engine's three rungs; `ladder` is the five a consumer may offer, which
# `level_for` maps onto those three. Checking a --level against the wrong one
# is wrong in both directions and silent in both: `level_for` CLAMPS instead
# of dying, so a bad range quietly refuses a documented level, and no range at
# all quietly hands level nine the top rung. bin/durak did the second, and
# then, for about a minute, the first.
subtest 'the ladder a consumer offers is not the engine rung count' => sub {
    isnt(Game::Durak::Bot->ladder, Game::Durak::Bot->levels,
        'the two numbers really are different');
    is(Game::Durak::Bot->ladder, 5, 'five levels face a consumer');
    is(Game::Durak::Bot->levels, 3, 'and three rungs are behind them');

    # Every level a consumer may offer maps to a real rung, and the top and
    # bottom of the ladder are not the same rung, or the ladder is decorative.
    my @rung = map { Game::Durak::Bot->level_for($_) } 1 .. Game::Durak::Bot->ladder;
    is(scalar(grep { $_ >= 1 && $_ <= Game::Durak::Bot->levels } @rung),
        Game::Durak::Bot->ladder, 'each one lands on a rung that exists');
    isnt($rung[0], $rung[-1], 'and the ladder is not flat');
};

subtest 'q and quit both stop' => sub {
    my ($t) = terminal();
    $t->game($game);
    my $view = $game->view(1);

    for my $word (qw/ q Q quit QUIT /) {
        my $move = $t->move_for($view, $word);
        is(ref $move eq 'HASH' ? $move->{kind} : '', 'quit', "'$word' stops");
    }

    # And a word that is not an answer is still refused, or the above proves
    # nothing about the parser.
    is($t->move_for($view, 'zzz'), undef, 'while nonsense is not a move');
};

# AND THE RANGE bin/durak ACTUALLY TAKES, which is where the bug was. The
# subtest above pins the two numbers apart in the API; this one pins the
# script against the right one.
#
# NO SHELL. Game-Checkers 0.01 failed on a Strawberry smoker in the one file
# that ran its script as a process, because `sh` had been quietly stripping
# quotes, running `printf` and resolving /dev/null. Handles are pointed at
# files and the spawn is a LIST, which bypasses the shell on both platforms.
subtest 'bin/durak takes the levels it documents and refuses the rest' => sub {
    my $script = 'bin/durak';
    plan skip_all => 'not run from the distribution root' unless -f $script;

    require File::Temp;
    require File::Spec;

    my $ladder = Game::Durak::Bot->ladder;

    for my $case ([ 1, 0 ], [ $ladder, 0 ], [ $ladder + 1, 2 ], [ 0, 2 ]) {
        my ($level, $want) = @$case;

        my ($null_fh, $null) = File::Temp::tempfile(UNLINK => 1);
        close $null_fh;
        my ($out_fh, $out) = File::Temp::tempfile(UNLINK => 1);
        close $out_fh;

        my $status = do {
            open my $save_in,  '<&', \*STDIN  or die $!;
            open my $save_out, '>&', \*STDOUT or die $!;
            open my $save_err, '>&', \*STDERR or die $!;
            open STDIN,  '<', $null or die $!;
            open STDOUT, '>', $out  or die $!;
            open STDERR, '>&', \*STDOUT or die $!;

            my $rc = system $^X, '-Ilib', $script,
                '--level', $level, '--seed', 'levelcheck';

            open STDIN,  '<&', $save_in  or die $!;
            open STDOUT, '>&', $save_out or die $!;
            open STDERR, '>&', $save_err or die $!;
            $rc;
        };

        is($status >> 8, $want, "--level $level exits $want");
    }
};

# The key loop, driven by `keysource` so nothing here needs a tty or
# Term::ReadKey. ONE character a call: a source handing back "\e[C" whole
# never becomes a right arrow.
sub picker {
    my ($keys, %o) = @_;
    my @chars = split //, $keys;
    my ($t, $shown) = terminal(
        paint => 0, picking => 1, keysource => sub { shift @chars }, %o);
    return ($t, $shown);
}

subtest 'a key at a time, named' => sub {
    my ($t) = picker("k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");

    my @got;
    while (defined(my $key = $t->read_key)) {
        push @got, $key eq ' ' ? 'space' : $key;
    }

    is_deeply(\@got, [ qw/ k up down right left page_up home enter tab backspace
        interrupt eof space q escape page_down / ],
        'a character comes back as itself and a sequence as a name');
};

subtest 'an escape does not eat the key behind it' => sub {
    my ($t) = picker("\eq");
    is($t->read_key, 'escape', 'the escape is an escape');
    is($t->read_key, 'q', 'and the keystroke behind it survives');
};

# THE CURSOR WALKS THE PLAYABLE CARDS AND NOTHING ELSE. In Durak most of a
# hand is unplayable most of the time: an attack is capped by rank, a defence
# by what is on the table. A cursor crawling the whole hand would sit mostly
# on cards that refuse, and those are already the ones the prompt does not
# list.
subtest 'the cursor walks only the cards that play' => sub {
    my $g = game_with(
        trump    => 'H',
        attacker => 1,
        hand1    => [qw(9S 8S TS KH)],
        hand2    => [qw(6S 7S JS QS KC)],
        talon    => [qw(7C 8C AH)],
    );
    $g->apply(1, { kind => 'attack', card => id_of('9S') });

    my $v = $g->view(2);
    my ($t, $shown) = picker("\e[C\e[C\e[Cq");
    $t->game($g);

    my $playable = $t->playable($v);
    cmp_ok(scalar @$playable, '>', 0, 'something can be played');
    cmp_ok(scalar @$playable, '<', scalar @{ $v->{hand} },
        'but NOT the whole hand, or this proves nothing');

    $t->enter_raw;
    $t->pick_move($v);

    my @named = $$shown =~ /^\s+(\S+): /mg;
    my %legal = map { $t->card($_->{card}) => 1 }
        grep { defined $_->{card} } @{ $v->{legal} };
    my @wrong = grep { !$legal{$_} } @named;

    cmp_ok(scalar @named, '>', 1, 'the cursor visited more than one card');
    is_deeply(\@wrong, [], 'and every card it visited was one that plays')
        or diag "visited: @named";
};

# THE LINE ABOVE THE TABLE IS WHAT THE CARD WOULD DO, and both halves come
# from the view the engine already handed over: the bout's cap and unbeaten
# attack, and the trump.
subtest 'the line says what the card would do' => sub {
    my $g = game_with(
        trump    => 'H',
        attacker => 1,
        hand1    => [qw(6S 8S TS KH)],
        hand2    => [qw(7S 9S JS QS)],
        talon    => [qw(7C 8C AH)],
    );

    my ($t) = picker('q');
    $t->game($g);
    my $v = $g->view(1);

    like($t->card_line($v, id_of('6S')), qr/they must beat it/,
        'an attack says the defender must answer it');
    like($t->card_line($v, id_of('KH')), qr/a trump/,
        'and a trump is called one, because that is what it costs');
    unlike($t->card_line($v, id_of('6S')), qr/a trump/,
        'while a plain card is not');

    # Now defend, and the line names the card it answers.
    $g->apply(1, { kind => 'attack', card => id_of('6S') });
    my $d = $g->view(2);
    my ($beats) = grep { $_->{kind} eq 'defend' } @{ $d->{legal} };
    SKIP: {
        skip 'nothing beats it in this fixture', 1 unless $beats;
        like($t->card_line($d, $beats->{card}),
            qr/beats the \Q@{[ $t->card(id_of('6S')) ]}\E/,
            'a defence names the attack it answers');
    }
};

subtest 'the cursor is a mark, not a colour' => sub {
    my $g = game_with(
        trump    => 'H',
        attacker => 1,
        hand1    => [qw(6S 8S TS KH)],
        hand2    => [qw(7S 9S JS QS)],
        talon    => [qw(7C 8C AH)],
    );
    my ($t) = picker('q');
    $t->game($g);
    my $v = $g->view(1);

    # Plain lines: the marker takes the place of a space.
    my $plain = $t->hand_line($v->{hand}, 2);
    like($plain, qr/>2\)/, 'the cursor card is marked in the plain hand');
    unlike($t->hand_line($v->{hand}), qr/>/,
        'and a hand with no cursor is drawn exactly as it was');

    # Painted: the card is ringed, reusing the ring the table already draws
    # round an unanswered attack.
    my $table = Game::Durak::Table->new(width => 80, height => 24, ascii => 1);
    my $with  = join "\n", @{ $table->lines($table->screen($v, cursor => 2)) };
    my $without = join "\n", @{ $table->lines($table->screen($v)) };

    like($with, qr/\+===/, 'the painted cursor card is ringed');
    unlike($without, qr/\+===\+---/, 'and nothing is ringed without one');

    # BOTH WITH NO COLOUR AT ALL, so they survive --ascii, NO_COLOR and a pipe.
    is($t->_colour, 0, 'with colour off throughout');
};

subtest 'the keys that are not cards, and the ones that stop' => sub {
    my $g = game_with(
        trump    => 'H',
        attacker => 1,
        hand1    => [qw(6S 8S TS KH)],
        hand2    => [qw(7S 9S JS QS)],
        talon    => [qw(7C 8C AH)],
    );
    $g->apply(1, { kind => 'attack', card => id_of('6S') });

    my ($take) = picker('t');
    $take->game($g);
    $take->enter_raw;
    my $move = $take->pick_move($g->view(2));
    is($move->{kind}, 'take', 't takes');

    my ($stop) = picker('q');
    $stop->game($g);
    $stop->enter_raw;
    is($stop->pick_move($g->view(2))->{kind}, 'quit', 'q stops');

    my ($dud, $said) = picker('zq');
    $dud->game($g);
    $dud->enter_raw;
    $dud->pick_move($g->view(2));
    like($$said, qr/that key does nothing here/, 'and a dud key says so');
};

# Without Term::ReadKey and without a keysource there is nothing to read keys
# with, and the fallback is the typed prompt rather than a failure.
subtest 'no key source at all falls back to typing' => sub {
    my ($t, $said) = terminal(said => "q\n", paint => 0, picking => 1,
        seed => seed32('fall'), level => 1, seat => 1);
    is($t->keys_available, 0, 'nothing to read keys with');
    $t->run;
    like($$said, qr/a card/, 'so the typed prompt was printed');
    is($t->picking, 0, 'and it does not try the keys again');
};

done_testing();
