#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills::Board;
use Game::Merrills::Move;
use Game::Merrills::Points;
use Game::Merrills::Rules;

sub p { return Game::Merrills::Points::point($_[0]) }

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

sub closes {
	my ($position, $side, $from, $to) = @_;
	return Game::Merrills::Rules::closes($position, $side,
		defined $from ? p($from) : undef, p($to));
}

sub landing_on {
	my ($position, $side, $to) = @_;
	return grep { $_->[Game::Merrills::Rules::RM_TO] == p($to) }
		@{ Game::Merrills::Rules::generate($position, $side) };
}

subtest 'each of the sixteen mills closes on its third man, whichever is last' => sub {
	for my $mill (Game::Merrills::Points::mills()) {
		my @names = map { Game::Merrills::Points::name($_) } @{$mill};
		for my $last (0 .. 2) {
			my @down = @names[ grep { $_ != $last } 0 .. 2 ];
			for my $side (qw/white black/) {
				my $other = $side eq 'white' ? 'black' : 'white';
				my $position = position_with($side => \@down, $other => []);
				is(closes($position, $side, undef, $names[$last]), 1,
					"$side: @down then $names[$last]");
				is(closes($position, $other, undef, $names[$last]), 0,
					"$other on $names[$last] closes nothing of its own");
			}
		}
	}
};

subtest 'two of a mill and the third is not yet a mill' => sub {
	my $position = position_with(white => [qw/a7/]);
	is(closes($position, 'white', undef, 'd7'), 0, 'the second man of a row');
	is(closes(position_with(), 'white', undef, 'd7'), 0, 'the first man on the board');
};

subtest 'an enemy man in the row spoils it' => sub {
	my $position = position_with(white => [qw/a7/], black => [qw/d7/]);
	is(closes($position, 'white', undef, 'g7'), 0, 'white a7, black d7, white g7');
	is(closes($position, 'black', undef, 'g7'), 0, 'and it is no mill of black either');
};

subtest 'three in a row across the centre is not a mill' => sub {
	my $across = position_with(white => [qw/b4 c4/]);
	is(closes($across, 'white', undef, 'e4'), 0, 'b4 c4 then e4');
	is(closes($across, 'white', undef, 'a4'), 1, 'b4 c4 then a4 is');
	my $down = position_with(white => [qw/d6 d5/]);
	is(closes($down, 'white', undef, 'd3'), 0, 'd6 d5 then d3');
	is(closes($down, 'white', undef, 'd7'), 1, 'd6 d5 then d7 is');
	my $apart = position_with(white => [qw/a7 g7 a1/]);
	is(closes($apart, 'white', undef, 'g1'), 0, 'the four corners are no mill');
};

subtest 'one man closing two mills at once: closes is 2, and one man is taken' => sub {
	my $position = position_with(
		white => [qw/a7 g7 d6 d5/],
		black => [qw/a1 g1 b2 f2/],
	);
	is(closes($position, 'white', undef, 'd7'), 2, 'd7 completes the top row and the d file');

	my @moves = landing_on($position, 'white', 'd7');
	is(scalar @moves, 4, 'one move for each of the four black men');
	is(scalar(grep { $_->[Game::Merrills::Rules::RM_CLOSES] == 2 } @moves), 4,
		'every one of them says it closed two');
	is(scalar(grep { defined $_->[Game::Merrills::Rules::RM_REMOVE] } @moves), 4,
		'and every one takes a man');
	is(scalar(grep { ref $_->[Game::Merrills::Rules::RM_REMOVE] } @moves), 0,
		'one man, a point and not a list of them');

	my $every = Game::Merrills::Rules::generate($position, 'white');
	is(scalar(grep { @{$_} != 5 } @{$every}), 0,
		'no move anywhere in the list has room for a second removal');

	my $after = [ @{$position} ];
	Game::Merrills::Rules::apply($after, 'white', $moves[0]);
	is(scalar(grep { $after->[$_] == -1 } 0 .. 23), 3, 'four black men become three, not two');
};

subtest 'generate marks a closing placement and no other' => sub {
	my $position = position_with(white => [qw/a7 d7 b2/], black => [qw/a1 d1/]);
	my $moves = Game::Merrills::Rules::generate($position, 'white');

	my @closing = grep { $_->[Game::Merrills::Rules::RM_CLOSES] } @{$moves};
	is_deeply(
		[ map { Game::Merrills::Move->from_raw($_)->notation } @closing ],
		[qw/g7xa1 g7xd1/],
		'g7 closes, once for each black man, in point order'
	);
	is(scalar(grep { $_->[Game::Merrills::Rules::RM_CLOSES] == 1 } @closing), 2,
		'each saying one mill');

	my @quiet = grep { !$_->[Game::Merrills::Rules::RM_CLOSES] } @{$moves};
	is(scalar @quiet, 18, 'the other eighteen empty points close nothing');
	is(scalar(grep { defined $_->[Game::Merrills::Rules::RM_REMOVE] } @quiet), 0,
		'and take nothing');
	is(scalar(grep { $_->[Game::Merrills::Rules::RM_TO] == p('g7') } @quiet), 0,
		'g7 is not also offered without its capture');
};

subtest 'black closes mills as white does' => sub {
	my $position = position_with(white => [qw/a1 d1/], black => [qw/c5 d5/]);
	my @moves = landing_on($position, 'black', 'e5');
	is(scalar @moves, 2, 'e5 takes either white man');
	is_deeply(
		[ map { Game::Merrills::Points::name($_->[Game::Merrills::Rules::RM_REMOVE]) } @moves ],
		[qw/a1 d1/],
		'a1 and d1, in point order'
	);
	my $after = [ @{$position} ];
	Game::Merrills::Rules::apply($after, 'black', $moves[0]);
	is($after->[ p('e5') ], -1, 'a black man on e5');
	is($after->[ p('a1') ], 0, 'the white man on a1 gone');
	is($after->[ p('d1') ], 1, 'the one on d1 still there');
	is($after->[Game::Merrills::Rules::HAND_WHITE], $position->[Game::Merrills::Rules::HAND_WHITE],
		"and white's hand is not what paid for it");
	Game::Merrills::Rules::unapply($after, 'black', $moves[0]);
	is_deeply($after, $position, 'taking it back puts the white man on a1 again');
};

subtest 'the point a man leaves counts as empty' => sub {
	my $position = position_with(white => [qw/g7 g1/]);
	is(closes($position, 'white', undef, 'g4'), 1, 'a third man placed on g4 closes the g file');
	is(closes($position, 'white', 'g7', 'g4'), 0,
		'the man from g7 stepping to g4 leaves a gap behind it');
	is(closes($position, 'white', 'g1', 'g4'), 0, 'and so does the one from g1');

	my $side_on = position_with(white => [qw/g7 g1 f4/]);
	is(closes($side_on, 'white', 'f4', 'g4'), 1,
		'a man stepping in from f4, outside the row, does close it');

	my $shuffle = position_with(white => [qw/a7 d7 g7/]);
	is(closes($shuffle, 'white', 'g7', 'g4'), 0, 'stepping out of a mill closes nothing');
	my $out = [ @{$shuffle} ];
	Game::Merrills::Rules::apply($out, 'white', [ p('g7'), p('g4'), undef, 0, 0 ]);
	is(closes($out, 'white', 'g4', 'g7'), 1, 'and stepping back in closes it again');
};

done_testing;
