use Test::More tests => 39;

BEGIN { use_ok( 'Games::Score' ); }

my     $player1 = Games::Score->new();
my     $player2 = Games::Score->new('CRASH');
my     $player3 = Games::Score->new('TEMPEST', 10);
my     $player4 = Games::Score->new('Zimboxo', 15, 'XPTO');

my     $default_name = Games::Score->default_name();
is  (  $player1->name(), $default_name);
is  (  $player2->name(), 'CRASH');
is  (  $player3->name(), 'TEMPEST');
is  (  $player4->name(), 'Zimboxo');

my     $default_score = Games::Score->default_score();
is  (  $player1->score(), $default_score);
is  (  $player2->score(), $default_score);
is  (  $player3->score(), 10);
is  (  $player4->score(), 15);

is  (  $player1->score(10), 10);
is  (  $player1->score(10, 20), 20);

my     $default_step = Games::Score->default_step();
is  (  Games::Score->default_step(10), 10);
is  (  Games::Score->default_step(10, 20), 20);

is  (  $player1->score(0), 0);
is  (  Games::Score->default_step(1), 1);
is  (  $player1->step(), 1);
is  (  $player1->step(2), 3);
is  (  $player1->step(2, 1), 5);

my     $step_method = Games::Score->step_method();
is  (  Games::Score->step_method('inc','dec'), 'inc');
is  (  Games::Score->step_method('xpto','dec'), 'dec');

is  (  $player1->score(0), 0);
is  (  $player1->add(), 0);
is  (  $player1->subtract(), 0);

ok  (! Games::Score->victory_is());
ok  (! Games::Score->defeat_is());

ok  (! $player1->has_won());
ok  (! $player1->has_won(1));
ok  (! $player1->has_lost());
ok  (! $player1->has_lost(1));
ok  (  $player1->is_ok());
ok  (  $player1->is_ok(1));

ok  (! Games::Score->invalidate_if());
ok  (! Games::Score->on_victory_do());
ok  (! Games::Score->on_defeat_do());

ok  (  Games::Score->priority_is('xpto'));
is  (  Games::Score->priority_is('lose', 'win'), 'lose');

ok  (! Games::Score->on_victory_do());
ok  (! Games::Score->on_defeat_do());
ok  (! Games::Score->invalidate_if());
