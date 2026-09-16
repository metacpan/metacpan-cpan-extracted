#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers::Board;
use Game::Checkers::Move;
use Game::Checkers::Notation;

my $N = 'Game::Checkers::Notation';

subtest 'a move parses however it is spelled' => sub {
	plan tests => 8;
	my $simple = { from => 11, to => 15, squares => [11, 15], jump => 0 };
	is_deeply Game::Checkers::Notation::parse_move('11-15'), $simple, 'a simple move';
	is_deeply Game::Checkers::Notation::parse_move(' 11 - 15 '), $simple, 'with spaces';

	my $double = { from => 23, to => 7, squares => [23, 14, 7], jump => 1 };
	is_deeply Game::Checkers::Notation::parse_move('23x14x7'), $double, 'a double jump';
	is_deeply Game::Checkers::Notation::parse_move('23X14X7'), $double, 'in upper case';

	is_deeply Game::Checkers::Notation::parse_move('23x7'),
		{ from => 23, to => 7, squares => [23, 7], jump => 1 },
		'the short form of a jump parses as written, and is resolved later';

	is Game::Checkers::Notation::parse_move('11-33'), undef, 'square 33 is not a square';
	is Game::Checkers::Notation::parse_move('11-11'), undef, 'a move to the same square';
	is Game::Checkers::Notation::parse_move('resign'), undef, 'a word is not a move';
};

subtest 'a move may be written as the squares on the board' => sub {
	plan tests => 8;
	is_deeply Game::Checkers::Notation::parse_move('f6-e5'),
		{ from => 11, to => 15, squares => [11, 15], jump => 0 },
		'the coordinate spelling comes back as the same numbers';
	is_deeply Game::Checkers::Notation::parse_move('F6-E5'),
		{ from => 11, to => 15, squares => [11, 15], jump => 0 },
		'in upper case as well';
	is_deeply Game::Checkers::Notation::parse_move('e3xc5xe7'),
		{ from => 23, to => 7, squares => [23, 14, 7], jump => 1 },
		'and so does a jump, path and all';

	is Game::Checkers::Notation::parse_move('e5-e5'), undef,
		'a move to the same square, spelled the other way';
	is Game::Checkers::Notation::parse_move('a8-b7'), undef,
		'a light square is not a square anybody plays on';
	is Game::Checkers::Notation::parse_move('e9-d8'), undef, 'nor is a rank off the board';
	is Game::Checkers::Notation::parse_move('11-e5'), undef,
		'the two spellings do not mix';
	is Game::Checkers::Notation::parse_move('e5-15'), undef, 'in either order';
};

subtest 'a move formats for the board as well as for the record' => sub {
	plan tests => 4;
	my $jump = Game::Checkers::Move->new(
		from => 23,
		to => 7,
		path => [23, 14, 7],
		captures => [18, 10],
		captured => [1, 1],
		side => 'white'
	);
	is $jump->coord_notation, 'e3xc5xe7', 'a jump names every square it landed on';
	is $N->can('format_coord_move')->($jump), 'e3xc5xe7', 'and the function agrees';

	my $simple = Game::Checkers::Move->new(
		from => 11, to => 15, path => [11, 15], side => 'black'
	);
	is $simple->coord_notation, 'f6-e5', 'a simple move is its two squares';
	is $N->can('format_coord_move')->(
		Game::Checkers::Notation::parse_move('11-15')
	), 'f6-e5', 'a parsed move formats either way';
};

subtest 'a move formats as its full path' => sub {
	plan tests => 3;
	my $jump = Game::Checkers::Move->new(
		from => 23,
		to => 7,
		path => [23, 14, 7],
		captures => [18, 10],
		captured => [1, 1],
		side => 'white'
	);
	is $jump->notation, '23x14x7', 'the whole path, never the short form';
	ok $jump->is_jump, 'and it knows it is a jump';

	my $simple = Game::Checkers::Move->new(
		from => 11, to => 15, path => [11, 15], side => 'black'
	);
	is $simple->notation, '11-15', 'a simple move';
};

subtest 'the raw move round trips' => sub {
	plan tests => 2;
	my $move = Game::Checkers::Move->new(
		from => 23,
		to => 7,
		path => [23, 14, 7],
		captures => [18, 10],
		captured => [1, 2],
		promoted => 0,
		king => 1,
		side => 'white'
	);
	my $raw = $move->to_raw;
	my $back = Game::Checkers::Move->from_raw($raw, 'white');
	is $back->notation, $move->notation, 'the same move';
	is_deeply $back->captured, [1, 2], 'and a jumped king is still a king';
};

