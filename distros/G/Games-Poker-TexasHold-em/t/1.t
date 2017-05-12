use Test::More tests => 39;
use_ok("Games::Poker::TexasHold::em"); # Test::More slightly buggy here.
  my $game = Games::Poker::TexasHold'em->new( #'
        me => "lathos",
        players => [
            { name => "lathos", bankroll => 500 },
            { name => "MarcBeth", bankroll => 500 },
            { name => "Hectate", bankroll => 500 },
            { name => "RichardIII", bankroll => 500 },
        ],
        button => "Hectate",
        bet => 10,
        limit => 50
  );

isa_ok($game, "Games::Poker::TexasHold::em");
is_deeply([$game->players], [qw[lathos MarcBeth Hectate RichardIII]],
    "->players");
is($game->seat2name(2), "Hectate", "->seat2name");
is($game->{unfolded}, 4, "unfolded works");
$game->hole(1,2,3);
is_deeply([$game->hole()], [1,2,3], "Storing hole cards works");

is($game->next_to_play, "Hectate", "Hectate has the button");
is($game->bankroll("lathos"), 500, "bankroll by name");
is($game->bankroll(0), 500, "bankroll by number");
is($game->pot,0, "The pot is currently empty");
$game->blinds;
is($game->pot, 15, "The blinds were put in");
is($game->next_to_play, "Hectate", "Hectate still has the button");
is($game->bankroll("lathos"), 495, "lathos put in small blind");
is($game->bankroll("MarcBeth"), 490, "MarcBeth put in small blind");
is($game->in("lathos"), 5, "lathos is in to the tune of \$5");

is($game->next_to_play, "Hectate", "->next_to_play");
ok(!$game->folded("Hectate"), "Not folded yet");
ok(!$game->folded(2), "By seat number");
$game->fold;
ok($game->folded("Hectate"), "Folded OK");
is($game->next_to_play, "RichardIII", "Advanced to next player");
$game->_advance;
is($game->next_to_play, "lathos", "Wrap around on advance");
$game->_advance;
is($game->next_to_play, "MarcBeth", "Advanced to next player");
$game->_advance;
is($game->next_to_play, "RichardIII", "Skip folded players on advance");

# Now that was fun. Let's get on with the game

# It's RichardIII to play and he's down 10 due to large blinds
$game->check_call;
is($game->pot, 25, "10 went in");
is($game->bankroll("RichardIII"), 490, "From RichardIII's cash");
is($game->next_to_play, "lathos", "And it's lathos' go");

# lathos put in small blinds, so calls up 5
is($game->check_call, 5, "lathos checked");
is($game->pot, 30, "Call");
is($game->next_to_play, "MarcBeth", "Marc's turn");

# Big blinds == check
is($game->check_call, 0, "MarcBeth called to small blinds");
is($game->pot, 30, "Check");
is($game->next_to_play, "RichardIII", "Back to Richard");

ok($game->pot_square, "We're all done");

# Let's move on.
$game->next_stage("Test", "board");
is(join(" ",$game->board), "Test board", "board function works");
is($game->stage, "flop", "We're now in the flop");

is($game->check, 0, "Richard checks");
is($game->bet_raise(), 10, "lathos chucks in 10");
is($game->bet_raise(15), 15, "MarcBeth sees 10, raises 5");
is($game->status, <<'EOF', "Status works");
Pot: 55 Stage: flop
?                 Name Bankroll  InPot
                lathos $  480 $   20
              MarcBeth $  475 $   25
F              Hectate $  500 $    0
*           RichardIII $  490 $   10
EOF
