#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills::Board;
use Game::Merrills::Points;
use Game::Merrills::Rules;

sub p { return Game::Merrills::Points::point($_[0]) }

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

sub position_with {
	my (%men) = @_;
	my %hand = (white => 9, black => 9);
	my $board = Game::Merrills::Board->new(hand => { white => 0, black => 0 });
	for my $side (qw/white black/) {
		for my $name (@{ $men{$side} || [] }) {
			$board->set(p($name), $side);
			$hand{$side}--;
		}
	}
	$board->hand({ %hand, %{ $men{hand} || {} } });
	return Game::Merrills::Rules::position($board);
}

sub takes {
	my ($position, $side) = @_;
	return [ map { Game::Merrills::Points::name($_) }
		Game::Merrills::Rules::removable($position, $side) ];
}

sub taken_by {
	my ($position, $side, $to) = @_;
	return [
		map { Game::Merrills::Points::name($_->[Game::Merrills::Rules::RM_REMOVE]) }
		grep { $_->[Game::Merrills::Rules::RM_TO] == p($to) }
		@{ Game::Merrills::Rules::generate($position, $side) }
	];
}

subtest 'a man in a mill is not offered while another stands outside one' => sub {
	my $position = position_with(
		white => [qw/a7 d7/],
		black => [qw/a1 d1 g1 f4/],
	);
	is_deeply(takes($position, 'white'), [qw/f4/], 'only the man outside the mill');
	is_deeply(taken_by($position, 'white', 'g7'), [qw/f4/],
		'and the closing move offers only him');

	my $two_out = position_with(
		white => [qw/a7 d7/],
		black => [qw/a1 d1 g1 f4 b6/],
	);
	is_deeply(takes($two_out, 'white'), [qw/b6 f4/], 'two outside: both, in point order');
};

subtest 'every enemy man in a mill: all of them are offered' => sub {
	my $position = position_with(
		white => [qw/a7 d7/],
		black => [qw/a1 d1 g1/],
	);
	is_deeply(takes($position, 'white'), [qw/a1 d1 g1/], 'the three men of the one mill');
	is_deeply(taken_by($position, 'white', 'g7'), [qw/a1 d1 g1/],
		'and the closing move may take any of them');

	my $two_mills = position_with(
		white => [qw/a7 d7/],
		black => [qw/a1 d1 g1 c5 d5 e5/],
	);
	is_deeply(takes($two_mills, 'white'), [qw/c5 d5 e5 a1 d1 g1/],
		'two whole mills and nothing else: all six');
};

subtest 'an enemy man in two mills is one man and is offered once' => sub {
	my $position = position_with(
		white => [qw/a7 d7/],
		black => [qw/a1 d1 g1 g4 g7/],
	);
	is_deeply(takes($position, 'white'), [qw/g7 g4 a1 d1 g1/],
		'five men in two mills that share g1: five points, g1 once');

	my $with_spare = position_with(
		white => [qw/a7 b6/],
		black => [qw/a1 d1 g1 g4 g7 c3/],
	);
	is_deeply(takes($with_spare, 'white'), [qw/c3/],
		'and with one man outside, being in two mills is no less safe than one');
};

subtest "the mover's own men are never offered" => sub {
	my $position = position_with(
		white => [qw/a7 d7 b6 c5/],
		black => [qw/a1 f4/],
	);
	is_deeply(takes($position, 'white'), [qw/f4 a1/], 'white takes black men');
	is_deeply(takes($position, 'black'), [qw/a7 d7 b6 c5/], 'black takes white men');
	is_deeply(taken_by($position, 'white', 'g7'), [qw/f4 a1/],
		'and the move that closes offers no white man');

	my $own_mill = position_with(
		white => [qw/a7 d7 g7 b6/],
		black => [qw/a1/],
	);
	is_deeply(takes($own_mill, 'black'), [qw/b6/],
		'asked for black, it is the white mill that is safe');
};

subtest 'men in hand are never offered' => sub {
	my $none_down = position_with(white => [qw/a7 d7/]);
	is($none_down->[Game::Merrills::Rules::HAND_BLACK], 9, 'black has nine in hand');
	is_deeply(takes($none_down, 'white'), [], 'and none of them can be taken');

	my $one_down = position_with(white => [qw/a7 d7/], black => [qw/f4/]);
	is_deeply(takes($one_down, 'white'), [qw/f4/], 'one on the board is one to take');
	is(scalar(grep { $_ > 23 } Game::Merrills::Rules::removable($one_down, 'white')), 0,
		'what is offered is always a point on the board');

	my $after = [ @{$one_down} ];
	my ($closing) = grep { defined $_->[Game::Merrills::Rules::RM_REMOVE] }
		@{ Game::Merrills::Rules::generate($one_down, 'white') };
	Game::Merrills::Rules::apply($after, 'white', $closing);
	is($after->[Game::Merrills::Rules::HAND_BLACK], 8, 'taking a man costs the hand nothing');
};

subtest 'a mill closed with nothing to take is a mistake in the position, and dies' => sub {
	my $position = position_with(white => [qw/a7 d7/]);
	like(dies { Game::Merrills::Rules::generate($position, 'white') },
		qr/^a mill closed and there is no man to take/,
		'no black man on the board and white about to close');
	is(dies { Game::Merrills::Rules::generate($position, 'black') }, '',
		'black, who closes nothing there, is generated for as usual');
};

subtest 'removable leaves the position alone, and answers the same twice' => sub {
	my $position = position_with(white => [qw/a7 d7/], black => [qw/a1 d1 g1 f4/]);
	my $before = [ @{$position} ];
	my $first = takes($position, 'white');
	my $second = takes($position, 'white');
	is_deeply($first, $second, 'the same list');
	is_deeply($position, $before, 'and the same position');
};

done_testing;