subtest 'FEN round trips' => sub {
	plan tests => 4;
	my @fen = (
		'B:W21,22,23,24,25,26,27,28,29,30,31,32:B1,2,3,4,5,6,7,8,9,10,11,12',
		'W:WK5:BK28',
		'B:WK1,K2,K3:BK30,K31,K32',
		'W:W:B1',
	);
	for my $fen (@fen) {
		my ($position, $turn) = Game::Checkers::Notation::position_from_fen($fen);
		is Game::Checkers::Notation::fen_from_position($position, $turn), $fen,
			"round trip: $fen";
	}
};

subtest 'what is not a FEN' => sub {
	plan tests => 6;
	my %bad = (
		'B:W21'                 => 'only one piece list',
		'X:W21:B1'              => 'the side to move is not a colour',
		'B:W21:B21'             => 'square 21 twice',
		'B:W33:B1'              => 'square 33',
		'B:W0:B1'               => 'square 0',
		'B:W21,zz:B1'           => 'not a square at all',
	);
	for my $fen (sort keys %bad) {
		ok !eval { Game::Checkers::Notation::position_from_fen($fen); 1 },
			"$bad{$fen} is refused";
	}
};

subtest 'strict refuses an impossible army' => sub {
	plan tests => 2;
	my $fen = 'B:W21,22,23,24,25,26,27,28,29,30,31,32:B1,2,3,4,5,6,7,8,9,10,11,12,13';
	ok eval { Game::Checkers::Notation::position_from_fen($fen); 1 },
		'thirteen black pieces is allowed by default, for a composed problem';
	ok !eval { Game::Checkers::Notation::position_from_fen($fen, strict => 1); 1 },
		'and refused under strict';
};

subtest 'PDN round trips' => sub {
	plan tests => 4;
	my $game = {
		tags => {
			Event => 'Test',
			Site => 'peer2peergames.com',
			Date => '2026.09.13',
			Round => '1',
			White => 'Bot',
			Black => 'Player',
		},
		moves => [qw/11-15 23-19 8-11 22-17 9-14 25-22 15x24 28x19/],
		result => '1/2-1/2',
	};

	my $text = Game::Checkers::Notation::format_pdn($game);
	like $text, qr/^\[Event "Test"\]/, 'the tags come first';
	like $text, qr/1\. 11-15 23-19 2\. 8-11 22-17/, 'the moves are numbered in pairs';

	my $parsed = Game::Checkers::Notation::parse_pdn($text);
	is_deeply $parsed->{moves}, $game->{moves}, 'the moves come back';
	is Game::Checkers::Notation::format_pdn($parsed), $text,
		'and a second pass through is byte for byte the same';
};

subtest 'PDN tolerates what people write' => sub {
	plan tests => 4;
	my $text = <<'PDN';
[Event "Comments"]

1. 11-15 {a good start} 23-19 ; and a reply
2. 8-11 22-17 0-1
PDN
	my $parsed = Game::Checkers::Notation::parse_pdn($text);
	is_deeply $parsed->{moves}, [qw/11-15 23-19 8-11 22-17/], 'comments are discarded';
	is $parsed->{result}, '0-1', 'the result is read';
	is $parsed->{tags}{Event}, 'Comments', 'and so are the tags';

	ok !eval { Game::Checkers::Notation::parse_pdn("1. 11-15 wibble\n"); 1 },
		'a token that is not a move is refused';
};

subtest 'a game record that does not replay is not a game record' => sub {
	plan tests => 6;
	# Notation knows nothing of the rules, so the check that a game is playable
	# belongs to Game::Checkers, which replays it
	require Game::Checkers;

	my $game = Game::Checkers->new;
	$game->move($_) for qw/11-15 23-19 8-11 22-17/;
	my $text = $game->to_pdn(Event => 'Round trip', Black => 'Me');

	my $replayed = Game::Checkers->from_pdn($text);
	is $replayed->ply, 4, 'four moves replayed';
	is $replayed->to_fen, $game->to_fen, 'to the same position';
	is $replayed->to_pdn(Event => 'Round trip', Black => 'Me'), $text,
		'and it writes itself out the same way';

	# 22-16 is not a move any piece on 22 can make, in any position
	(my $tampered = $text) =~ s/22-17/22-16/;
	ok !eval { Game::Checkers->from_pdn($tampered); 1 },
		'an illegal move is refused';
	like $@, qr/move 4/, 'naming which move it was';

	my $from_position = Game::Checkers->new(fen => 'B:W29:BK15');
	like $from_position->to_pdn, qr/\[FEN "B:W29:BK15"\].*\[SetUp "1"\]/s,
		'a game that did not start from the opening carries its position';
};

done_testing;
