#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes::Notation qw(
	tile_text parse_tile move_text parse_move to_text from_text to_layout
);
use Game::Dominoes::Layout;
use Game::Dominoes::Tile;

plan tests => 7;

sub tile { Game::Dominoes::Tile->of(@_) }

subtest 'a tile' => sub {
	plan tests => 6;

	is tile_text(tile(4, 6)), '6-4', 'a tile prints higher face first';
	is parse_tile('6-4')->id, tile(6, 4)->id, 'and reads back as the same tile';
	is parse_tile('4-6')->id, tile(6, 4)->id, 'either way round';
	is parse_tile('0-0')->stringify, '0-0', 'the double blank survives the trip';

	ok !eval { parse_tile('7-1'); 1 }, 'a face above six is not a tile';
	ok !eval { parse_tile('64'); 1 }, 'and neither is a bare number';
};

subtest 'a move' => sub {
	plan tests => 8;

	is move_text({ kind => 'pass' }), 'P', 'a pass is P';
	is move_text({ kind => 'hand_end' }), '|', 'the end of a hand is a bar';
	is move_text({ kind => 'draw' }), 'D', 'one draw is D';
	is move_text({ kind => 'draw', count => 3 }), 'D3', 'three draws is D3';
	is move_text({ kind => 'draw', count => 1 }), 'D',
		'and a count of one is still just D, so the text has one spelling';

	is move_text({ tile => tile(6, 4), arm => 'L' }), '6-4@L', 'a play names its arm';
	is move_text({ tile => tile(6, 6), arm => 'L', spinner => 1 }), '6-6@L*',
		'and a star marks the play that made the spinner';

	is move_text(Game::Dominoes::Layout->new->place(tile(5, 5), 'L')), '5-5@L*',
		'a real Play object prints the same way';
};

subtest 'parsing a move' => sub {
	plan tests => 9;

	is_deeply parse_move('P'), { kind => 'pass' }, 'P is a pass';
	is_deeply parse_move('|'), { kind => 'hand_end' }, 'a bar ends the hand';
	is_deeply parse_move('D'), { kind => 'draw', count => 1 }, 'D is one draw';
	is_deeply parse_move('D3'), { kind => 'draw', count => 3 }, 'D3 is three';

	my $play = parse_move('6-6@L*');
	is $play->{kind}, 'play', 'a play is a play';
	is $play->{tile}->stringify, '6-6', 'carrying its tile';
	is $play->{arm}, 'L', 'and its arm';
	is $play->{spinner}, 1, 'and the star came through';

	is parse_move('6-4@R')->{spinner}, 0, 'no star means no spinner';
};

subtest 'parsing refuses what it cannot read' => sub {
	plan tests => 6;

	ok !eval { parse_move('6-4@Z'); 1 }, 'there is no arm Z';
	ok !eval { parse_move('6-4'); 1 }, 'a bare tile is not a move';
	ok !eval { parse_move('D0'); 1 }, 'a draw of none is not a draw';
	ok !eval { parse_move('X'); 1 }, 'and nor is a letter nobody defined';
	ok !eval { parse_move(''); 1 }, 'an empty token dies';
	ok !eval { parse_move(undef); 1 }, 'and so does no token at all';
};

subtest 'a whole sequence round-trips' => sub {
	plan tests => 6;

	my $text = '5-5@L* 5-2@L D2 5-3@R P 6-5@U |';

	my $moves = from_text($text);
	is scalar(@$moves), 7, 'seven tokens come back as seven moves';
	is to_text($moves), $text, 'and go back out as the same line';

	# from_text(to_text(from_text($x))) is where a notation with two spellings
	# for one move shows up.
	is to_text(from_text(to_text($moves))), $text, 'twice round changes nothing';

	# A tile has exactly one spelling, higher face first, so a text written
	# the other way round normalises rather than round-tripping unchanged.
	# This is why the line above says 6-5@U and not 5-6@U.
	is to_text(from_text('5-6@U')), '6-5@U',
		'a tile written low face first comes back canonical';

	is_deeply from_text(''), [], 'empty text is no moves, not an error';
	is_deeply from_text(undef), [], 'and neither is no text at all';
};

subtest 'whitespace is not significant' => sub {
	plan tests => 2;

	# The @ in an arm interpolates in a double-quoted Perl string, so a
	# fixture written that way needs escaping. Single quotes elsewhere in
	# this file are why nothing else here trips over it.
	is to_text(from_text("  5-5\@L*   5-2\@L \n 5-3\@R  ")), '5-5@L* 5-2@L 5-3@R',
		'runs of whitespace, leading and trailing, all collapse';
	is scalar @{ from_text("   ") }, 0, 'and whitespace alone is no moves';
};

subtest 'to_layout draws the table, and is not a saved game' => sub {
	plan tests => 4;

	my $layout = to_layout('5-5@L* 5-2@L D2 5-3@R P 6-5@U');

	is $layout->count, 4, 'the draws and the pass changed a hand, not the table';
	is $layout->spinner->stringify, '5-5', 'the spinner came back';
	is $layout->sides_covered, 2, 'with both its sides covered';
	is_deeply [ sort { $a <=> $b } map { $_->{face} } $layout->ends ], [ 2, 3, 6 ],
		'and the ends are where they were left';
};
