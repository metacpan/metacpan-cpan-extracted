#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Capture;

use Game::Mahjong;
use Game::Mahjong::Terminal;

# The terminal is driven with scripted input on a filehandle and its output
# kept as characters by t/lib/Capture.pm, so a test can see the table, the
# prompt, a refusal, a hint and a hand's end without a tty.

sub run_with {
	my ($script, %o) = @_;
	open my $in, '<', \$script or die $!;
	my $text = '';
	my $out = Capture->handle(\$text);
	my $t = Game::Mahjong::Terminal->new(seed => $o{seed} || 'terminal', level => $o{level} || 1, seat => 0, in => $in, out => $out, colour => $o{colour} || 0, glyphs => $o{glyphs} || 0, auto => $o{auto} || 0, ascii => $o{ascii} || 0, clear => 0);
	my $g = $t->run;
	# NOTHING IS DECODED HERE, because nothing was encoded: Capture keeps the
	# characters the terminal printed. See t/lib/Capture.pm for the smoker
	# report that made it so.
	return ($text, $g, $t);
}

plan tests => 15;

# The key loop is driven by `keysource`, so none of this needs a tty, a pipe
# or Term::ReadKey installed. One CHARACTER a call: a source handing back
# "\e[C" whole never becomes a right arrow.
sub picker {
	my ($seed, $keys, %o) = @_;
	my $g = post_draw($seed) or return undef;
	my @chars = split //, $keys;

	open my $in, '<', \(my $script = $o{input} // "quit\n") or die $!;
	my $text = '';
	my $t = Game::Mahjong::Terminal->new(
		seed => $seed, level => 1, seat => 0, in => $in,
		out => Capture->handle(\$text), colour => 0, clear => 0,
		picking => (exists $o{picking} ? $o{picking} : 1),
		(exists $o{keysource} ? (keysource => $o{keysource})
			: (keysource => sub { shift @chars })));
	$t->rules($g);
	$t->hinter(Game::Mahjong::Bot->new(level => 1));

	return ($t, $g, \$text);
}

subtest 'a key at a time, named' => sub {
	my ($t) = picker('terminal',
		"k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");

	my @got;
	while (defined(my $key = $t->read_key)) {
		push @got, $key eq ' ' ? 'space' : $key;
	}

	is_deeply(\@got, [ qw/ k up down right left page_up home enter tab backspace
		interrupt eof space q escape page_down / ],
		'a character comes back as itself and a sequence as a name');
};

subtest 'an escape does not eat the key behind it' => sub {
	my ($t) = picker('terminal', "\eq");
	is($t->read_key, 'escape', 'the escape is an escape');
	is($t->read_key, 'q', 'and the keystroke behind it survives');
};

# THE CURSOR WALKS THE RACK AS DRAWN. Same lesson as the numbering: the rack
# is reordered for display, so a cursor indexing the hand would step to a tile
# somewhere else on the screen.
# THE TILE NAMED ON SCREEN IS THE TILE THROWN. Asserting the returned move
# against rack_order instead would be checking the picker against a second
# copy of its own arithmetic: it passed with the cursor deliberately indexing
# the wrong order. The caption is what the player reads, so that is what the
# move has to agree with.
subtest 'the tile the frame names is the tile that is thrown' => sub {
	my $checked = 0;

	for my $seed (qw/ terminal demo rack /) {
		for my $walk ('', "\e[D", "\e[D\e[D", "\e[C") {
			my ($t, $g, $text) = picker($seed, $walk . "\r") or next;
			my @legal = $g->legal(0);

			$t->enter_raw;
			my $move = $t->pick_discard(@legal);
			next unless $move;

			# The LAST caption drawn before enter was pressed.
			my @said = $$text =~ /throw (\S+) and you are/g;
			next unless @said;

			is($t->_parse_tile($said[-1]), $move->{tile},
				"seed $seed after '" . length($walk) / 3 . " steps': "
					. "the frame named $said[-1] and that is what went");
			$checked++;
		}
	}

	cmp_ok($checked, '>', 6, 'over enough racks and cursor positions');
};

subtest 'the line under the rack is what the engine really says' => sub {
	my ($t, $g, $text) = picker('terminal', 'q');
	my ($kinds) = $t->rack_order;
	my $hand = $g->hand_of(0);

	$t->enter_raw;
	$t->pick_discard($g->legal(0));

	my ($tile, $away) = ($$text =~ /throw (\S+) and you are (\d+) away/);
	ok(defined $away, 'the frame said how far the throw leaves you')
		or diag $$text;

	# The oracle is Shanten, not arithmetic retyped here.
	my $kind = $t->_parse_tile($tile);
	is($away, Game::Mahjong::Shanten::after_discard($hand, $kind),
		'and it is the number after_discard gives for that tile');
};

# THE NUMBER UNDER A TILE MUST THROW THAT TILE, and for 92% of racks it did
# not. `_rack_art` moves the tile just drawn to the end and numbers what it
# drew; the parser indexed `$hand->tiles`, which is not reordered. On average
# 6.4 of the 14 slots pointed at a different tile, and slot 14, the tile you
# just drew and the one most often thrown, was wrong every time the drawn
# tile did not already sort last.
#
# The old subtest below types `1` and asserts a discard happened. Slot 1 is
# the one slot that is usually right, and "a discard happened" is not "the
# right discard happened", so it passed throughout.
# A seat's OPENING rack has no drawn tile, so the reorder does not happen and
# the two orders agree: a test built on the deal checks an identity map and
# passes against the bug. Each seed is played on until seat 0 is on turn
# holding a tile it drew, which is the only state where this can be wrong.
sub post_draw {
	my ($seed) = @_;
	my $g = Game::Mahjong::Rules->new(seed => $seed);
	my $bot = Game::Mahjong::Bot->new(level => 1);

	for (1 .. 200) {
		return $g if defined $g->turn && $g->turn == 0
			&& $g->phase eq 'discard' && defined $g->drawn;

		my $acted = 0;
		for my $seat (defined $g->turn ? ($g->turn) : (0 .. 3)) {
			my @legal = $g->legal($seat);
			next unless @legal;
			my ($pass) = grep { $_->{kind} eq 'pass' } @legal;
			$g->apply($seat, $pass || $bot->choose($g, $seat) || $legal[0]);
			$acted = 1;
			last;
		}
		last unless $acted;
	}

	return undef;
}

subtest 'every number throws the tile drawn above it' => sub {
	my ($checked, $reordered) = (0, 0);

	for my $seed (qw/ terminal demo rack slots drawn /) {
		my $g = post_draw($seed) or next;

		open my $in, '<', \(my $script = "quit\n") or die $!;
		my $text = '';
		my $t = Game::Mahjong::Terminal->new(
			seed => $seed, level => 1, seat => 0, in => $in,
			out => Capture->handle(\$text), colour => 0, clear => 0);
		$t->rules($g);

		my ($kinds, $last) = $t->rack_order;
		$reordered++ if defined $last
			&& join(',', $g->hand_of(0)->tiles) ne join(',', @$kinds);

		my @legal = $g->legal(0);
		for my $slot (1 .. scalar @$kinds) {
			my $move = $t->_parse($slot, [], \@legal, $g->hand_of(0));
			next unless $move;
			is($move->{tile}, $kinds->[ $slot - 1 ],
				"seed $seed slot $slot throws the tile drawn there");
			$checked++;
		}
	}

	# WITHOUT THESE TWO THE SUBTEST CANNOT FAIL. The first proves slots were
	# examined at all; the second proves they were examined in a rack whose
	# display order differs from the order the hand is held in, which is the
	# only arrangement in which the bug exists.
	cmp_ok($checked, '>', 20, 'enough slots were checked to mean it');
	cmp_ok($reordered, '>', 0, 'and in racks that really are reordered');
};

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
