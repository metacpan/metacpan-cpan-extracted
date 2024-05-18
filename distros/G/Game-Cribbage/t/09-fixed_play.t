use Test::More;

use Game::Cribbage::Player::Hand;

my @test = (
	{
		player1 => {
			name => 'Luck',
			dealt => [
				{
					suit => 'H',
					symbol => 'K'
				},
				{
					suit => 'D',
					symbol => 'K'
				},
				{
					suit => 'S',
					symbol => '10'
				},
				{
					suit => 'S',
					symbol => '5'
				},
				{
					suit => 'S',
					symbol => '3'
				},
				{
					suit => 'S',
					symbol => '4'
				}
			],
			discard => [4, 5],
			score => 8,
			fifteen => 3,
			pair => 1,
			three_of_a_kind => 0,
			four_of_a_kind => 0,
			run => 0,
			four_flush => 0,
			five_flush => 0,
			nobs => 0
		},
		player2 => {
			name => 'Robert',
			dealt => [
				{
					suit => 'S',
					symbol => 'A'
				},
				{
					suit => 'H',
					symbol => 'J'
				},
				{
					suit => 'H',
					symbol => 'Q'
				},
				{
					suit => 'D',
					symbol => 'Q'
				},
				{
					suit => 'C',
					symbol => 'Q'
				},
				{
					suit => 'S',
					symbol => '2'
				}
			],
			discard => [0, 1],
			score => 8,
			fifteen => 0,
			pair => 1,
			three_of_a_kind => 1,
			four_of_a_kind => 0,
			run => 0,
			four_flush => 0,
			five_flush => 0,
			nobs => 0
		},
		starter => {
			suit => 'H',
			symbol => 2
		},
		crib => {
			dealt => [
				{
					suit => 'S',
					symbol => '3'
				},
				{
					suit => 'S',
					symbol => '4'
				},
				{
					suit => 'S',
					symbol => 'A'
				},
				{
					suit => 'H',
					symbol => 'J'
				}
			]

		}
	},
);

use Game::Cribbage::Board;
use Game::Cribbage::Deck::Card;

