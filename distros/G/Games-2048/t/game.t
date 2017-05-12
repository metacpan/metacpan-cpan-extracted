use 5.012;
use strictures;
use Test::More;
use Games::2048;
use Storable qw/dclone/;

my $game = Games::2048::Game->new;
my $small_game = Games::2048::Game->new(size => 2);
my $big_game = Games::2048::Game->new(size => 7);

isa_ok $game, "Games::2048::Grid", "game";
isa_ok $small_game, "Games::2048::Grid", "small_game";
isa_ok $big_game, "Games::2048::Grid", "big_game";

ok $game->version, "Game version isn't 0";
ok $game->is_valid, "Game is valid";

sub create_game {
	my %options = @_;
	my $tiles = delete $options{tiles};
	my $move_tiles = delete $options{move_tiles};

	my $game = Games::2048::Game->new(%options);
	my $i = 0;
	for my $cell ($game->each_cell) {
		my $tile = $tiles->[$i++];
		$game->insert_tile($cell, $tile) if $tile;
	}
	$game->move_tiles($move_tiles) if $move_tiles;
	$game;
}

sub tiles_are {
	my ($got, $expected, $message) = @_;
	for my $game ($got, $expected) {
		$game = [ map $_->value, $game->each_tile ];
	}
	is_deeply $got, $expected, $message;
}

tiles_are $game, create_game(size => 4), "game empty";
tiles_are $small_game, create_game(size => 2), "small_game empty";
tiles_are $big_game, create_game(size => 7), "big_game empty";

$small_game->insert_random_tile;
is scalar $small_game->available_cells, 3, "small_game insert random tile once";

$small_game->insert_random_tile;
$small_game->insert_random_tile;

is scalar $small_game->available_cells, 1, "small_game insert random tile twice more";

$small_game->insert_random_tile;

ok !$small_game->has_available_cells, "small_game insert final random tile";

my $small_game_copy = dclone ($small_game);
$small_game->insert_random_tile for 1..10;

tiles_are $small_game, $small_game_copy, "small_game insert random tile does nothing when full";

{
	my $game1 = Games::2048::Game->new(insert_tiles_on_start => 7);
	my $game2 = Games::2048::Game->new(insert_tiles_on_start => 7);

	for ($game1, $game2) {
		srand 0;
		$_->insert_start_tiles(7);
	}

	is scalar $game1->available_cells, 9, "game1 available tiles after inserting start tiles";
	is scalar $game2->available_cells, 9, "game2 available tiles after inserting start tiles";
	tiles_are $game1, $game2, "game1 and game2 inserted tiles the same";
}

### Move tiles RIGHT ###
          $game= create_game(tiles => [1,0,0,0 , 0,1,0,0 , 0,0,1,0 , 0,0,0,1], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,0,1 , 0,0,0,1 , 0,0,0,1 , 0,0,0,1]), "L sliding with 1 tile in each row";

          $game= create_game(tiles => [1,2,0,0 , 2,0,1,0 , 1,0,0,2 , 0,0,2,1], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,1,2 , 0,0,2,1 , 0,0,1,2 , 0,0,2,1]), "L sliding with 2 tiles in each row";

          $game= create_game(tiles => [1,2,1,0 , 2,0,1,2 , 1,2,0,1 , 0,2,1,2], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,1,2,1 , 0,2,1,2 , 0,1,2,1 , 0,2,1,2]), "L sliding with 3 tiles in each row";

          $game= create_game(tiles => [0,0,0,0 , 1,2,1,2 , 2,1,2,1 , 1,3,2,4], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,0,0 , 1,2,1,2 , 2,1,2,1 , 1,3,2,4]), "L sliding with full/empty rows";

          $game= create_game(tiles => [0,0,1,1 , 2,0,0,2 , 1,1,0,0 , 2,0,2,0], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,0,2 , 0,0,0,4 , 0,0,0,2 , 0,0,0,4]), "L 2 tile merges";

          $game= create_game(tiles => [0,2,1,1 , 4,0,2,2 , 1,1,2,0 , 2,2,0,4], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,2,2 , 0,0,4,4 , 0,0,2,2 , 0,0,4,4]), "L 2 tile merges with extra mess";

          $game= create_game(tiles => [1,0,1,2 , 4,2,0,2 , 2,1,1,0 , 4,2,2,4], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,2,2 , 0,0,4,4 , 0,0,2,2 , 0,4,4,4]), "L more 2 tile merges";

          $game= create_game(tiles => [1,1,1,0 , 0,2,2,2 , 1,1,1,2 , 4,2,2,2], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,1,2 , 0,0,2,4 , 0,1,2,2 , 0,4,2,4]), "L 3 in a row merges";

          $game= create_game(tiles => [1,1,2,2 , 1,1,1,1 , 2,2,1,1 , 2,2,2,2], move_tiles => [1, 0]);
tiles_are $game, create_game(tiles => [0,0,2,4 , 0,0,2,2 , 0,0,4,2 , 0,0,4,4]), "L double merges";

