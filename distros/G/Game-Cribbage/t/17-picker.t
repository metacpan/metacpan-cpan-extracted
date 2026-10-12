use strict;
use warnings;
use utf8;
use Test::More;
use Encode ();

use Game::Cribbage::Terminal;
use Game::Cribbage::Board;
use Game::Cribbage::Play;
use Game::Cribbage::Deck::Card;

my $T = 'Game::Cribbage::Terminal';

sub make_card { Game::Cribbage::Deck::Card->new(@_) }

# ONE CHARACTER PER CALL, which is what the reader asks for and what makes an
# escape sequence testable: `read_sequence` has to ask three times for a single
# arrow key, and a source handing back whole keys would never reach the pushback
# branch that an escape followed by an ordinary character goes down.
sub keysource {
    my @chars;
    for my $k (@_) {
        push @chars,
            $k eq 'up'     ? ("\e", '[', 'A')
          : $k eq 'down'   ? ("\e", '[', 'B')
          : $k eq 'right'  ? ("\e", '[', 'C')
          : $k eq 'left'   ? ("\e", '[', 'D')
          : $k eq 'home'   ? ("\e", '[', 'H')
          : $k eq 'end'    ? ("\e", '[', 'F')
          : $k eq 'enter'  ? ("\r")
          : $k eq 'tab'    ? ("\t")
          : $k eq 'escape' ? ("\e")
          :                  split //, $k;
    }
    return sub { shift @chars };
}

# A board with a known hand for the player and a known count already laid down,
# so every assertion below is about a position written here rather than about
# whatever a shuffle produced.
sub board_with {
    my (%o) = @_;
    my $board = Game::Cribbage::Board->new();
    $board->add_player(name => 'Bot');
    $board->add_player(name => 'Player');
    $board->start_game();
    $board->set_crib_player('player1');

    $board->rounds->current_round->add_player_card(
        $board->players->[0], make_card(%$_)) for @{ $o{bot} || [] };
    $board->rounds->current_round->add_player_card(
        $board->players->[1], make_card(%$_)) for @{ $o{player} || [] };

    for my $laid (@{ $o{laid} || [] }) {
        $board->current_play->card('player1', make_card(%$laid));
    }
    return $board;
}

sub terminal {
    my ($board, @keys) = @_;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $t = $T->new(board => $board, out => $fh, picking => 1,
                    keysource => keysource(@keys));
    return ($t, \$out);
}

subtest 'the cursor stops only on a card that can legally be played' => sub {
    # The count stands at 25. Of the four cards held, only the ace and the 6 can
    # go on without passing 31, and a 10 and a king cannot.
    my $board = board_with(
        player => [ { suit => 'H', symbol => 'A' }, { suit => 'S', symbol => '10' },
                    { suit => 'D', symbol => '6' }, { suit => 'C', symbol => 'K' } ],
        laid   => [ { suit => 'H', symbol => 'K' }, { suit => 'S', symbol => '9' },
                    { suit => 'D', symbol => '6' } ],
    );
    my ($t) = terminal($board);

    is($board->current_play_score, 25, 'the fixture really does stand at 25');
    is_deeply($t->playable_cards('player2'), [ 1, 3 ],
              'only the ace and the 6 are stops');

    # AND THE ENGINE AGREES, asked the other way round. This is the check that
    # the list is the engine's answer and not a rule written twice: a hand-made
    # list of positions here would pass even if `playable_cards` swept the whole
    # hand and the engine disagreed.
    my $play = $board->current_play;
    my $cards = $board->get_hands->player2->cards;
    for my $i (1 .. 4) {
        my $refused = ref $play->test_card('player2', $cards->[$i - 1]) ? 1 : 0;
        my $stop = ($i == 1 || $i == 3) ? 1 : 0;
        is($refused, !$stop ? 1 : 0, "position $i: engine and cursor agree");
    }
};

