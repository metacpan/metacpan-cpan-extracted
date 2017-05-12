use Test::More tests => 138;

BEGIN { use_ok( 'Games::Score' ); }

my     $player1 = Games::Score->new();

is  (  $player1->name(), Games::Score->default_name());
isnt(  $player1->name(), 'UGH');
is  (  $player1->name('UGH'), 'UGH');
is  (  $player1->name(), 'UGH');
isnt(  $player1->name(), Games::Score->default_name());

is  (  Games::Score->default_name('WARRIOR'),'WARRIOR');

my     $default_score = Games::Score->default_score();
is  (  $player1->score(), $default_score);
is  (  $player1->score(10), 10);
is  (  $player1->score(), 10);
is  (  $player1->score($default_score), $default_score);

is  (  Games::Score::default_score(10), 10);

my     $player2 = Games::Score->new();
is  (  $player2->name(), 'WARRIOR');
is  (  $player2->score(), 10);

my     $default_step = Games::Score->default_step();
is  (  $player1->step(), $default_step);
is  (  $player1->step(), $default_step * 2);
is  (  $player1->step(2), $default_step * 4);

my     $step_method = Games::Score->step_method();
is  (  Games::Score->step_method('inc'), 'inc');
is  (  Games::Score->step_method('dec'), 'dec');
is  (  Games::Score->step_method($step_method), $step_method);
isnt(  Games::Score->step_method('not'), 'not');
is  (  Games::Score->step_method('not'), $step_method);

my     $current_score = $player1->score();
       $current_score = $player1->score();
is  (  $player1->add(2), $current_score + 2);
       $current_score = $player1->score();
is  (  $player1->add(2,3,4), $current_score + 2 + 3 + 4);

       $current_score = $player1->score();
is  (  $player1->subtract(3), $current_score - 3);
       $current_score = $player1->score();
is  (  $player1->subtract(1,2,3), $current_score - 1 - 2 - 3);

ok  (  Games::Score->victory_is( sub { $_[0] >= 20 } ));
ok  (! Games::Score->victory_is( 0 ));
ok  (! Games::Score->victory_is());

ok  (  Games::Score->defeat_is( sub { $_[0] < 0 } ));
ok  (! Games::Score->defeat_is( 0 ));
ok  (! Games::Score->defeat_is());

is  (  $player1->score(10), 10);
ok  (! $player1->has_won());
ok  (  $player1->is_ok());
is  (  $player1->score(20), 20);
ok  (  $player1->has_won());
ok  (! $player1->is_ok());
is  (  $player1->score(30), 30);
ok  (  $player1->has_won());
ok  (! $player1->is_ok());

is  (  $player1->score(10), 10);
ok  (! $player1->has_lost());
ok  (  $player1->is_ok());
is  (  $player1->score(0), 0);
ok  (! $player1->has_lost());
ok  (  $player1->is_ok());
is  (  $player1->score(-10), -10);
ok  (  $player1->has_lost());
ok  (! $player1->is_ok());

is  (  $player1->score(10), 10);
ok  (  Games::Score->invalidate_if( sub { $_[0] < 0 } ));
ok  (! Games::Score->invalidate_if( 0 ));
ok  (! Games::Score->invalidate_if());

ok  (  Games::Score->invalidate_if( sub { $_[0] > 20 } ));
is  (  $player1->score(18), 18);
is  (  $player1->add(1,2,1), 19);
is  (  $player1->add(-2), 17);

ok  (  Games::Score->invalidate_if( sub { $_[0] < 0 } ));
is  (  $player1->score(2), 2);
is  (  $player1->subtract(1,2,1), 1);
is  (  $player1->subtract(-2), 3);

our    $value = 0;
is  (  $player1->score(15), 15);
ok  (  Games::Score->victory_is( sub { $_[0] > 20 } ));
ok  (  Games::Score->invalidate_if( sub { } ));
ok  (  Games::Score->on_victory_do( sub { $value = 1 } ));
is  (  $player1->score(15), 15);
ok  (! $value);
is  (  $player1->score(25), 25);
ok  (  $value);
       $value = 0;