### Move tiles LEFT ###
          $game= create_game(tiles => [1,0,0,0 , 0,1,0,0 , 0,0,1,0 , 0,0,0,1], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [1,0,0,0 , 1,0,0,0 , 1,0,0,0 , 1,0,0,0]), "R sliding with 1 tile in each row";

          $game= create_game(tiles => [1,2,0,0 , 2,0,1,0 , 1,0,0,2 , 0,0,2,1], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [1,2,0,0 , 2,1,0,0 , 1,2,0,0 , 2,1,0,0]), "R sliding with 2 tiles in each row";

          $game= create_game(tiles => [1,2,1,0 , 2,0,1,2 , 1,2,0,1 , 0,2,1,2], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [1,2,1,0 , 2,1,2,0 , 1,2,1,0 , 2,1,2,0]), "R sliding with 3 tiles in each row";

          $game= create_game(tiles => [0,0,0,0 , 1,2,1,2 , 2,1,2,1 , 1,3,2,4], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [0,0,0,0 , 1,2,1,2 , 2,1,2,1 , 1,3,2,4]), "R sliding with full/empty rows";

          $game= create_game(tiles => [0,0,1,1 , 2,0,0,2 , 1,1,0,0 , 2,0,2,0], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [2,0,0,0 , 4,0,0,0 , 2,0,0,0 , 4,0,0,0]), "R 2 tile merges";

          $game= create_game(tiles => [0,2,1,1 , 4,0,2,2 , 1,1,2,0 , 2,2,0,4], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [2,2,0,0 , 4,4,0,0 , 2,2,0,0 , 4,4,0,0]), "R 2 tile merges with extra mess";

          $game= create_game(tiles => [1,0,1,2 , 4,2,0,2 , 2,1,1,0 , 4,2,2,4], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [2,2,0,0 , 4,4,0,0 , 2,2,0,0 , 4,4,4,0]), "R more 2 tile merges";

          $game= create_game(tiles => [1,1,1,0 , 0,2,2,2 , 1,1,1,2 , 4,2,2,2], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [2,1,0,0 , 4,2,0,0 , 2,1,2,0 , 4,4,2,0]), "R 3 in a row merges";

          $game= create_game(tiles => [1,1,2,2 , 1,1,1,1 , 2,2,1,1 , 2,2,2,2], move_tiles => [-1, 0]);
tiles_are $game, create_game(tiles => [2,4,0,0 , 2,2,0,0 , 4,2,0,0 , 4,4,0,0]), "R double merges";

### Move tiles DOWN ###
$game = create_game(tiles => [
	1,0,2,1 ,
	0,0,1,0 ,
	0,1,2,0 ,
	0,2,0,2 ,
], move_tiles => [0, 1]);
tiles_are $game, create_game(tiles => [
	0,0,0,0 ,
	0,0,2,0 ,
	0,1,1,1 ,
	1,2,2,2 ,
]), "D different slides";

$game = create_game(tiles => [
	2,2,1,1 ,
	0,2,1,1 ,
	1,2,2,1 ,
	1,4,2,1 ,
], move_tiles => [0, 1]);
tiles_are $game, create_game(tiles => [
	0,0,0,0 ,
	0,2,0,0 ,
	2,4,2,2 ,
	2,4,4,2 ,
]), "D different merges";

### Move tiles UP ###
$game = create_game(tiles => [
	0,0,2,1 ,
	0,1,0,0 ,
	0,0,1,2 ,
	0,0,2,0 ,
], move_tiles => [0, -1]);
tiles_are $game, create_game(tiles => [
	0,1,2,1 ,
	0,0,1,2 ,
	0,0,2,0 ,
	0,0,0,0 ,
]), "D different slides";

$game = create_game(tiles => [
	0,2,2,1 ,
	2,2,1,0 ,
	1,4,1,1 ,
	1,0,2,1 ,
], move_tiles => [0, -1]);
tiles_are $game, create_game(tiles => [
	2,4,2,2 ,
	2,4,2,1 ,
	0,0,2,0 ,
	0,0,0,0 ,
]), "D different merges";

### Move and Moves Remaining ###

$game = create_game(tiles => [
	0,0,0,0 ,
	0,0,0,0 ,
	0,0,0,0 ,
	0,0,0,1 ,
]);

ok !$game->move_tiles([1, 0]), "Can't move mostly empty board right";
ok !$game->move_tiles([0, 1]), "Can't move mostly empty board down";

ok $game->move_tiles([-1, 0]), "Can move mostly empty board left";
ok $game->move_tiles([1, 0]), "Can move mostly empty board back right";

ok $game->move_tiles([0, -1]), "Can move mostly empty board up";
ok $game->move_tiles([0, 1]), "Can move mostly empty board back down";

ok $game->has_moves_remaining, "Mostly empty board has moves remaining";

$game = create_game(tiles => [
	5,7,5,7 ,
	7,5,7,5 ,
	5,7,5,7 ,
	7,5,7,0 ,
]);

ok !$game->move_tiles([-1, 0]), "Can't move left";
ok !$game->move_tiles([0, -1]), "Can't move up";

ok $game->move_tiles([1, 0]), "Can move right";
ok $game->move_tiles([-1, 0]), "Can move back left";

ok $game->move_tiles([0, 1]), "Can move down";
ok $game->move_tiles([0, -1]), "Can move back up";

ok $game->has_moves_remaining, "Has moves remaining before insert";
$game->insert_random_tile;
ok !$game->has_moves_remaining, "No moves remaining after insert";

$game = create_game(tiles => [
	3,5,3,5 ,
	5,3,5,3 ,
	5,7,3,5 ,
	3,5,7,3 ,
]);
my $game2 = dclone $game;
my $game3 = dclone $game;

ok !$game->move_tiles([-1, 0]), "Can't move mergable board left";
ok !$game->move_tiles([1, 0]), "Can't move mergable board right";
ok $game->move_tiles([0, -1]), "Can move mergable board up";
ok $game2->move_tiles([0, 1]), "Can move mergable board down";

ok $game->has_moves_remaining, "Merged board has moves remaining";
ok $game3->has_moves_remaining, "Mergable board has moves remaining";

$game->insert_random_tile;
ok !$game->has_moves_remaining, "Merged board has no moves remaining after insert";

done_testing
