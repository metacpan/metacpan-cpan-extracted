#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills::Board;
use Game::Merrills::Move;
use Game::Merrills::Notation;
use Game::Merrills::Points;

sub p { return Game::Merrills::Points::point($_[0]) }

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

my $parse = \&Game::Merrills::Notation::parse_move;
my $format = \&Game::Merrills::Notation::format_move;

subtest 'the four shapes of a move' => sub {
	is_deeply($parse->('d2'), { to => p('d2') }, 'a placement');
	is_deeply($parse->('d2-d3'), { from => p('d2'), to => p('d3') }, 'a move');
	is_deeply($parse->('d2xa1'), { to => p('d2'), remove => p('a1') },
		'a placement that takes');
	is_deeply($parse->('d2-d3xa1'),
		{ from => p('d2'), to => p('d3'), remove => p('a1') }, 'a move that takes');
	is_deeply($parse->('a7-g1'), { from => p('a7'), to => p('g1') },
		'a flying move is written like any other');
};

subtest 'a placement has no from key at all, and a quiet move no remove' => sub {
	ok(!exists $parse->('d2')->{from}, 'no from');
	ok(!exists $parse->('d2')->{remove}, 'no remove');
	ok(!exists $parse->('d2-d3')->{remove}, 'no remove on a move');
	ok(!exists $parse->('d2xa1')->{from}, 'no from on a taking placement');
};

subtest 'case and spaces are forgiven' => sub {
	my $want = { from => p('d2'), to => p('d3'), remove => p('a1') };
	is_deeply($parse->($_), $want, "'$_'")
		for 'D2-D3XA1', 'd2 - d3 x a1', '  d2-d3xa1  ', "d2-d3xa1\n", 'D2 -d3 Xa1';
};

subtest 'what is not a move is undef, and nothing dies' => sub {
	my @bad = (
		undef, '', ' ', 'd', '2', 'd4', 'a2', 'h1', 'a8', 'd0',
		'd2-', '-d2', 'd2x', 'xd2', 'd2-d4', 'd4-d2', 'd2xd4',
		'd2-d3-d5', 'd2xa1xa4', 'd2xa1-d3', 'd2d3', 'd2 d3', 'd2--d3',
		'd2-d2', 'd2xd2', 'd2-d3xd3', 'd2-d3xd2',
		'19', 'pass', 'resign', 'd2!', [], {},
	);
	for my $text (@bad) {
		my $shown = defined $text ? "'$text'" : 'undef';
		my $result = 'not run';
		my $died = dies { $result = $parse->($text) };
		is($died, '', "$shown does not die");
		is($result, undef, "$shown is not a move");
	}
};

subtest 'every move that can be written reads back' => sub {
	my @points = Game::Merrills::Points::all_points();
	my $count = 0;
	for my $to (@points) {
		for my $from (undef, @points) {
			next if defined $from && $from == $to;
			for my $remove (undef, @points) {
				next if defined $remove && ($remove == $to
					|| (defined $from && $remove == $from));
				my %move = (to => $to);
				$move{from} = $from if defined $from;
				$move{remove} = $remove if defined $remove;
				my $text = $format->(\%move);
				$count++;
				next if eq_hash($parse->($text), \%move) && $text =~ m/^[a-g1-7x-]+$/;
				fail("$text does not round trip");
				return;
			}
		}
	}
	is($count, 24 * 24 + 24 * 23 * 23, 'all 13,272 of them');
};

subtest 'format_move writes lower case with no spaces, and needs a to' => sub {
	is($format->({ to => p('d2') }), 'd2', 'a placement');
	is($format->({ from => p('d2'), to => p('d3'), remove => p('a1') }), 'd2-d3xa1',
		'a move that takes');
	is($format->({ from => undef, to => p('d2'), remove => undef }), 'd2',
		'undef parts are parts that are not there');
	like(dies { $format->({ from => 1 }) }, qr/^a move needs a point to go to/, 'no to');
	like(dies { $format->('d2') }, qr/^a move needs a point to go to/, 'not a hashref');
	like(dies { $format->({ to => 24 }) }, qr/^point must be 0 \.\. 23/, 'a to off the board');
};

