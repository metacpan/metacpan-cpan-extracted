use Test::More;

use Game::Cribbage::Player::Hand;

my @test = (
	{
		hand => [
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
			}
		],
		starter => {
			suit => 'H',
			symbol => 2
		},
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
	{
		hand => [
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
		starter => {
			suit => 'H',
			symbol => 3
		},
		score => 12,
		fifteen => 3,
		pair => 0,
		three_of_a_kind => 1,
		four_of_a_kind => 0,
		run => 0,
		four_flush => 0,
		five_flush => 0,
		nobs => 0
	},
	{
		hand => [
			{
				suit => 'H',
				symbol => 'K'
			},
			{
				suit => 'D',
				symbol => 'K'
			},
			{
				suit => 'C',
				symbol => 'K'
			},
			{
				suit => 'S',
				symbol => 'K'
			}
		],
		starter => {
			suit => 'H',
			symbol => 5
		},
		score => 20,
		fifteen => 4,
		pair => 0,
		three_of_a_kind => 0,
		four_of_a_kind => 1,
		run => 0,
		four_flush => 0,
		five_flush => 0,
		nobs => 0
	},
	{
		hand => [
			{
				suit => 'H',
				symbol => 'A'
			},
			{
				suit => 'H',
				symbol => '2'
			},
			{
				suit => 'H',
				symbol => '3'
			},
			{
				suit => 'H',
				symbol => '4'
			}
		],
		starter => {
			suit => 'S',
			symbol => J
		},
		score => 12,
		fifteen => 2,
		pair => 0,
		three_of_a_kind => 0,
		four_of_a_kind => 0,
		run => 1,
		four_flush => 1,
		five_flush => 0,
		nobs => 0
	},
	{
		hand => [
			{
				suit => 'H',
				symbol => 'J'
			},
			{
				suit => 'H',
				symbol => '2'
			},
			{
				suit => 'H',
				symbol => '3'
			},
			{
				suit => 'H',
				symbol => '4'
			}
		],
		starter => {
			suit => 'H',
			symbol => K
		},
		score => 13,
		fifteen => 2,
		pair => 0,
		three_of_a_kind => 0,
		four_of_a_kind => 0,
		run => 1,
		four_flush => 0,
		five_flush => 1,
		nobs => 1
	},
	{
		hand => [
			{
				suit => 'H',
				symbol => 'J'
			},
			{
				suit => 'D',
				symbol => '5'
			},
			{
				suit => 'S',
				symbol => '5'
			},
			{
				suit => 'C',
				symbol => '5'
			}
		],
		starter => {
			suit => 'H',
			symbol => 5
		},
		score => 29,
		fifteen => 8,
		pair => 0,
		three_of_a_kind => 0,
		four_of_a_kind => 1,
		run => 0,
		four_flush => 0,
		five_flush => 0,
		nobs => 1
	},
);

use Game::Cribbage::Deck::Card;
for my $data (@test) {
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
	is(scalar @{$hand->score->three_of_a_kind}, $data->{three_of_a_kind}, 'Pair Royal: ' . $data->{three_of_a_kind});
	is(scalar @{$hand->score->four_of_a_kind}, $data->{four_of_a_kind}, 'Double Pair Royal: ' . $data->{four_of_a_kind});
	is(scalar @{$hand->score->run}, $data->{run}, 'Run: ' . $data->{run});
	is(scalar @{$hand->score->four_flush}, $data->{four_flush}, 'Four flush: ' . $data->{four_flush});
	is(scalar @{$hand->score->five_flush}, $data->{five_flush}, 'Five flush: ' . $data->{five_flush});
	is(scalar @{$hand->score->nobs}, $data->{nobs}, 'Nobs: ' . $data->{nobs});
	is($score, $data->{score}, "Total Score: $score");
}

done_testing();
