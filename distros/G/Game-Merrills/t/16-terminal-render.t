#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Test::Position qw/p position_of/;
use Game::Merrills::Test::Screen qw/terminal/;

sub board {
	my ($terminal) = @_;
	return join "\n", @{ $terminal->board_lines };
}

sub game_of {
	my (@moves) = @_;
	my $game = Game::Merrills->new;
	for my $move (@moves) {
		my $played = $game->move($move);
		die "$move: " . $played->message if ref $played eq 'Game::Merrills::Error';
	}
	return $game;
}

# THIS BOARD IS TYPED BY HAND, not printed by the code and pasted back. A
# golden file the code wrote compares the code with itself.
#
# The first one typed, and the one in the plan, were WRONG: the row between
# ranks 3 and 2 was a copy of the row above it, with a c and an e line that
# stop at rank 3. The code, which draws from the table of mills, was right.
# So the hand-typed board is itself checked below: the board is the same
# upside down and back to front.
my $OPENING = <<'BOARD';
7  .-----------.-----------.
   |           |           |
6  |   .-------.-------.   |   White
   |   |       |       |   |   in hand 9  on the board 0  lost 0
5  |   |   .---.---.   |   |   W W W W W W W W W
   |   |   |       |   |   |
4  .---.---.       .---.---.   Black
   |   |   |       |   |   |   in hand 9  on the board 0  lost 0
3  |   |   .---.---.   |   |   B B B B B B B B B
   |   |       |       |   |
2  |   .-------.-------.   |
   |           |           |
1  .-----------.-----------.
   a   b   c   d   e   f   g
BOARD
chomp $OPENING;

subtest 'the empty board, to the character' => sub {
	my ($terminal) = terminal('');
	is(board($terminal), $OPENING, 'three squares, four spokes, and the two sides beside it');
};

subtest 'the empty board is the same upside down and back to front' => sub {
	my ($terminal) = terminal('');
	my @rows = map { sprintf '%-25s', substr $_, 3, 25 } @{ $terminal->board_lines }[ 0 .. 12 ];
	is_deeply([ reverse @rows ], \@rows, 'top to bottom');
	is_deeply([ map { scalar reverse } @rows ], \@rows, 'left to right');
	is(scalar(() = join('', @rows) =~ m/\./g), 24, 'with twenty-four points');
};

subtest 'every point is drawn where its name says' => sub {
	for my $point (Game::Merrills::Points::all_points()) {
		my $name = Game::Merrills::Points::name($point);
		my ($terminal) = terminal('', game => Game::Merrills->new(position => position_of(
			white => [$name], hand => { white => 8, black => 9 },
		)));
		my @lines = @{ $terminal->board_lines };
		my ($file, $rank) = $name =~ m/^(.)(.)$/;
		my ($row) = grep { $lines[$_] =~ m/^$rank / } 0 .. $#lines;
		my $col = index $lines[-1], $file;
		is(substr($lines[$row], $col, 1), 'W', "$name: the W is on rank $rank under the letter $file");
		is(scalar(() = join('', map { substr $_, 0, 28 } @lines[ 0 .. 12 ]) =~ m/W/g), 1,
			"$name: and nowhere else on the board");
	}
};

subtest 'a game in progress: men, hands, and what was lost' => sub {
	my ($terminal) = terminal('', game => game_of(qw/a7 b4 d7 e5 g7xb4 a1 d6 d1/));
	my $expect = <<'BOARD';
7  W-----------W-----------W
   |           |           |
6  |   .-------W-------.   |   White
   |   |       |       |   |   in hand 5  on the board 4  lost 0
5  |   |   .---.---B   |   |   W W W W W
   |   |   |       |   |   |
4  .---.---.       .---.---.   Black
   |   |   |       |   |   |   in hand 5  on the board 3  lost 1
3  |   |   .---.---.   |   |   B B B B B
   |   |       |       |   |
2  |   .-------.-------.   |
   |           |           |
1  B----------(B)----------.
   a   b   c   d   e   f   g
BOARD
	chomp $expect;
	is(board($terminal), $expect, 'eight plies in, the last of them marked');
};

