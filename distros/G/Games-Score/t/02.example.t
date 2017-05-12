use Test::More tests => 1;

BEGIN { use_ok( 'Games::Score' ); }

# These two lines aren't actually needed, as these are the default values
Games::Score->default_score(0);
Games::Score->step_method('inc');

# Set the victory condition
Games::Score->victory_is( sub { $_[0] > 20; } );

# Set what to do on victory
our $game_ended = 0;
our $message = '';
Games::Score->on_victory_do( sub {
                                    $game_ended = 1;
                                    $message = "$_[1] has won!\n";
                                 } );

# Start two players, "Shiribi" and "Zuncucu"
my $player1 = Games::Score->new("Shiribi");
my $player2 = Games::Score->new("Zuncucu");
my @players = ($player1, $player2);

# And have a random game
until ($game_ended) {
  for (@players) {
    if (rand(1)) {
      $_->step();
      print "Player $_->name() scored and now has $_->score() point(s).\n";
      last if $_->has_won();
    }
    else {
      print "Player $_->name() didn't score.\n"
    }
  }
}

