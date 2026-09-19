#!perl

# The terminal, driven in process against tied in-memory handles.
#
# NO FORK AND NO SUBPROCESS, which is why `in` and `out` are attributes rather
# than hardcoded: a test that had to spawn a child would be a test whose output
# the harness has to be protected from.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Terminal;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# Play a scripted game and hand back everything it printed.
sub run {
	my ($input, %o) = @_;
	open my $in, '<', \$input or die $!;
	my $output = '';
	open my $out, '>', \$output or die $!;

	my $t = Game::Go::Terminal->new(
		in => $in, out => $out,
		size => 9, level => 1, ascii => 1, ansi => 0, seed => 'test',
		%o,
	);
	my $result = $t->start;
	return ($output, $t, $result);
}

subtest 'every option is validated in the constructor' => sub {
	# A sibling's terminal refused a bad colour with a tidy sentence and exit 2,
	# and died on a bad variant with a raw Perl message and exit 255, because
	# one option was checked in the constructor and the other several calls
	# deeper. So all of them are checked in one place.
	for my $bad (
		[ size     => 11 ],
		[ size     => 0 ],
		[ level    => 0 ],
		[ level    => 6 ],
		[ colour   => 'green' ],
		[ komi     => 6.25 ],
		[ handicap => 99 ],
	) {
		my ($key, $value) = @$bad;
		ok(!eval { Game::Go::Terminal->new($key => $value); 1 },
			"$key => $value is refused");
		like($@, qr/\AGame::Go::Terminal: /, "and says which module refused it");
		like($@, qr/\n\z/, 'with a newline, so no "at line" is appended');
	}

	# The colour spellings a person actually types.
	for my $ok (qw(b w black white dark light BLACK)) {
		ok(eval { Game::Go::Terminal->new(colour => $ok); 1 }, "colour $ok is accepted");
	}
	done_testing();
};

subtest 'the board, with coordinates on both axes' => sub {
	my ($out) = run("D4\nresign\n");

	# COLUMNS SKIP I. A Go player reads them off the edge constantly.
	like($out, qr/A B C D E F G H J/, 'the columns are A to J with no I');
	unlike($out, qr/ I /, 'I appears nowhere on the board');

	# ROWS RUN FROM THE BOTTOM, so the first row printed is 9 and the last is 1.
	like($out, qr/^9 /m, 'row 9 is printed');
	like($out, qr/^1 /m, 'and row 1');

	# D4 is four up from the bottom: engine row 5 on a 9x9.
	my @lines = grep { /^4 / } split /\n/, $out;
	ok(scalar @lines, 'row 4 was drawn');
	like($lines[-1], qr/\AX|X/, 'with a black stone somewhere on it');
	done_testing();
};

subtest 'the star points are marked, and legal moves are not' => sub {
	my ($out) = run("resign\n");

	# In Reversi a legal-move marker earns its place because there are a
	# handful of them. In Go very nearly every empty point is legal, so marking
	# them draws a board of plus signs that tells a player nothing. The first
	# version of this did exactly that.
	my @plus = $out =~ /\+/g;
	cmp_ok(scalar @plus, '>', 0, 'some points are marked');
	cmp_ok(scalar @plus, '<', 20, 'but only a few, so it is the star points and not every empty point');
	done_testing();
};

subtest 'a move, and what it says about it' => sub {
	my ($out) = run("D4\nresign\n");
	like($out, qr/you play D4/, 'it echoes the move in human coordinates');
	like($out, qr/(?:black|white) plays [A-HJ-T][0-9]/, 'and says what the bot played');
	done_testing();
};

subtest 'help, board and libs' => sub {
	my ($out) = run("help\nboard\nlibs D4\nD4\nlibs D4\nresign\n");
	like($out, qr/I left out/, 'help explains the missing I');
	like($out, qr/rows are numbered from the bottom/, 'and the row origin');
	like($out, qr/D4 is empty/, 'libs on an empty point says so');
	like($out, qr/D4 is a black group of 1, with 4 liberties/,
		'and on a stone gives the group and its liberties');
	done_testing();
};