subtest 'the three marks of a move, and they are shapes' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4 e5/],
	));
	$game->move('g4-g7xb4');
	my ($terminal) = terminal('', game => $game);
	my @lines = @{ $terminal->board_lines };
	like($lines[0], qr/^7  W-----------W----------\(W\)$/, 'the man that moved: (W) on g7');
	like($lines[6], qr/^4  \.--\(x\)--\.       \.---\.--\(\.\)/, 'the man taken: (x) on b4, and the point left: (.) on g4');
	unlike(board($terminal), qr/\e/, 'with no escape anywhere');

	$terminal->highlight({ p('d6') => 'candidate', p('a1') => 'takeable' });
	@lines = @{ $terminal->board_lines };
	like($lines[2], qr/^6  \|   \.------\[\.\]------\.   \|/, 'a move considered: [.] on d6');
	like($lines[12], qr/^1 \{B\}----------B-----------\.$/, 'a man that could be taken: {B} on a1');
	like($lines[0], qr/\(W\)$/, 'and the marks of the last move are still there beside them');

	$terminal->highlight({ p('g7') => 'candidate' });
	like($terminal->board_lines->[0], qr/\[W\]$/, 'a mark given later goes on top of one from the last move');
};

subtest 'a marked point is exactly as wide as an unmarked one' => sub {
	my ($plain) = terminal('');
	my ($marked) = terminal('');
	$marked->highlight({ map { $_ => 'candidate' } Game::Merrills::Points::all_points() });
	my @one = @{ $plain->board_lines };
	my @two = @{ $marked->board_lines };
	for my $row (0 .. 12) {
		(my $unmarked = substr $two[$row], 0, 29) =~ tr/[]/  /;
		(my $bare = sprintf '%-29s', substr $one[$row], 0, 29) =~ tr/-/ /;
		$unmarked =~ tr/-/ /;
		is(sprintf('%-29s', $unmarked), $bare, "row $row: with the brackets taken out, every point and bar is where it was");
	}
	is(scalar(() = join('', @two) =~ m/\[\.\]/g), 24, 'twenty-four points, twenty-four pairs of brackets');
	is($two[6], '4 [.]-[.]-[.]     [.]-[.]-[.]  Black', 'and what stands beside the board has not moved');
	is(index($two[6], 'Black'), index($one[6], 'Black'), 'not by a column');
};

subtest 'no line ends in a space, in any mode' => sub {
	my $game = game_of(qw/a7 b4 d7 e5 g7xb4 a1 d6 d1 f6 g1xd6 b6 c3/);
	for my $mode ([ ascii => 1, colour => 0 ], [ ascii => 0, colour => 0 ],
		[ ascii => 0, colour => 1 ], [ ascii => 1, colour => 1 ]) {
		my %mode = @{$mode};
		my ($terminal) = terminal('', game => $game, %mode, human => 'white');
		my @lines = (@{ $terminal->board_lines }, @{ $terminal->status_lines });
		is(scalar(grep { m/[ \t]$/ } @lines), 0,
			"ascii $mode{ascii}, colour $mode{colour}: none of " . scalar(@lines) . ' lines');
	}
};

subtest 'ascii and no colour is plain ASCII and nothing else' => sub {
	my ($terminal, $screen) = terminal('', game => game_of(qw/a7 b4 d7 e5 g7xb4/), human => 'white');
	$terminal->render;
	unlike($$screen, qr/\e/, 'no escape');
	unlike($$screen, qr/[^\x0a\x20-\x7e]/, 'no byte outside printable ASCII and newline');
	like($$screen, qr/White \(you\)/, 'and it says which side you are');
};

