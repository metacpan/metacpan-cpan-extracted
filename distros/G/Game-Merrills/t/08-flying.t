#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Points;
use Game::Merrills::Rules;
use Game::Merrills::Test::Position qw/p names position_of/;

sub written { return [ map { $_->notation } @{ $_[0] } ] }

my $THREE_EACH = position_of(white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2/]);

subtest 'three men and none in hand: any man to any empty point, 54 moves' => sub {
	my $game = Game::Merrills->new(position => $THREE_EACH);
	is($game->phase, 'flying', 'white is flying');
	my $legal = $game->legal_moves;
	is(scalar @{$legal}, 54, 'three men times eighteen empty points');
	my %seen = map { $_ => 1 } @{ written($legal) };
	is(scalar keys %seen, 54, 'every one of them a different move');

	for my $from (qw/a7 d5 g1/) {
		is(scalar(grep { $_->from == p($from) } @{$legal}), 18, "$from can reach all eighteen");
	}
	is(scalar(grep { !$game->board->empty($_->to) } @{$legal}), 0, 'and none lands on a man');
	is(scalar(grep { $_->is_capture } @{$legal}), 0, 'no mill is in reach, so nothing is taken');
};

subtest 'a move is marked as flown only when it left the lines' => sub {
	my $game = Game::Merrills->new(position => $THREE_EACH);
	my $legal = $game->legal_moves;
	my @walked = grep { !$_->flew } @{$legal};
	is_deeply(
		[ sort @{ written(\@walked) } ],
		[ sort qw/a7-d7 a7-a4 d5-c5 d5-e5 d5-d6 g1-d1 g1-g4/ ],
		'the seven steps along a line are not flights'
	);
	is(scalar(grep { $_->flew } @{$legal}), 47, 'the other forty-seven are');
	is(scalar(grep { $_->flew && Game::Merrills::Points::is_adjacent($_->from, $_->to) } @{$legal}),
		0, 'and no flight is between neighbours');

	my $flown = $game->move('a7-g7');
	ok($flown->flew, 'a7-g7, played, flew');
	is($game->board->side_at(p('g7')), 'white', 'and landed');
};

subtest 'with flying off, three men still walk' => sub {
	my $game = Game::Merrills->new(position => $THREE_EACH, flying => 0);
	is($game->phase, 'moving', 'the phase is moving');
	is_deeply(
		[ sort @{ written($game->legal_moves) } ],
		[ sort qw/a7-d7 a7-a4 d5-c5 d5-e5 d5-d6 g1-d1 g1-g4/ ],
		'and only the seven steps are legal'
	);
	is($game->move('a7-g7')->code, 'not_adjacent', 'a flight is refused');

	my $position = Game::Merrills::Rules::position($game->board);
	is(Game::Merrills::Rules::phase($position, 'white', 0), 'moving', 'Rules says moving when told no flying');
	is(Game::Merrills::Rules::phase($position, 'white', 1), 'flying', 'flying when told yes');
	is(Game::Merrills::Rules::phase($position, 'white'), 'flying', 'and flying when not told');
	is(scalar @{ Game::Merrills::Rules::generate($position, 'white') }, 54,
		'generate, not told, flies too');
};

subtest 'the two sides are judged apart' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2 c3/],
	));
	is($game->phase_of('white'), 'flying', 'white, with three, flies');
	is($game->phase_of('black'), 'moving', 'black, with four, does not');
	is($game->phase, 'flying', 'phase is the side to move');
	$game->move('a7-g7');
	is($game->phase, 'moving', 'and follows the turn');
	is(scalar(grep { $_->flew } @{ $game->legal_moves }), 0, 'black has no flight in its list');
	is($game->move('b6-a1')->code, 'not_adjacent', 'and is refused one');
};

subtest 'four men do not fly, and three with more in hand are still placing' => sub {
	my $four = Game::Merrills->new(position => position_of(
		white => [qw/a7 d5 g1 c3/], black => [qw/b6 f4 d2/],
	));
	is($four->phase, 'moving', 'four men: moving');

	my $in_hand = Game::Merrills->new(position => position_of(
		white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2/], hand => { white => 2, black => 2 },
	));
	is($in_hand->phase, 'placing', 'three down and two in hand: placing');
	is(scalar(grep { !$_->is_placement } @{ $in_hand->legal_moves }), 0, 'and every move places');
};

subtest 'a man that flies into a mill takes a man' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 c3/], black => [qw/a1 d2 f4 e5/],
	));
	my @landing = grep { $_->to == p('g7') } @{ $game->legal_moves };
	my @closing = grep { $_->is_capture } @landing;
	is_deeply(written([ grep { !$_->is_capture } @landing ]), [qw/a7-g7 d7-g7/],
		'a7 and d7 can fly to g7 too, and close nothing by leaving the row');
	is_deeply(written(\@closing), [qw/c3-g7xe5 c3-g7xf4 c3-g7xd2 c3-g7xa1/],
		'c3 flies to g7, once for each black man');
	is(scalar(grep { $_->flew && $_->closes == 1 } @closing), 4, 'each a flight that closed one mill');
	$game->move('c3-g7xf4');
	is($game->on_board('black'), 3, 'and black is down to three');
	is($game->phase, 'flying', 'which sets black flying in its turn');
};

subtest 'a flying side cannot be walled in' => sub {
	my $walled = position_of(
		white => [qw/a7 g7 a1/], black => [qw/d7 a4 g4 d1/],
	);
	my $flying = Game::Merrills->new(position => $walled);
	is($flying->status, 'active', 'three men with every neighbour taken: the game goes on');
	is(scalar @{ $flying->legal_moves }, 3 * 17, 'with fifty-one flights to choose from');

	my $walking = Game::Merrills->new(position => $walled, flying => 0);
	is($walking->status, 'finished', 'the same men without flying have no move');
	is($walking->result->reason, 'blocked', 'and are blocked');
	is($walking->result->winner, 'black', 'so black wins');
};

done_testing;