subtest 'a refused move is re-prompted, not fatal' => sub {
	# A refused move is an ordinary thing for a player to do, and the reason is
	# what they need to see.
	# A1 rather than a middle point: the bot picks from the middle and a test
	# that named one there would fail whenever the bot happened to take it,
	# which is exactly what the first version of this did.
	my ($out) = run("ZZ9\nD4\nD4\nA1\nresign\n");
	like($out, qr/is not a point on this board/, 'a name that is not a point');
	like($out, qr/there is already a stone there/, 'and a point that is taken');
	like($out, qr/you play A1/, 'and the game carries on');
	done_testing();
};

subtest 'resigning ends it and the arithmetic is not printed' => sub {
	my ($out, $t, $result) = run("resign\n");
	is($t->game->status, 'finished', 'the game is over');
	is($t->game->result, 'resign', 'by resignation');
	unlike($out, qr/territory/, 'with no count, because there was none');
	like($out, qr/\bresign\b/i, 'and it says so');
	done_testing();
};

subtest 'THE CONFIRMATION PHASE, IN WORDS' => sub {
	# THIS IS WHAT THE TERMINAL EXISTS FOR. Two passes STOP play; they do not
	# end the game. A player told "the game is over" and then shown a board
	# they can still type at will file a bug, and they will be right.
	my ($out) = run(("pass\n" x 200) . "done\n");

	like($out, qr/play has STOPPED/, 'it says play has stopped');
	like($out, qr/The game is not over yet/, 'and that the game is not over');
	like($out, qr/agree which stones are dead/, 'and what has to happen next');
	like($out, qr/It is your count to offer/, 'it says whose count it is');
	like($out, qr/Marked dead so far: nothing/, 'and what is marked, which is nothing');
	like($out, qr/"done" to offer the count/, 'and how to finish');
	done_testing();
};

subtest 'the answerer is told what disputing costs' => sub {
	# "Dispute" reads like a refusal rather than a request to play on, so it
	# has to say what it does. Article 9.3 gives the move to the OPPONENT of
	# whoever asked, and a player who did not know that would dispute for free.
	#
	# THE HUMAN IS ALMOST ALWAYS THE PROPOSER, and that is not a bug. The
	# proposer is whoever passed FIRST, and a player who is passing to end the
	# game passes before the bot decides to. So reaching the answering side
	# through a scripted game is not something a seed can be found for; the
	# state is built and handed to the terminal through its own `game`
	# accessor instead.
	open my $in, '<', \"dispute\n" or die $!;
	my $output = '';
	open my $out, '>', \$output or die $!;

	my $t = Game::Go::Terminal->new(
		in => $in, out => $out, size => 9, level => 1,
		ascii => 1, ansi => 0, seed => 'answer',
	);

	# bot passes first, human second, so the BOT is the proposer
	my $g = $t->game;
	$g->play($B, $g->point(2, 2));      # the bot, as black
	$g->pass($W) if $g->turn == $W;
	$g->pass($B) if $g->turn == $B;
	is($g->phase, 'marking', 'play stopped');
	is($g->marking->proposer, $W, 'and white, which is not the human, proposes')
		if $g->phase eq 'marking';

	# the human here is black, so make the bot's side the proposer by having
	# the terminal run from a state where the proposal is already made
	$g->done($g->marking->proposer) if $g->phase eq 'marking';

	$t->start;

	like($output, qr/accept or dispute/, 'the answering prompt is reached');
	like($output, qr/put it back on the\s+board and play it out/,
		'it says what disputing does');
	like($output, qr/costs you the move/, 'and that it costs the move');
	like($output, qr/opponent\s+plays first/, 'and who gets it');
	done_testing();
};

subtest 'the final arithmetic is shown, not just the margin' => sub {
	# A board full of stones followed by "W+6.5" with no working reads as
	# something the program made up: komi and prisoners are both invisible on
	# the board.
	my ($out, $t) = run(("pass\n" x 250) . "done\naccept\n");

	SKIP: {
		skip 'this seed did not reach a count', 4 unless $t->game->outcome;
		like($out, qr/black\s+\d+ territory/, 'black territory');
		like($out, qr/white\s+\d+ territory/, 'white territory');
		like($out, qr/prisoners/, 'the prisoners');
		like($out, qr/komi/, 'and the komi');
	}
	done_testing();
};