subtest 'drawn without colour: lines and discs, as UTF-8' => sub {
	my ($terminal, $screen) = terminal('', game => game_of(qw/a7 b4/), ascii => 0);
	$terminal->render;
	unlike($$screen, qr/\e/, 'no escape');
	my $text = $$screen;
	ok(utf8::decode($text), 'what was written is valid UTF-8');
	like($text, qr/\x{25CB}\x{2500}{11}\x{00B7}/, 'a hollow white disc, eleven line pieces and an empty point');
	like($text, qr/\x{25CF}/, 'a solid black disc');
	like($text, qr/\x{2502}/, 'and upright line pieces');
	unlike($text, qr/[-|]/, 'with no dash or bar left over') ;
};

subtest 'painted: every colour is closed, and the things that differ are painted differently' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4 e5/],
	));
	$game->move('g4-g7xb4');
	my ($terminal) = terminal('', game => $game, ascii => 0, colour => 1, human => 'white');
	$terminal->highlight({ p('d6') => 'candidate', p('a1') => 'takeable' });
	my @lines = (@{ $terminal->board_lines }, @{ $terminal->status_lines });
	is(scalar(grep { m/\e\[/ && (m/.*(\e\[[0-9;]*m)/s)[0] ne "\e[0m" } @lines), 0,
		'the last colour code on every painted line puts the colour back');

	my $board = join "\n", @{ $terminal->board_lines };
	my %ground = %Game::Merrills::Terminal::GROUND;
	for my $kind (qw/board mill last left taken candidate takeable/) {
		like($board, qr/\Q$ground{$kind}\Em/, "the $kind ground is on the board");
	}
	my %seen = map { $_ => 1 } values %ground;
	is(scalar keys %seen, scalar keys %ground, 'and no two grounds are the same colour');

	my %ink = %Game::Merrills::Terminal::INK;
	isnt($ink{white}, $ink{black}, 'white men and black men are different inks');
	isnt($ink{you}, $ink{them}, 'and so are your name and theirs');
	like($board, qr/\(/, 'the brackets are still drawn under the paint');
};

subtest 'ascii with colour: painted, and still nothing but ASCII under the paint' => sub {
	my ($terminal) = terminal('', game => game_of(qw/a7 b4 d7 e5 g7xb4/), ascii => 1, colour => 1);
	my $board = join "\n", @{ $terminal->board_lines };
	like($board, qr/\e\[/, 'it is painted');
	(my $bare = $board) =~ s/\e\[[0-9;]*m//g;
	unlike($bare, qr/[^\x0a\x20-\x7e]/, 'and with the paint taken off, every character is plain ASCII');
	like($bare, qr/^7  W-----------W----------\(W\)/m, 'letters, dashes and brackets');
};

subtest 'colour off means no colour, whatever else is on' => sub {
	my ($terminal, $screen) = terminal("help\nmoves\nhint\nd4\n", colour => 0);
	$terminal->start;
	unlike($$screen, qr/\e/, 'a whole session with help, moves, a hint and a refusal has no escape in it');
};

subtest 'under the board' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3 e3/], black => [qw/a1 d1 g1 b4 e5/],
	));
	my ($terminal) = terminal('', game => $game, human => 'white');
	$terminal->played($game->move('g4-g7xb4'));
	is_deeply($terminal->status_lines, [
		'You moved g4 to g7, closed a mill and took the black man on b4.',
		'White mill: a7-d7-g7',
		'Black mill: a1-d1-g1',
		'Black to move.',
	], 'the move in words, the mills, and whose turn it is');

	$terminal->played($game->move('e5-e4'));
	is($terminal->status_lines->[-1], 'White (you) to move.', 'your turn says so');
	is($terminal->status_lines->[1], 'Black moved e5 to e4.', 'and their move is in words too');

	$terminal->played($game->move('c3-c4'));
	is(scalar(grep { m/ moved | placed | flew / } @{ $terminal->status_lines }), 2,
		'only the last two moves are kept');
	unlike(join("\n", @{ $terminal->status_lines }), qr/closed a mill/, 'the capture has scrolled away');
};