subtest 'the caption is the engine-s score and not arithmetic done here' => sub {
    # Ten on the table, a 5 in hand: fifteen for two.
    my $fifteen = board_with(
        player => [ { suit => 'H', symbol => '5' } ],
        laid   => [ { suit => 'S', symbol => '10' } ],
    );
    my ($t) = terminal($fifteen);
    like($t->card_line('player2', 1), qr/takes the count to 15 for fifteen, pegging 2/,
         'fifteen is named, and so is what it pegs');

    # A pair.
    my $pair = board_with(
        player => [ { suit => 'H', symbol => '7' } ],
        laid   => [ { suit => 'S', symbol => '7' } ],
    );
    my ($p) = terminal($pair);
    like($p->card_line('player2', 1), qr/count to 14 for a pair, pegging 2/,
         'a pair is named');

    # A run of three.
    my $run = board_with(
        player => [ { suit => 'H', symbol => '4' } ],
        laid   => [ { suit => 'S', symbol => '2' }, { suit => 'D', symbol => '3' } ],
    );
    my ($r) = terminal($run);
    like($r->card_line('player2', 1), qr/count to 9 for a run of 3, pegging 3/,
         'a run is named with its length');

    # Thirty-one.
    my $pegged = board_with(
        player => [ { suit => 'H', symbol => 'A' } ],
        laid   => [ { suit => 'S', symbol => 'K' }, { suit => 'D', symbol => 'K' },
                    { suit => 'C', symbol => 'K' } ],
    );
    my ($g) = terminal($pegged);
    like($g->card_line('player2', 1), qr/count to 31 for thirty-one, pegging/,
         'thirty-one is named');

    # A card that scores nothing says so rather than saying nothing.
    my $quiet = board_with(
        player => [ { suit => 'H', symbol => '2' } ],
        laid   => [ { suit => 'S', symbol => '9' } ],
    );
    my ($q) = terminal($quiet);
    like($q->card_line('player2', 1), qr/count to 11, pegging nothing/,
         'and a card that pegs nothing says so');

    # A card that cannot be played is named as such rather than described.
    my $over = board_with(
        player => [ { suit => 'H', symbol => 'K' } ],
        laid   => [ { suit => 'S', symbol => 'K' }, { suit => 'D', symbol => 'K' },
                    { suit => 'C', symbol => '5' } ],
    );
    my ($o) = terminal($over);
    like($o->card_line('player2', 1), qr/cannot be played, it would take the count past 31/,
         'an unplayable card says why');
};

subtest 'the marks are box frames and not colours' => sub {
    # A MARK THAT IS A COLOUR IS GONE the moment the board is piped into a file,
    # and the suits are already spending colour on red against black. Three
    # things need marking at once while discarding, so there are three frames.
    my $board = board_with(
        player => [ { suit => 'H', symbol => '5' }, { suit => 'S', symbol => '6' },
                    { suit => 'D', symbol => '7' } ],
    );
    my ($t, $out) = terminal($board);
    my $cards = $board->get_hands->player2->cards;

    $$out = '';
    $t->render_player_cards($cards, 2, 5, 1, { 2 => 'double', 3 => 'heavy' });

    # DECODED ON PURPOSE. Terminal.pm has no `use utf8`, so its box characters
    # are bytes in the source and bytes on the handle, which is right for a
    # terminal and wrong for a regex written in characters: without this the
    # assertions below match nothing and pass for the wrong reason the moment
    # somebody writes them the other way round.
    my $drawn = Encode::decode('UTF-8', $$out);

    like($drawn, qr/\x{250c}\x{2500}+\x{2510}/, 'an ordinary card keeps the light frame');
    like($drawn, qr/\x{2554}\x{2550}+\x{2557}/, 'the cursor card is drawn double');
    like($drawn, qr/\x{250f}\x{2501}+\x{2513}/, 'a chosen card is drawn heavy');

    # And the three are different, which an assertion on each alone does not say.
    my %seen = map { $_ => 1 } $drawn =~ /([\x{250c}\x{2554}\x{250f}])/g;
    is(scalar keys %seen, 3, 'three distinct frames, not one glyph three times');
};

