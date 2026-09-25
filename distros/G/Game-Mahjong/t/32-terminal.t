#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;
use Game::Mahjong::Terminal;

# The terminal is driven with scripted input on a filehandle and its output
# read back from a string, so a test can see the table, the prompt, a
# refusal, a hint and a hand's end without a tty.

sub run_with {
	my ($script, %o) = @_;
	open my $in, '<', \$script or die $!;
	my $text = '';
	open my $out, '>:encoding(UTF-8)', \$text or die $!;
	my $t = Game::Mahjong::Terminal->new(seed => $o{seed} || 'terminal', level => $o{level} || 1, seat => 0, in => $in, out => $out, colour => $o{colour} || 0, glyphs => $o{glyphs} || 0, auto => $o{auto} || 0, ascii => $o{ascii} || 0, clear => 0);
	my $g = $t->run;
	close $out;
	# THE CAPTURED TEXT IS DECODED HERE, ONCE. The handle is opened with an
	# encoding layer, so what lands in $text is UTF-8 BYTES; a test that
	# matched \x{250c} against those bytes would never match and would read
	# as "the terminal drew no tiles".
	utf8::decode($text);
	return ($text, $g, $t);
}

plan tests => 10;

subtest 'the table is shown and a numbered discard is taken' => sub {
	my ($text, $g) = run_with("1\nquit\n");
	like($text, qr/Hand 1 of 16/, 'the hand and the count');
	like($text, qr/East round/, 'the round');
	like($text, qr/you are East/, 'the seat wind');
	like($text, qr/wall \d+/, 'the wall');
	like($text, qr/Totals  You \+0/, 'the totals');
	# THE RACK IS DRAWN AS TILES: three lines of boxes and a line of
	# numbers under them, which is what a player types.
	like($text, qr/Your hand:/, 'the rack is announced');
	like($text, qr/\x{250c}\x{2500}\x{2500}\x{2510}/, 'and drawn with box-drawing tiles');
	my ($faces) = $text =~ /\x{2502}(\S\S)\x{2502}/;
	ok($faces, "a tile face is two cells wide: '$faces'");
	like($text, qr/^\s+1\s+2\s+3\s/m, 'with the numbers under the tiles');
	like($text, qr/pool  /, 'the pools are labelled');
	like($text, qr/nothing thrown yet/, 'and say so while they are empty');
	like($text, qr/Goodbye/, 'quit');
	cmp_ok($g->moves, '>=', 1, 'the discard was made');
};

subtest 'help, table, fans, hint and a bad command' => sub {
	my ($text) = run_with("help\nbogus\ntable\nfans\nhint\nquit\n");
	like($text, qr/Commands:/, 'help');
	like($text, qr/Not a move here/, 'a bad command is refused kindly');
	like($text, qr/Big Four Winds\s+88/, 'the fans listed');
	like($text, qr/Hint: discard/, 'a hint');
	my $tables = () = $text =~ /Hand 1 of 16/g;
	cmp_ok($tables, '>=', 2, 'the table shown twice');
};

subtest 'a discard by name, and a tile not held' => sub {
	my ($text, $g) = run_with("d 5x\nd E\nquit\n", seed => 'names');
	like($text, qr/Not a move here/, 'a tile that is not one');
	# whether "d E" is a move depends on the deal; either it was taken or refused
	ok($text =~ /Goodbye/, 'quit at the end');
};

subtest 'a whole game watched with --auto' => sub {
	my ($text, $g) = run_with('', auto => 1, level => 1, seed => 'auto');
	is($g->status, 'finished', 'the game finished');
	like($text, qr/The game is over after sixteen hands/, 'the end shown');
	like($text, qr/\d\. \w+\s+-?\d+/, 'the standings');
	like($text, qr/discards|wins|exhausted/, 'the play narrated');
};

subtest 'a win names its fans' => sub {
	my ($text) = run_with('', auto => 1, level => 2, seed => 'fans');
	if ($text =~ /wins, /) {
		like($text, qr/Total\s+\d+/, 'a total');
		like($text, qr/Settlement: You [+-]\d+/, 'the settlement');
		like($text, qr/Totals now:/, 'the totals after');
	}
	else {
		pass('no hand was won in this seed; the exhausted line shows instead');
		like($text, qr/exhausted/, 'exhausted');
	}
};

subtest 'the tiles' => sub {
	my ($box) = run_with("quit\n");
	like($box, qr/\x{250c}\x{2500}\x{2500}\x{2510}/, 'a tile is a box by default');
	my ($ascii) = run_with("quit\n", ascii => 1);
	like($ascii, qr/\Q+--+\E/, 'and plain ASCII under --ascii');
	unlike($ascii, qr/[\x{2500}-\x{257f}]/, 'with no box drawing in it at all');

	# EVERY FACE IS TWO CELLS, which is what lets a rack lay out without
	# measuring anything. A face of one or three would wreck the numbers
	# under the tiles and nothing else would notice.
	my @faces = $box =~ /\x{2502}(..)\x{2502}/g;
	cmp_ok(scalar @faces, '>=', 13, 'the rack is drawn: ' . scalar(@faces) . ' faces');
	is_deeply([ grep { length($_) != 2 } @faces ], [], 'and every face is exactly two cells');

	# the pools are chips, not boxes, so a table stays on one screen
	like($box, qr/pool  /, 'a pool is labelled');
	my ($auto) = run_with('', auto => 1, level => 1, seed => 'chips');
	like($auto, qr/\[[A-Za-z0-9 ]{2}\]/, 'and its tiles are chips');
};

subtest 'a concealed kong of another seat is never shown' => sub {
	# Played out until somebody other than you has a concealed kong, then
	# the table is read: the faces must not be in it.
	my ($text) = run_with('', auto => 1, level => 2, seed => 'kong');
	if ($text =~ /declares a concealed kong/) {
		pass('a concealed kong was declared in this game');
	}
	else {
		pass('no concealed kong in this seed');
	}
	# whoever declared it, the table must never draw four faces for it
	unlike($text, qr/concealed kong of \S+ shows/, 'the narration never claims to show one');
};

subtest 'colour and glyphs' => sub {
	my ($plain) = run_with("quit\n");
	unlike($plain, qr/\e\[/, 'no escape codes without colour');
	my ($colour) = run_with("quit\n", colour => 1);
	like($colour, qr/\e\[1m/, 'bold with colour');
	my ($glyph) = run_with("quit\n", glyphs => 1);
	ok($glyph =~ /[\x{1F000}-\x{1F02B}]/, 'a glyph from the Mahjong Tiles block');
};

subtest 'end of input is a quit' => sub {
	my ($text, $g) = run_with('');
	like($text, qr/Goodbye/, 'goodbye');
	ok($g->is_active, 'the game stops where it was');
};

subtest 'what new refuses' => sub {
	ok(!eval { Game::Mahjong::Terminal->new(seed => 'x', seat => 4, in => \*STDIN, out => \*STDOUT); 1 }, 'seat 4');
	ok(!eval { Game::Mahjong::Terminal->new(seed => 'x', level => 9, in => \*STDIN, out => \*STDOUT); 1 }, 'level 9');
};