subtest 'what a turn is called in each phase' => sub {
	my ($placing) = terminal('');
	is($placing->status_lines->[-1], 'White to place, 9 in hand.', 'placing');

	my ($flying) = terminal('', game => Game::Merrills->new(position => position_of(
		white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2 c3/],
	)));
	is($flying->status_lines->[-1], 'White to move, and flying.', 'flying');

	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7/], black => [qw/a1 d6/], hand => { white => 7, black => 7 }, turn => 'black',
	));
	my ($taken) = terminal('', game => $game, human => 'white');
	is($taken->narrate($game->move('g1')), 'Black placed a man on g1.', 'a placement in words');
	is($taken->narrate($game->move('g7xa1')), 'You placed a man on g7, closed a mill and took the black man on a1.',
		'your capture');
	$game->move('a1');
	$game->move('b6');
	is($taken->narrate($game->move('d1xb6')), 'Black placed a man on d1, closed a mill and took your man on b6.',
		'and theirs, of yours');

	my $double = Game::Merrills->new(position => position_of(
		white => [qw/a7 g7 d6 d5/], black => [qw/a1 g1 b2 f2/], hand => { white => 5, black => 5 },
	));
	my ($two) = terminal('', game => $double);
	is($two->narrate($double->move('d7xb2')), 'White placed a man on d7, closed two mills and took the black man on b2.',
		'two mills at once are said to be two');

	my $flight = Game::Merrills->new(position => position_of(
		white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2 c3/],
	));
	my ($flew) = terminal('', game => $flight);
	is($flew->narrate($flight->move('a7-e3')), 'White flew a7 to e3.', 'a flight is called one');
};

subtest 'the warning on the way to a draw, the offer, and the result' => sub {
	my $limit = Game::Merrills::NO_MILL_PLIES;
	my %men = (white => [qw/a7 b2 e3 g1/], black => [qw/f6 c5 d2 b4/]);
	my ($early) = terminal('', game => Game::Merrills->new(position => position_of(%men, no_mill => int($limit / 2) - 1)));
	unlike(join("\n", @{ $early->status_lines }), qr/No mill/, 'under half way there is no warning');
	my ($late) = terminal('', game => Game::Merrills->new(position => position_of(%men, no_mill => int(($limit + 1) / 2))));
	like(join("\n", @{ $late->status_lines }), qr/^No mill for \d+ moves: it is a draw at $limit\.$/m,
		'from half way there is, and it names the limit');

	my ($offer) = terminal('');
	$offer->game->offer_draw('white');
	is($offer->status_lines->[-1], 'White has offered a draw: accept or decline.', 'a standing offer is shown');

	my ($over) = terminal('');
	$over->game->resign('black');
	is($over->status_lines->[-1], 'White wins: Black resigned', 'the result is the last line');
	unlike(join("\n", @{ $over->status_lines }), qr/to place|to move/, 'and nobody is told it is their turn');
};

subtest 'switching between ascii and drawn while running' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my ($terminal, $screen) = terminal('', game => game_of(qw/a7 b4/));
	$terminal->render;
	my $mark = length $$screen;
	$terminal->command('ascii');
	$terminal->render;
	my $drawn = substr $$screen, $mark;
	ok(utf8::decode($drawn), 'after the switch the output is UTF-8');
	like($drawn, qr/\x{2500}/, 'with drawn lines in it');

	$mark = length $$screen;
	$terminal->command('ascii');
	$terminal->render;
	unlike(substr($$screen, $mark), qr/[^\x0a\x20-\x7e]/, 'and switched back it is plain ASCII again');
	is_deeply(\@warnings, [], 'with no warning either way, wide character or otherwise');

	$terminal->command('colour');
	$mark = length $$screen;
	$terminal->render;
	like(substr($$screen, $mark), qr/\e\[/, 'the colour command turns the paint on');
	$terminal->command('color');
	$mark = length $$screen;
	$terminal->render;
	unlike(substr($$screen, $mark), qr/\e\[/, 'and, spelt the other way, off again');
};

done_testing;