subtest 'a Move writes itself the same way' => sub {
	my $move = Game::Merrills::Move->new(
		from => p('d2'), to => p('d3'), remove => p('a1'), closes => 1, side => 'white'
	);
	is($move->notation, 'd2-d3xa1', 'notation');
	is($move->stringify, 'd2-d3xa1', 'stringify');
	ok($move->is_capture, 'it took a man');
	ok(!$move->is_placement, 'and was not a placement');
	is($move->side, 'white', 'by white');
	is($move->closes, 1, 'closing one mill');
	ok(!$move->flew, 'along a line');

	my $placed = Game::Merrills::Move->new(to => p('d2'), side => 'black');
	is($placed->notation, 'd2', 'a placement');
	ok($placed->is_placement, 'is a placement');
	ok(!$placed->is_capture, 'that took nothing');
	is($placed->from, undef, 'from nowhere');
	is($placed->remove, undef, 'removing nothing');
	is($placed->closes, 0, 'closing nothing');

	my $built = Game::Merrills::Move->new(%{ $parse->('a7-g1xd5') }, flew => 1);
	is($built->notation, 'a7-g1xd5', 'a parsed move builds a Move');
	ok($built->flew, 'that flew');
};

subtest 'a Move and its raw move convert both ways' => sub {
	my @raw;
	$raw[Game::Merrills::Move::RM_FROM] = p('d2');
	$raw[Game::Merrills::Move::RM_TO] = p('d3');
	$raw[Game::Merrills::Move::RM_REMOVE] = p('a1');
	$raw[Game::Merrills::Move::RM_CLOSES] = 2;
	$raw[Game::Merrills::Move::RM_FLEW] = 0;

	my $move = Game::Merrills::Move->from_raw(\@raw, 'black');
	is($move->notation, 'd2-d3xa1', 'the points');
	is($move->closes, 2, 'the mills');
	is($move->side, 'black', 'the side');
	is_deeply($move->to_raw, \@raw, 'and back');
	isnt($move->to_raw, $move->to_raw, 'a fresh arrayref each time');

	my @placed;
	$placed[Game::Merrills::Move::RM_TO] = p('g7');
	my $placement = Game::Merrills::Move->from_raw(\@placed, 'white');
	is($placement->notation, 'g7', 'a placement from a raw move');
	is_deeply($placement->to_raw, [ undef, p('g7'), undef, 0, 0 ], 'and back, filled in');
	is_deeply(
		[
			Game::Merrills::Move::RM_FROM, Game::Merrills::Move::RM_TO,
			Game::Merrills::Move::RM_REMOVE, Game::Merrills::Move::RM_CLOSES,
			Game::Merrills::Move::RM_FLEW
		],
		[ 0 .. 4 ],
		'the five indexes are five different ones'
	);
};

subtest 'a Move that could not be one dies' => sub {
	like(dies { Game::Merrills::Move->new(from => 1) },
		qr/^a move needs a point to go to/, 'no to');
	like(dies { Game::Merrills::Move->new(to => 24) }, qr/^point must be 0 \.\. 23/, 'to');
	like(dies { Game::Merrills::Move->new(to => 1, from => 24) },
		qr/^point must be 0 \.\. 23/, 'from');
	like(dies { Game::Merrills::Move->new(to => 1, remove => 24) },
		qr/^point must be 0 \.\. 23/, 'remove');
};

my $OPENING = '........................ w 9 9 0 0';

subtest 'a position reads' => sub {
	my $position = Game::Merrills::Notation::parse_position('W..........B............ b 8 7 3 12');
	is($position->{cells}[0], 1, 'a7 is white');
	is($position->{cells}[11], -1, 'c4 is black');
	is(scalar(grep { $_ == 0 } @{ $position->{cells} }), 22, 'the rest are empty');
	is(scalar @{ $position->{cells} }, 24, 'twenty-four cells');
	is($position->{turn}, 'black', 'black to move');
	is_deeply($position->{hand}, { white => 8, black => 7 }, 'the hands');
	is($position->{no_mill}, 3, 'plies since a mill');
	is($position->{ply}, 12, 'the ply');

	is(Game::Merrills::Notation::parse_position($OPENING)->{turn}, 'white', 'w is white');
	is_deeply(
		Game::Merrills::Notation::parse_position("  $OPENING \n")->{hand},
		{ white => 9, black => 9 },
		'space around it is forgiven'
	);
};

