  use Test::Simple tests => 1;
  use Games::Poker::TexasHold'em;
  my $game = Games::Poker::TexasHold'em->new(
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

$game->blinds;
$game->check; $game->bet(10); $game->call; $game->fold;
$game->fold;
$game->next_stage();
$game->check; $game->bet(20);
$game->call;
ok($game->pot_square, "The pot is square after a second round of betting");