is  (  $player1->score(15), 15);
is  (  $player1->add(6), 21);
ok  (  $value);

       $value = 0;
is  (  $player1->score(15), 15);
ok  (  Games::Score->defeat_is( sub { $_[0] < 0 } ));
ok  (  Games::Score->invalidate_if( sub { } ));
ok  (  Games::Score->on_defeat_do( sub { $value = 1 } ));
is  (  $player1->score(5), 5);
ok  (! $value);
is  (  $player1->score(-1), -1);
ok  (  $value);
       $value = 0;
is  (  $player1->score(5), 5);
is  (  $player1->subtract(6), -1);
ok  (  $value);

is  (  Games::Score->priority_is('win'), 'win');
is  (  Games::Score->priority_is('lose'), 'lose');
is  (  Games::Score->priority_is('win_lose'), 'win_lose');
is  (  Games::Score->priority_is('lose_win'), 'lose_win');
isnt(  Games::Score->priority_is(''), '');
is  (  Games::Score->priority_is(''), 'lose_win');

my     $value1 = 0;
my     $value2 = 0;
is  (  $player1->score(15), 15);
ok  (  Games::Score->victory_is( sub { $_[0] == 10 } ));
ok  (  Games::Score->defeat_is( sub { $_[0] == 10 } ));
ok  (  Games::Score->on_victory_do( sub { $value1 = 1 } ));
ok  (  Games::Score->on_defeat_do( sub { $value2 = 1 } ));
ok  (  Games::Score->invalidate_if( sub { } ));
ok  (! $value1);
ok  (! $value2);

       $value1 = 0;
       $value2 = 0;
is  (  Games::Score->priority_is('win'), 'win');
is  (  $player1->score(10), 10);
ok  (  $value1);
ok  (! $value2);

       $value1 = 0;
       $value2 = 0;
is  (  Games::Score->priority_is('lose'), 'lose');
is  (  $player1->score(10), 10);
ok  (! $value1);
ok  (  $value2);

       $value1 = 0;
       $value2 = 0;
is  (  Games::Score->priority_is('lose_win'), 'lose_win');
is  (  $player1->score(10), 10);
ok  (  $value1);
ok  (  $value2);

       $value1 = 0;
       $value2 = 0;
is  (  Games::Score->priority_is('lose_win'), 'lose_win');
is  (  $player1->score(10), 10);
ok  (  $value1);
ok  (  $value2);

       $value = 1;
       $value1 = 0;
       $value2 = 0;
is  (  $player1->score(15), 15);
ok  (  Games::Score->victory_is( sub { $_[0] == 10 } ));
ok  (  Games::Score->defeat_is( sub { $_[0] == 10 } ));
ok  (  Games::Score->on_victory_do( sub { $value1 = ++$value } ));
ok  (  Games::Score->on_defeat_do( sub { $value2 = ++$value } ));
ok  (  Games::Score->invalidate_if( sub { } ));
is  (  Games::Score->priority_is('win_lose'), 'win_lose');
is  (  $player1->score(10), 10);
ok  (  $value1);
ok  (  $value2);
is  (  $value1, 2);
is  (  $value2, 3);

       $value = 1;
       $value1 = 0;
       $value2 = 0;
is  (  $player1->score(15), 15);
ok  (  Games::Score->victory_is( sub { $_[0] == 10 } ));
ok  (  Games::Score->defeat_is( sub { $_[0] == 10 } ));
ok  (  Games::Score->on_victory_do( sub { $value1 = ++$value } ));
ok  (  Games::Score->on_defeat_do( sub { $value2 = ++$value } ));
ok  (  Games::Score->invalidate_if( sub { } ));
is  (  Games::Score->priority_is('lose_win'), 'lose_win');
is  (  $player1->score(10), 10);
ok  (  $value1);
ok  (  $value2);
is  (  $value1, 3);
is  (  $value2, 2);