subtest 'a position round trips, and a board takes what it reads' => sub {
	my @texts = (
		$OPENING,
		'W..........B............ b 8 8 0 2',
		'WWW.BB..B..W....B..W.B.. w 4 4 1 10',
		'WBWBWBWBW.........BWBWBW b 0 0 57 143',
		'WWWWWWWWWBBBBBBBBB...... w 0 0 0 18',
	);
	for my $text (@texts) {
		my $position = Game::Merrills::Notation::parse_position($text);
		is(Game::Merrills::Notation::format_position($position), $text, $text);
		my $board = Game::Merrills::Board->new(
			cells => $position->{cells},
			hand => $position->{hand}
		);
		is(
			Game::Merrills::Notation::format_position({
				%{$position}, cells => $board->cells, hand => $board->hand
			}),
			$text,
			'and through a Board'
		);
	}
};

subtest 'format_position fills in what is left out' => sub {
	is(
		Game::Merrills::Notation::format_position({
			cells => Game::Merrills::Board->opening,
			turn => 'white',
			hand => { white => 9, black => 9 },
		}),
		$OPENING,
		'the counts default to nought'
	);
	is(
		Game::Merrills::Notation::format_position({
			cells => Game::Merrills::Board->opening, turn => 'black'
		}),
		'........................ b 0 0 0 0',
		'and so do the hands'
	);
};

subtest 'what is not a position dies, saying why' => sub {
	my @bad = (
		[ undef, qr/^position: nothing to read/ ],
		[ '', qr/^position: six fields are needed, got 0/ ],
		[ '........................ w 9 9 0', qr/^position: six fields are needed, got 5/ ],
		[ "$OPENING 1", qr/^position: six fields are needed, got 7/ ],
		[ '....................... w 9 9 0 0', qr/^position: the board must be 24/ ],
		[ '......................... w 9 9 0 0', qr/^position: the board must be 24/ ],
		[ 'w....................... w 9 9 0 0', qr/^position: the board must be 24/ ],
		[ 'X....................... w 9 9 0 0', qr/^position: the board must be 24/ ],
		[ '........................ x 9 9 0 0', qr/^position: the side to move must be w or b, got 'x'/ ],
		[ '........................ W 9 9 0 0', qr/^position: the side to move must be w or b/ ],
		[ '........................ w 10 9 0 0', qr/^position: men in hand for white must be 0 \.\. 9, got '10'/ ],
		[ '........................ w 9 -1 0 0', qr/^position: men in hand for black must be 0 \.\. 9, got '-1'/ ],
		[ '........................ w 9 9 x 0', qr/^position: plies since a mill must be a number/ ],
		[ '........................ w 9 9 0 1.5', qr/^position: the ply must be a number/ ],
		[ 'W....................... w 9 9 0 0', qr/^position: white has more than nine men/ ],
		[ 'B....................... w 9 9 0 0', qr/^position: black has more than nine men/ ],
	);
	for my $case (@bad) {
		my ($text, $why) = @{$case};
		like(dies { Game::Merrills::Notation::parse_position($text) }, $why,
			defined $text ? "'$text'" : 'undef');
	}

	my $cells = Game::Merrills::Board->opening;
	like(dies { Game::Merrills::Notation::format_position('x') },
		qr/^position: not a hashref/, 'format: not a hashref');
	like(dies { Game::Merrills::Notation::format_position({ turn => 'white' }) },
		qr/^position: cells must be an arrayref of 24 values/, 'format: no cells');
	like(dies { Game::Merrills::Notation::format_position({ cells => [ (2) x 24 ], turn => 'white' }) },
		qr/^position: cell a7 must be -1, 0 or 1/, 'format: a cell that is no man');
	like(dies { Game::Merrills::Notation::format_position({ cells => $cells, turn => 'red' }) },
		qr/^position: turn must be white or black/, 'format: a side that is not one');
	like(dies { Game::Merrills::Notation::format_position({ cells => $cells }) },
		qr/^position: turn must be white or black/, 'format: no side');
	like(
		dies {
			Game::Merrills::Notation::format_position({
				cells => $cells, turn => 'white', hand => { white => 12 }
			})
		},
		qr/^position: men in hand for white must be 0 \.\. 9, got '12'/,
		'format: a hand that is not a count'
	);
};

subtest 'a game is written in numbered pairs' => sub {
	my @moves = qw/d2 f4 d6 b4 d7/;
	my $text = Game::Merrills::Notation::format_record(\@moves);
	is($text, "1. d2 f4\n2. d6 b4\n3. d7\n", 'white then black, a pair a line');
	is(Game::Merrills::Notation::format_record([]), '', 'no moves is no text');
	is(Game::Merrills::Notation::format_record([qw/d2 f4/]), "1. d2 f4\n", 'an even count');
	is(Game::Merrills::Notation::format_record(['D2 - D3 x A1']), "1. d2-d3xa1\n",
		'each move is rewritten the one way');

	my $mixed = Game::Merrills::Notation::format_record([
		'd2',
		{ to => p('f4') },
		Game::Merrills::Move->new(from => p('d2'), to => p('d3'), remove => p('f4')),
	]);
	is($mixed, "1. d2 f4\n2. d2-d3xf4\n", 'strings, hashrefs and Moves alike');
};