subtest 'step walks the ring in both directions and both axes' => sub {
    my ($t) = terminal(board_with());
    my @items = (1, 3, 4, 6);

    is($t->step(\@items, 0, 'right'), 1, 'right goes on');
    is($t->step(\@items, 0, 'down'),  1, '  and so does down, the hand being one row');
    is($t->step(\@items, 3, 'right'), 0, 'right from the last wraps');
    is($t->step(\@items, 0, 'left'),  3, 'and left from the first wraps back');
    is($t->step(\@items, 0, 'up'),    3, '  as does up');
    is($t->step(\@items, 2, 'home'),  0, 'home is the first');
    is($t->step(\@items, 2, 'end'),   3, 'and end the last');
    is($t->step(\@items, 2, 'tab'),   3, 'tab goes on like right');
};

subtest 'pick_card returns a position, and the other keys their own answers' => sub {
    my %hand = (
        player => [ { suit => 'H', symbol => 'A' }, { suit => 'S', symbol => '10' },
                    { suit => 'D', symbol => '6' }, { suit => 'C', symbol => 'K' } ],
        laid   => [ { suit => 'H', symbol => 'K' }, { suit => 'S', symbol => '9' },
                    { suit => 'D', symbol => '6' } ],
    );

    my ($first) = terminal(board_with(%hand), 'enter');
    is($first->pick_card('player2'), 1, 'enter takes the first playable card');

    my ($second) = terminal(board_with(%hand), 'right', 'enter');
    is($second->pick_card('player2'), 3, 'right steps to the next one that plays');

    # AND IT STEPS OVER THE TWO THAT DO NOT. Position 2 is a 10 and position 4 a
    # king, and at a count of 25 neither can go on; a cursor walking the hand
    # rather than the playable list would stop on them.
    my ($wrap) = terminal(board_with(%hand), 'right', 'right', 'enter');
    is($wrap->pick_card('player2'), 1, '  and wraps past them back to the first');

    my ($space) = terminal(board_with(%hand), ' ');
    is($space->pick_card('player2'), 1, 'space does what enter does');

    my ($quit) = terminal(board_with(%hand), 'q');
    is($quit->pick_card('player2'), 'quit', 'q quits');

    my ($go) = terminal(board_with(%hand), 'g');
    is($go->pick_card('player2'), 'go', 'g is a go');

    my ($bot) = terminal(board_with(%hand), 'b');
    is($bot->pick_card('player2'), 'bot', 'b asks the bot');
};

subtest 'a hand with nothing playable is a go without asking' => sub {
    # THE PICKER MUST NOT OFFER AN EMPTY CHOICE. At 30 with two kings in hand
    # there is no card to put the cursor on, and a loop that drew a frame round
    # $can->[0] would index an empty list and draw a frame round nothing.
    my $board = board_with(
        player => [ { suit => 'H', symbol => 'K' }, { suit => 'S', symbol => 'K' } ],
        laid   => [ { suit => 'H', symbol => 'K' }, { suit => 'S', symbol => 'K' },
                    { suit => 'D', symbol => '10' } ],
    );
    my ($t, $out) = terminal($board, 'enter');
    is($board->current_play_score, 30, 'the fixture stands at 30');
    is_deeply($t->playable_cards('player2'), [], '  and nothing can be played');
    is($t->pick_card('player2'), 'go', 'the picker answers go and reads no key');
    is($$out, '', '  and draws nothing at all');
};

subtest 'pick_discards takes two, and enter on a held card puts it back' => sub {
    my %six = (player => [ map { { suit => 'H', symbol => $_ } } qw(2 3 4 5 6 7) ]);

    my ($two) = terminal(board_with(%six), 'enter', 'right', 'enter');
    is_deeply($two->pick_discards, [ 1, 2 ], 'two cards chosen in order');

    my ($skip) = terminal(board_with(%six), 'right', 'right', 'enter', 'end', 'enter');
    is_deeply($skip->pick_discards, [ 3, 6 ], 'and the cursor reaches any of the six');

    # TAKING ONE BACK. Enter, enter on the same card, then two others: if the
    # first were still held the answer would carry it, so this is the assertion
    # that the toggle really releases.
    my ($back) = terminal(board_with(%six),
        'enter', 'enter', 'right', 'enter', 'right', 'enter');
    is_deeply($back->pick_discards, [ 2, 3 ], 'enter on a held card puts it back');

    my ($quit) = terminal(board_with(%six), 'q');
    is($quit->pick_discards, 'quit', 'q quits');

    my ($bot) = terminal(board_with(%six), 'b');
    is($bot->pick_discards, 'bot', 'b asks the bot');
};