for my $data (@test) {
	my $board = Game::Cribbage::Board->new();

	$board->add_player(name => $data->{player1}->{name});
	$board->add_player(name => $data->{player2}->{name});	

	$board->start_game();

	$board->set_crib_player('player2');

	my $player1 = $board->players->[0];
	for (@{$data->{player1}->{dealt}}) {
		$board->rounds->current_round->add_player_card(
			$player1,
			Game::Cribbage::Deck::Card->new(
				%{$_}
			)
		);
	}

	my $player2 = $board->players->[1];
	for (@{$data->{player2}->{dealt}}) {
		$board->rounds->current_round->add_player_card(
			$player2,
			Game::Cribbage::Deck::Card->new(
				%{$_}
			)
		);
	}

	my $current = $board->rounds->current_round->current_hands;

	my $p1 = join " | ", map {$_->stringify} @{$current->player1->cards};
	my $p2 = join " | ", map {$_->stringify} @{$current->player2->cards};
	
	is(scalar @{$current->player1->cards}, 6, 'player1 has 6 cards ' . $p1);
	is(scalar @{$current->player2->cards}, 6, 'player2 has 6 cards ' . $p2);

	ok($board->cribbed_cards($player1, @{$data->{player1}->{discard}}), 'player1 discards 2 cards');
	ok($board->cribbed_cards($player2, @{$data->{player2}->{discard}}), 'player2 discards 2 cards');

	$p1 = join " | ", map {$_->stringify} @{$current->player1->cards};
	$p2 = join " | ", map {$_->stringify} @{$current->player2->cards};
	my $c1 = join " | ", map {$_->stringify} @{$current->player1->crib};

	is(scalar @{$current->player1->cards}, 4, 'player1 now has 4 cards ' . $p1);
	is(scalar @{$current->player2->cards}, 4, 'player2 now has 4 cards ' . $p2);
	is(scalar @{$current->player2->crib}, 4, 'player2 has a crib of 4 cards ' . $c1);
	is(scalar @{$current->player1->crib}, 0, 'player1 should not have a crib');
	
	ok(1, 'Here we would allow splitting of the deck but for testing just use a default card');

	$board->rounds->current_round->add_starter_card(
		$player1,
		Game::Cribbage::Deck::Card->new(
			%{$data->{starter}}
		)
	);

	is($current->starter->value, 2, 'starter card is set ' . $current->starter->stringify);
	ok(1, 'Start the play, player2 sets the first card');


	ok($board->play_card($player2, 0), 'player2 plays card 0 ' . $board->get_card($player2, 0)->stringify);

	is($board->current_play_score, 10, 'The current run score is 10');
	is($board->play_card($player2, 1)->message, 'It is not the turn of player2', 'Fail at trying to play a card as player2 again');

	ok($board->play_card($player1, 3), 'player1 plays card ' . $board->get_card($player1, 3)->stringify);

	is_deeply($board->score->player1, { current => 2, last => 0}, 'which should score player1 2 points for hitting 15');
	is_deeply($board->score->player2, { current => 0, last => 0}, 'player2 should still have 0 points');

	is($board->current_play_score, 15, 'The current run score is 15');
 
	ok($board->play_card($player2, 3), 'player2 plays card ' . $board->get_card($player2, 3)->stringify);
	
	is($board->current_play_score, 17, 'The current run score is 17');

	ok($board->play_card($player1, 0), 'player1 plays card ' . $board->get_card($player1, 0)->stringify);

	is($board->current_play_score, 27, 'The current run score is 27');

	ok(1, 'Now nobody can play but confirm that');

	is($board->play_card($player2, 1)->message, 'Playing this card will make the score greater than 31', 'player2 cannot play any cards and trying to play one it fails');

	ok($board->cannot_play($player2), 'Confirm that player2 cannot play a card and switch current_player to player1 to check their cards');
	ok($board->cannot_play($player1), 'Confirm that player1 cannot play a card');

	ok($board->next_play($board), 'Both players still have cards so start another PLAY');

	is_deeply($board->score->player1, { current => 3, last => 2}, 'Confirm that player1 now has three points adding 1 point for the "go"');
	is_deeply($board->score->player2, { current => 0, last => 0 }, 'Confirm that player2 still has 0 points');

	is($board->current_play_score, 0, 'Confirm we have a new play object');
	is($board->last_play_score, 27, 'Confirm we have our last play still available');

	is($board->play_card($player1, 2)->message, 'It is not the turn of player1', "try to play with player1 but error as it's player2s turn");

	ok($board->play_card($player2, 1), 'player2 plays card ' . $board->get_card($player2, 1)->stringify);

	is($board->current_play_score, 10, 'The current run score is 10');

	ok($board->play_card($player1, 1), 'player1 plays card ' . $board->get_card($player1, 1)->stringify);

	is($board->current_play_score, 20, 'The current run score is 20');

	ok($board->play_card($player2, 2), 'player2 plays card ' . $board->get_card($player2, 2)->stringify);

	is($board->current_play_score, 30, 'The current run score is 30');

	ok(1, 'Now nobody can play but confirm that');

	is($board->play_card($player1, 2)->message, 'Playing this card will make the score greater than 31', 'player1 cannot play any cards and trying to play one it fails');

	ok($board->cannot_play($player1), 'Confirm that player1 cannot play a card');
	ok($board->cannot_play($player2), 'Confirm that player2 cannot play a card, they have no cards left at this point');

	ok($board->next_play($board), 'player1 still has cards so start a new play');

	is_deeply($board->score->player1, { current => 3, last => 2 }, 'Confirm that player1 still has 3 points');
	is_deeply($board->score->player2, { current => 1, last => 0 }, 'Confirm that player2 now has 1 point for getting the go');

	is($board->current_play_score, 0, 'Confirm we have a new play object');
	is($board->last_play_score, 30, 'Confirm we have our last play still available');

	ok($board->play_card($player1, 2), 'player1 plays their last card ' . $board->get_card($player1, 2)->stringify);

	is($board->current_play_score, 10, 'Confirm the final count of 10');

	ok($board->end_play(), 'No cards left to play so end this play');

	is_deeply($board->score->player1, {current => 4, last => 3}, 'Confirm that player1 now has 4 points adding one point for the "go"');
	is_deeply($board->score->player2, {current => 1, last => 0}, 'Confirm that player2 still has 1 point');

	ok($board->end_hands(), 'Now calculate the scores for the hands and the crib');

	is($board->rounds->current_round->history->[0]->player1->score->total_score, 8, 'player1 - 3 x 15 + 1 pair = 8 points');
	is($board->rounds->current_round->history->[0]->player2->score->total_score, 8, 'player2 - 1 pair + 1 three of a kind = 8 points');

	ok(1, 'player2 gets the crib');

	is($board->rounds->current_round->history->[0]->player2->crib_score->total_score, 9, 'player2 - 2 x 15 + 1 run of four and a nob = 9 points');

	is_deeply($board->score->player1, {current => 12, last => 4}, 'Confirm that player1 now has a total score of 12, 4 + 8');
	is_deeply($board->score->player2, {current => 18, last => 1}, 'Confirm that player2 now has a total score of 9, 1 + 8 + 9');

=pod
	my $hand = Game::Cribbage::Player::Hand->new(
		player => 'player1',
	);

	is($hand->player(), 'player1');

	for (@{$data->{hand}}) {
		$hand->add(Game::Cribbage::Deck::Card->new(
			%{$_}
		));
	}

	$hand->starter = Game::Cribbage::Deck::Card->new(
		%{$data->{starter}}
	);

	my $score = $hand->calculate_score();

	diag explain "Hand: " . join(" ,", map { $_->stringify } @{$hand->cards}) . " Starter: " . $hand->starter->stringify;

	is(scalar @{$hand->score->fifteen}, $data->{fifteen}, 'Fifteens: ' . $data->{fifteen});
	is(scalar @{$hand->score->pair}, $data->{pair}, 'Pairs: ' . $data->{pair});
	is(scalar @{$hand->score->three_of_a_kind}, $data->{three_of_a_kind}, 'Pair Royal: ' . $data->{fifteen});
	is(scalar @{$hand->score->four_of_a_kind}, $data->{four_of_a_kind}, 'Double Pair Royal: ' . $data->{four_of_a_kind});
	is(scalar @{$hand->score->run}, $data->{run}, 'Run: ' . $data->{run});
	is(scalar @{$hand->score->four_flush}, $data->{four_flush}, 'Four flush: ' . $data->{four_flush});
	is(scalar @{$hand->score->five_flush}, $data->{five_flush}, 'Five flush: ' . $data->{five_flush});
	is(scalar @{$hand->score->nobs}, $data->{nobs}, 'Nobs: ' . $data->{nobs});
	is($score, $data->{score}, "Total Score: $score");
=cut
}

done_testing();