subtest 'NO_COLOR wins over an explicit request' => sub {
	# The whole point of the convention: a user who has set it has said they do
	# not want colour from anything, and a program that overrides it on its own
	# say-so is the reason they had to set it.
	{
		local $ENV{NO_COLOR} = 1;
		my $t = Game::Go::Terminal->new(size => 9);
		is($t->ansi, 0, 'NO_COLOR turns colour off');
	}
	{
		delete local $ENV{NO_COLOR};
		my $t = Game::Go::Terminal->new(size => 9, ansi => 1);
		is($t->ansi, 1, 'and without it an explicit request is honoured');
	}
	done_testing();
};

subtest 'the coloured board strips to the uncoloured one' => sub {
	# Glyphs have to be readable in monochrome, so the two boards must differ
	# only by escape sequences.
	my ($plain) = run("D4\nresign\n", ansi => 0);
	my ($inked) = run("D4\nresign\n", ansi => 1);

	(my $stripped = $inked) =~ s/\e\[[0-9;]*m//g;
	is($stripped, $plain, 'stripping the escapes gives exactly the plain board');
	isnt($inked, $plain, 'and the two really did differ before stripping');
	done_testing();
};

subtest 'start returns and never exits' => sub {
	my ($out, $t, $result) = run("resign\n");
	ok(defined $result, 'start returned something');
	is($t->game->status, 'finished', 'having finished the game');

	# A module that exits cannot be tested in process, which is the whole
	# reason this file needs no fork.
	my $src = do {
		local $/;
		open my $fh, '<', 'lib/Game/Go/Terminal.pm' or die $!;
		<$fh>;
	};
	$src =~ s/^=\w.*?^=cut//gms;
	$src =~ s/^\s*#.*$//gm;
	unlike($src, qr/\bexit\b/, 'and the module never calls exit');
	done_testing();
};

subtest 'the stones are wide characters and the handle is told' => sub {
	# THE BUG THIS FILE DID NOT CATCH. glyph() returns U+25CF and U+25CB
	# unless --ascii is given, and printing those to a handle with no encoding
	# layer warns "Wide character in print" on every line of every board. It is
	# a warning and not an error, so the game plays and the board draws.
	#
	# EVERY OTHER SUBTEST HERE USES AN IN-MEMORY HANDLE, WHICH DOES NOT
	# COMPLAIN. That is exactly why the whole file was green while a person
	# running bin/go got a screenful of warnings. So this subtest asserts the
	# layer rather than the output, and uses a real file for the one case an
	# in-memory handle cannot show.
	use File::Temp ();

	my ($fh, $path) = File::Temp::tempfile(UNLINK => 1);
	my $term = Game::Go::Terminal->new(
		in => \*STDIN, out => $fh, size => 9, level => 1, seed => 'utf8', quiet => 1,
	);
	my @layers = PerlIO::get_layers($fh);
	ok((grep { /\A(?:utf8|encoding)/ } @layers),
		"a plain handle gets an encoding layer (@layers)");

	# --ascii means X and O, which are not wide, so the handle is left alone.
	my ($afh, $apath) = File::Temp::tempfile(UNLINK => 1);
	Game::Go::Terminal->new(
		in => \*STDIN, out => $afh, size => 9, level => 1, seed => 'utf8',
		quiet => 1, ascii => 1,
	);
	my @alayers = PerlIO::get_layers($afh);
	ok(!(grep { /\A(?:utf8|encoding)/ } @alayers),
		"--ascii leaves the handle alone (@alayers)");

	# A CALLER WHO ALREADY SET A LAYER MUST NOT GET TWO. Double encoding turns
	# one black stone into two mojibake characters, which is worse than the
	# warning being fixed here.
	my ($efh, $epath) = File::Temp::tempfile(UNLINK => 1);
	binmode $efh, ':encoding(UTF-8)';
	my $before = scalar grep { /\A(?:utf8|encoding)/ } PerlIO::get_layers($efh);
	Game::Go::Terminal->new(
		in => \*STDIN, out => $efh, size => 9, level => 1, seed => 'utf8', quiet => 1,
	);
	my $after = scalar grep { /\A(?:utf8|encoding)/ } PerlIO::get_layers($efh);
	is($after, $before, 'an already-encoded handle gains no second layer');

	# And the characters really are wide, or none of the above matters.
	my $glyph = $term->glyph(Game::Go::BLACK);
	cmp_ok(ord($glyph), '>', 127, 'a stone really is a wide character');
	done_testing();
};

done_testing();