subtest 'the two split prompts index the deck the same way' => sub {
    # 0.16 INDEXED THE DECK THREE DIFFERENT WAYS IN TWO METHODS. `split_cards`
    # took the player's card with `get($number - 1)` and the bot's with
    # `get($rand - 1)` against a 0-based `rand(52)`, so a rand of 0 reached
    # `get(-1)`, the LAST card in the deck; and `starter` took the player's card
    # with `get($number)`, one card along from the one they pointed at.
    # A DECK IN A KNOWN ORDER, so the two ends are two cards this test chose.
    # Deck::from_order numbers H S D C and A 2..10 J Q K, so id 1 is the ace of
    # hearts and id 52 the king of clubs.
    #
    # Position 0 is the ace, value 1. Position 51 is the king, value 10. The
    # player splits at 7, which is position 6, and that is the five. So with
    # rand pinned to 0 the dealer comes out one way if the bot drew the first
    # card of the deck and THE OTHER WAY if it drew the last, and `dealer` is
    # one bit that says which happened. A `like` over the drawn screen would
    # not: every rank appears somewhere on a board full of cards.
    my @order = (1, 2, 3, 4, 7, 6, 5, 8 .. 52);
    my $board = Game::Cribbage::Board->new();
    $board->add_player(name => 'Bot');
    $board->add_player(name => 'Player');
    $board->start_game();
    $board->deck->from_order(\@order);

    is($board->deck->get(0)->value,  1, 'position 0 is the ace');
    is($board->deck->get(6)->value,  5, 'position 6 is the five');
    is($board->deck->get(51)->value, 10, 'and position 51 the king');

    my $out = '';
    open my $w, '>', \$out or die $!;
    open my $r, '<', \"7\n" or die $!;

    # THE DRAW IS PINNED THROUGH THE SEAM AND NOT THROUGH CORE::GLOBAL::rand.
    # A `local *CORE::GLOBAL::rand` has to be in place before the code that
    # calls rand is COMPILED, and Terminal.pm is compiled by the `use` at the
    # top of this file; set here it does nothing at all, and this subtest then
    # passes or fails on the real draw. It passed twice and failed on the third
    # run, which is the only reason it was noticed.
    my $t = $T->new(board => $board, in => $r, out => $w, picking => 0);
    my $drew = 0;
    no warnings 'redefine';
    local *Game::Cribbage::Terminal::random_index = sub { $drew++; 0 };
    $t->split_cards;

    ok($drew, 'the draw really went through the seam this test pinned');

    is($t->dealer, 0, 'a rand of 0 draws the FIRST card of the deck, not the last');

    # And the starter is the card that was pointed at, not the next one along.
    my $s_out = '';
    open my $sw, '>', \$s_out or die $!;
    open my $sr, '<', \"7\n" or die $!;
    my $st = $T->new(board => $board, in => $sr, out => $sw, picking => 0);
    $st->dealer(0);
    $st->starter;
    is($st->starter_card->stringify, $board->deck->get(6)->stringify,
       'splitting at 7 turns the 7th card, not the 8th');

    # AND A NUMBER PAST THE END IS REFUSED RATHER THAN REACHED FOR. The deck at
    # the starter is what is LEFT after the deal and not 52, which is why this
    # fixture deals first: 0.16 checked against 52 either way, so a number
    # between the two fetched a card that is not there and the starter came
    # back undef.
    my $dealt = Game::Cribbage::Board->new();
    $dealt->add_player(name => 'Bot');
    $dealt->add_player(name => 'Player');
    $dealt->start_game();
    $dealt->set_crib_player('player1');
    $dealt->draw_hands();

    my $left = scalar @{ $dealt->deck->deck };
    cmp_ok($left, '<', 52, 'the deal really did take cards out of the deck');

    my $big_out = '';
    open my $bw, '>', \$big_out or die $!;
    my $answers = ($left + 1) . "\n3\n";
    open my $br, '<', \$answers or die $!;
    my $bt = $T->new(board => $dealt, in => $br, out => $bw, picking => 0);
    $bt->dealer(0);
    $bt->starter;
    is($bt->starter_card->stringify, $dealt->deck->get(2)->stringify,
       'a number past what is left is refused and the next answer taken');

    # WHEN THE BOT CUTS, IT CUTS THE WHOLE DECK. 0.16 wrote the remainder as
    # the literal 39 where forty cards are left, so the last card of the deck
    # could never be turned: one card in forty, which no amount of playing
    # would show you. Pinning the draw to the last index is the only way to
    # see it, and against the literal the card comes back as something else.
    my $asked;
    no warnings 'redefine';
    local *Game::Cribbage::Terminal::random_index = sub { $asked = $_[1]; $_[1] - 1 };

    my $cut_out = '';
    open my $cw, '>', \$cut_out or die $!;
    my $ct = $T->new(board => $dealt, out => $cw, picking => 0);
    $ct->dealer(1);
    $ct->starter;

    is($asked, $left, 'the bot is offered every card that is left');
    is($ct->starter_card->stringify, $dealt->deck->get($left - 1)->stringify,
       '  including the last one');
};