subtest 'and reads back, numbers and line breaks ignored' => sub {
	my @moves = qw/d2 f4 d6 b4 d2-d3 f4-g4xd6 a7-g1/;
	my $text = Game::Merrills::Notation::format_record(\@moves);
	my $read = Game::Merrills::Notation::parse_record($text);
	is_deeply([ map { $format->($_) } @{$read} ], \@moves, 'the same moves in order');
	is_deeply(
		[ map { $format->($_) } @{ Game::Merrills::Notation::parse_record('d2 f4 d6') } ],
		[qw/d2 f4 d6/],
		'without numbers'
	);
	is_deeply(
		[ map { $format->($_) } @{ Game::Merrills::Notation::parse_record("1.\nd2\n\n  f4 2. d6") } ],
		[qw/d2 f4 d6/],
		'however it is broken up'
	);
	is_deeply(Game::Merrills::Notation::parse_record(''), [], 'nothing is no moves');
	is_deeply(
		[ map { $format->($_) } @{ Game::Merrills::Notation::parse_record("# a note\n1. d2 f4\n  # d4 pass, not moves\n2. d6\n") } ],
		[qw/d2 f4 d6/],
		'a line beginning with # is a note and is passed over'
	);
	like(dies { Game::Merrills::Notation::parse_record("1. d2 # f4\n") },
		qr/^record: move 2, '#' is not a move/, 'but only a whole line: a # after a move is not a note');
	is(
		Game::Merrills::Notation::format_record(Game::Merrills::Notation::parse_record($text)),
		$text,
		'text to moves to text'
	);
};

subtest 'a game with a move that is not one dies, naming it' => sub {
	like(dies { Game::Merrills::Notation::parse_record('1. d2 f4 2. d4 b4') },
		qr/^record: move 3, 'd4' is not a move/, 'reading, by its place in the game');
	like(dies { Game::Merrills::Notation::parse_record('d2 3 f4') },
		qr/^record: move 2, '3' is not a move/, 'a bare number is not a move number');
	like(dies { Game::Merrills::Notation::parse_record(undef) },
		qr/^record: nothing to read/, 'reading undef');
	like(dies { Game::Merrills::Notation::format_record([qw/d2 zz/]) },
		qr/^record: move 2, 'zz' is not a move/, 'writing');
	like(dies { Game::Merrills::Notation::format_record([ 'd2', undef ]) },
		qr/^record: move 2, undef is not a move/, 'writing undef');
	like(dies { Game::Merrills::Notation::format_record('d2') },
		qr/^record: moves must be an arrayref/, 'writing a string');
};

subtest 'a game that began somewhere else says where' => sub {
	my $start = 'WWW.BB..B..W....B..W.B.. w 4 4 0 10';
	my $text = Game::Merrills::Notation::format_record([qw/d2 f4/], position => $start);
	is($text, "position $start\n1. d2 f4\n", 'on a line of its own before the moves');
	is(Game::Merrills::Notation::record_position($text), $start, 'and it reads back');
	is_deeply(
		[ map { $format->($_) } @{ Game::Merrills::Notation::parse_record($text) } ],
		[qw/d2 f4/],
		'the moves read as if the line were not there'
	);
	is(Game::Merrills::Notation::record_position("1. d2 f4\n"), undef,
		'a game from the empty board names no position');
	is(Game::Merrills::Notation::record_position("  position   $start  \n"), $start,
		'space around the line is forgiven');
	is(Game::Merrills::Notation::format_record([], position => $start), "position $start\n",
		'a position and no moves yet');
	like(dies { Game::Merrills::Notation::record_position("position nonsense\n1. d2") },
		qr/^position: six fields are needed/, 'a position line that is not a position dies');
	like(dies { Game::Merrills::Notation::format_record([], position => 'nonsense') },
		qr/^position: six fields are needed/, 'writing one too');
	like(dies { Game::Merrills::Notation::record_position(undef) },
		qr/^record: nothing to read/, 'and so does reading undef');
};

done_testing;