subtest 'test_card_score hands back the object test_card reduces' => sub {
    # `test_card` returned the total and threw the breakdown away, so a caller
    # could not tell a pair from a fifteen: both are two. The object is what the
    # caption needs, and `test_card` is now a wrapper over it, so the two cannot
    # drift apart.
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    $play->card('player1', make_card(suit => 'S', symbol => '7'));

    my $card = make_card(suit => 'H', symbol => '7');
    my $score = $play->test_card_score('player2', $card);
    my $total = $play->test_card('player2', $card);

    isa_ok($score, 'Game::Cribbage::Play::Score', 'test_card_score returns the object');
    is($score->total_score, $total, 'and its total is what test_card returns');
    is($score->pair, 1, '  with the pair that made it');
    ok(!$score->fifteen, '  and no fifteen, which the total alone cannot say');

    # The refusal still comes back the same way from both.
    my $full = Game::Cribbage::Play->new(next_to_play => 'player1');
    $full->card('player1', make_card(suit => 'S', symbol => 'K'));
    $full->card('player1', make_card(suit => 'D', symbol => 'K'));
    $full->card('player1', make_card(suit => 'C', symbol => 'K'));
    my $over = make_card(suit => 'H', symbol => 'K');
    isa_ok($full->test_card_score('player2', $over), 'Game::Cribbage::Error',
           'an unplayable card is an Error from test_card_score');
    isa_ok($full->test_card('player2', $over), 'Game::Cribbage::Error',
           '  and from test_card too');

    # NOTHING IS COMMITTED EITHER WAY, which is the whole point of a preview.
    is(scalar @{ $full->cards }, 3, 'the play still holds three cards');
};

subtest 'nothing in the module prints or reads outside the handles' => sub {
    # THIS IS WHAT MADE THE TERMINAL TESTABLE, and it is one grep rather than an
    # assertion about behaviour because the failure mode is a single stray
    # `print` reaching the real screen in the middle of somebody's test run.
    my $src = do {
        open my $fh, '<', 'lib/Game/Cribbage/Terminal.pm' or die $!;
        local $/;
        <$fh>;
    };
    ($src) = split /^__END__/m, $src;

    my @stdin = $src =~ /^(.*<STDIN>.*)$/mg;
    is_deeply(\@stdin, [], 'not one <STDIN> left in the code')
        or diag(join "\n", @stdin);

    # THE DRAWING CODE IS WHAT THIS IS ABOUT, so the scan stops at `run`.
    # `run` is the program's option parsing and it writes its usage and its
    # refusals to the real STDOUT and STDERR on purpose: there is no terminal
    # yet when a bad option is refused, and a usage line is not a board.
    # Everything before it draws, and all of that must go through `emit`.
    my ($drawing) = split /^sub run \{/m, $src;
    ok(length($drawing) < length($src), 'the scan really did stop at run');

    my @print = grep { !/print \{\$fh\}/ } $drawing =~ /^(.*\bprint\b.*)$/mg;
    is_deeply(\@print, [], 'every print in the drawing code goes through emit')
        or diag(join "\n", @print);
};

done_testing();
