#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Terminal;

# A whole game driven through the real terminal loop, in process.
#
# NO PIPE, NO FORK, NO SUBPROCESS. `in` and `out` are properties, so the loop
# under test is the actual one and not a re-implementation of it: the input is a
# tied handle that answers with a legal move when the terminal asks for one, and
# the output is a string.
#
# Driving it with a feeder rather than a pre-written script of moves is
# deliberate. A script would have to be computed by playing the same game
# somewhere else first, and would then desync into nonsense the moment anything
# about the loop changed, failing for a reason that had nothing to do with the
# change.

my $B = 'Game::Reversi::Board';

sub sq { return $B->square_of(split //, $_[0]) }

# Answers the prompt with one of the legal moves, chosen by a fixed rule.
{
	package Feeder;
	sub TIEHANDLE {
		my ($class, $terminal, $pick) = @_;
		return bless { t => $terminal, pick => $pick || 'first', asked => 0 }, $class;
	}
	sub READLINE {
		my ($self) = @_;
		$self->{asked}++;
		my $game = $self->{t}->game or return "quit\n";
		return "quit\n" if $game->status ne 'active';
		my $legal = $game->legal($self->{t}->colour);
		return "quit\n" unless @$legal;
		my $move = $self->{pick} eq 'last' ? $legal->[-1] : $legal->[0];
		return Game::Reversi::Board->name_of($move->square) . "\n";
	}
	sub asked { $_[0]{asked} }
}

sub play_through {
	my (%o) = @_;
	my $output = '';
	open my $out, '>', \$output or die $!;

	my $terminal = Game::Reversi::Terminal->new(
		out     => $out,
		level   => defined $o{level} ? $o{level} : 1,
		seed    => $o{seed} || 'terminal-test',
		variant => $o{variant} || 'historic',
		colour  => $o{colour} || 'b',
		quiet   => $o{quiet} ? 1 : 0,
		ascii   => $o{ascii} ? 1 : 0,
	);

	# The tie object is deliberately not kept: holding a reference to it makes
	# untie warn "inner references still exist" and leaves the handle tied.
	# Whatever is wanted from it has to be read out before the untie.
	my $asked;
	{
		my $feeder = tie *FEED, 'Feeder', $terminal, $o{pick};
		$terminal->in(\*FEED);
		my $result = $terminal->start;
		close $out;
		$asked = $feeder->asked;
		undef $feeder;
		untie *FEED;
		return ($result, $output, $terminal, $asked);
	}
}

subtest 'in and out are properties, so a game runs entirely in memory' => sub {
	my ($result, $output, $terminal, $asked) = play_through();

	# start RETURNS. If it called exit, nothing below this line would run, which
	# is the whole reason the exit status belongs to bin/reversi instead.
	ok($result, 'start returned a result rather than exiting');
	isa_ok($result, 'Game::Reversi::Result');

	is($terminal->game->status, 'finished', 'and the game really finished');
	cmp_ok($asked, '>', 10, 'the human was asked for a move many times');
	cmp_ok(length $output, '>', 500, 'and a good deal was printed');

	# Nothing reached the real STDOUT: every byte went to the string.
	like($output, qr/a   b   c   d   e   f   g   h/, 'the board was drawn');
	done_testing();
};

subtest 'the board is a grid, with the discs in it and the legal moves marked' => sub {
	my $game = Game::Reversi->new(variant => 'othello');
	my $terminal = Game::Reversi::Terminal->new(quiet => 1, ascii => 1);
	my @lines = $terminal->board_text($game, 'b');

	# a rule between every pair of ranks, so eight ranks are fifteen rows, and
	# a border and a row of files at each end
	is(scalar @lines, 19, 'eight ranks in a ruled grid between two file rows');
	is($lines[0], '     a   b   c   d   e   f   g   h', 'files across the top');
	is($lines[-1], '     a   b   c   d   e   f   g   h', 'and along the bottom');
	is($lines[1], '   +---+---+---+---+---+---+---+---+', 'the board has an edge');
	like($lines[2], qr/\A 8 /, 'rank 8 first');
	like($lines[2], qr/ 8\z/, 'and named again on the right');
	like($lines[16], qr/\A 1 /, 'rank 1 last');

	# The Othello centre, and Black's four legal moves marked.
	is($lines[8], ' 5 |   |   |   | X | O | * |   |   | 5',
		'rank 5 is dark on d5, light on e5, and f5 marked as playable')
		or diag($lines[8]);
	is($lines[10], ' 4 |   |   | * | O | X |   |   |   | 4',
		'rank 4 is light on d4, dark on e4, and c4 marked')
		or diag($lines[10]);

	my $drawn = join "\n", @lines;
	is(scalar(() = $drawn =~ /\*/g), 4, 'four squares are marked as playable');

	# MARKING THEM IS NOT DECORATION. Working out which squares outflank
	# something is the engine's job; a person doing it by hand every turn gets
	# it wrong. The marks must be exactly the legal moves and nothing else.
	my %marked;
	for my $row (0 .. 7) {
		my @cells = split /\|/, substr($lines[2 + $row * 2], 3);
		for my $col (0 .. 7) {
			$marked{ $row * 8 + $col } = 1 if ($cells[$col + 1] // '') eq ' * ';
		}
	}
	is_deeply([ sort { $a <=> $b } keys %marked ],
		[ sort { $a <=> $b } map { $_->square } @{ $game->legal('b') } ],
		'and they are exactly the legal moves');

	# Discs are two glyphs, never one glyph in two colours: two discs told apart
	# only by an escape code are unreadable in half the terminals in the world.
	unlike($drawn, qr/\e/, 'no escape codes in the board at all');
	done_testing();
};

subtest 'the discs are drawn as discs unless ascii is asked for' => sub {
	my $game = Game::Reversi->new(variant => 'othello');

	my $drawn = join "\n",
		Game::Reversi::Terminal->new(quiet => 1, ansi => 0)->board_text($game, 'b');
	like($drawn, qr/\x{25CF}/, 'dark is a filled disc');
	like($drawn, qr/\x{25CB}/, 'and light a hollow one');
	like($drawn, qr/\x{2502}/, 'in a ruled grid');

	# the fallback is the same board in characters every terminal has
	my $plain = join "\n",
		Game::Reversi::Terminal->new(quiet => 1, ansi => 0, ascii => 1)
			->board_text($game, 'b');
	unlike($plain, qr/[^\x00-\x7f]/, 'ascii draws it without a wide character');
	is(scalar(() = $plain =~ /X/g), 2, 'with two dark discs');
	is(scalar(() = $plain =~ /O/g), 2, 'and two light');
	done_testing();
};

subtest 'a forfeited turn is announced, or it looks like a bug' => sub {
	# A pass is applied by the engine, so from the player's side the board simply
	# changes twice. Without a line saying so it reads as the program losing
	# track of whose turn it is.
	#
	# Found by search rather than constructed: of eighty games driven through
	# this loop, the ones where the human always takes the LAST legal move reach
	# a forfeited turn, and the ones taking the first never do.
	my ($result, $output) = play_through(seed => 's1', pick => 'last');

	my $passes = grep { $_->{kind} eq 'pass' }
	             @{ (play_through(seed => 's1', pick => 'last'))[2]->game->events };
	cmp_ok($passes, '>', 0, 'this game really does forfeit a turn');

	like($output, qr/has no legal move, so that turn is forfeited/,
		'and the terminal says so');
	like($output, qr/(?:dark|light) has no legal move/,
		'naming which side lost the turn');
	done_testing();
};

subtest 'the discs and the score are labelled apart' => sub {
	my ($result, $output) = play_through(seed => 'label');

	like($output, qr/discs on the board:/, 'the discs on the board are named');
	like($output, qr/final score:/, 'and the final score separately');

	# On a full board the two agree, so nothing needs explaining.
	my $counts = $result->counts;
	is($counts->{b} + $counts->{w}, 64, 'this game filled the board');
	unlike($output, qr/empty squares go to the winner/,
		'so the empty-squares clause is not printed');
	done_testing();
};

subtest 'an early finish explains where the extra points came from' => sub {
	# A game ending 20-14 with thirty squares empty is officially 50-14, and an
	# unexplained jump from one to the other reads as an arithmetic error.
	#
	# This reaches past `start` to `_finish`, and the reason is worth recording:
	# NONE of eighty games driven through the loop ended with the board unfilled.
	# Early finishes are real, and three of them are cited in t/16-cited.t from
	# actual tournament play, but they are rare enough that waiting for one to
	# turn up would mean not testing this at all.
	#
	# The position is Vecchi 13 - 51 Nicolas, World Othello Championship 2017,
	# transcribed from Wikipedia's diagram of the final board.
	my @rows = (
		' XXXXXXX', ' OOOOO X', 'OOOOOOOX', 'OOOOOOOX',
		'OOOOOOOX', 'OOOOOOOX', 'OOOOOOOX', ' OOOOO  ',
	);
	my $board = $B->empty;
	for my $row (0 .. 7) {
		my @cells = split //, $rows[$row];
		for my $col (0 .. 7) {
			$board->[ $row * 8 + $col ] =
				$cells[$col] eq 'X' ? 'b' : $cells[$col] eq 'O' ? 'w' : undef;
		}
	}

	my $game = Game::Reversi->from_board($board, turn => 'b');
	is($game->status, 'finished', 'the position is already over');
	is($B->empties($game->board), 6, 'with six squares still empty');

	my $output = '';
	open my $out, '>', \$output or die $!;
	# ascii, so that the two score lines can be asserted as the words they are
	my $terminal = Game::Reversi::Terminal->new(
		out => $out, colour => 'b', quiet => 1, ascii => 1);
	$terminal->game($game);
	$terminal->_finish($game);
	close $out;

	like($output, qr/discs on the board: X 13\s+O 45/, 'the discs are 13 and 45');
	like($output, qr/final score:\s+X 13\s+O 51/,
		'while the score is 13 and 51, which is what the record says');
	like($output, qr/the 6 empty squares go to the winner/,
		'and the difference is explained rather than left to be noticed');
	done_testing();
};

subtest 'bad input is answered and the prompt comes back' => sub {
	# A refusal is a return value, not an exception, so there is nothing to catch
	# and no reason for a mistyped move to end the program.
	my $output = '';
	open my $out, '>', \$output or die $!;
	open my $in, '<', \"zz\nq9\nd9\na1\nhelp\nquit\n" or die $!;

	my $terminal = Game::Reversi::Terminal->new(
		in => $in, out => $out, level => 1, seed => 'bad', quiet => 1);
	my $result = $terminal->start;
	close $out;

	ok($result, 'the terminal survived all of it and returned');
	like($output, qr/"zz" is not a square/, 'a word that is not a square is named');
	like($output, qr/"q9" is not a square/, 'and a file that does not exist');
	like($output, qr/"d9" is not a square/, 'and a rank that does not exist');
	like($output, qr/the first four discs go in the centre four/,
		'a real square in the wrong place gets the engine\'s own sentence');
	like($output, qr/Enter a square as a file and a rank/, 'help is printed on request');
	is($result->result, 'resign', 'and quitting resigns rather than crashing');
	done_testing();
};

subtest 'the end of input is not an error' => sub {
	# A terminal handed a script that runs out has to stop, not spin on undef.
	my $output = '';
	open my $out, '>', \$output or die $!;
	open my $in, '<', \"" or die $!;

	my $terminal = Game::Reversi::Terminal->new(
		in => $in, out => $out, level => 1, seed => 'eof', quiet => 1);
	my $result = $terminal->start;

	ok($result, 'it returned');
	is($result->result, 'resign', 'treating the silence as giving up');
	done_testing();
};

subtest 'the othello variant is playable too, from the other seat' => sub {
	my ($result, $output, $terminal) = play_through(
		variant => 'othello', colour => 'w', seed => 'other', ascii => 1);

	is($terminal->game->variant, 'othello', 'the variant was passed through');
	is($terminal->colour, 'w', 'and the seat');
	like($output, qr/You are O, light/, 'which the intro says');
	like($output, qr/four discs are already on the board/,
		'and it explains that this opening is the other one');
	is($terminal->game->status, 'finished', 'the game finished');
	done_testing();
};

subtest 'colour adds emphasis and never information' => sub {
	# "Must degrade" has to mean the board reads the same without colour, not
	# that it degrades to something you cannot read. Every disc and every marker
	# is told apart by its glyph, so stripping the escapes must lose nothing.
	my $game = Game::Reversi->new(variant => 'othello');

	my $plain = do {
		my $out = ''; open my $fh, '>', \$out or die $!;
		local %ENV = (%ENV); delete $ENV{NO_COLOR};
		join "\n", Game::Reversi::Terminal
			->new(out => $fh, ansi => 0, quiet => 1)->board_text($game, 'b');
	};
	my $painted = do {
		my $out = ''; open my $fh, '>', \$out or die $!;
		local %ENV = (%ENV); delete $ENV{NO_COLOR};
		join "\n", Game::Reversi::Terminal
			->new(out => $fh, ansi => 1, quiet => 1)->board_text($game, 'b');
	};

	unlike($plain, qr/\e/, 'with colour off there are no escapes');
	like($painted, qr/\e/, 'with colour on there are');

	(my $stripped = $painted) =~ s/\e\[[0-9;]*m//g;
	is($stripped, $plain,
		'and with the escapes removed the two boards are identical');
	done_testing();
};

subtest 'NO_COLOR wins, even over an explicit request for colour' => sub {
	# https://no-color.org: the variable's PRESENCE is the signal, not its value.
	# Somebody who set it meant it, so it outranks the ansi option rather than
	# merely changing the default.
	my $out = ''; open my $fh, '>', \$out or die $!;
	my $terminal = Game::Reversi::Terminal->new(out => $fh, ansi => 1, quiet => 1);

	{
		local $ENV{NO_COLOR} = '1';
		is($terminal->ansi, 0, 'NO_COLOR=1 turns it off');
	}
	{
		local $ENV{NO_COLOR} = 'anything at all';
		is($terminal->ansi, 0, 'and so does any other non-empty value');
	}
	{
		local $ENV{NO_COLOR} = '';
		is($terminal->ansi, 1, 'but an empty value is not the signal');
	}

	local %ENV = (%ENV);
	delete $ENV{NO_COLOR};
	is($terminal->ansi, 1, 'and unset leaves the explicit request standing');
	done_testing();
};

subtest 'bad options are refused by the constructor, all of them' => sub {
	# Found by running bin/reversi rather than by testing it: --colour green got
	# a tidy sentence and exit 2, while --variant draughts died with a raw Perl
	# message naming a line number and exited 255, because the variant was only
	# checked later, inside start. A program should reject what it rejects the
	# same way.
	ok(!eval { Game::Reversi::Terminal->new(colour => 'green'); 1 },
		'green is not a seat');
	like($@, qr/colour must be b or w/, 'saying so');

	ok(!eval { Game::Reversi::Terminal->new(variant => 'draughts'); 1 },
		'and draughts is not a variant');
	like($@, qr/no variant 'draughts'/, 'saying that too, and at the same point');

	ok(eval { Game::Reversi::Terminal->new(variant => 'othello', colour => 'w'); 1 },
		'while the real ones are accepted');

	# THE ONE THIS DISTRIBUTION IS CITED FOR, and it was only half fixed. Four
	# other dists' POD names Game::Reversi for validating its variant three
	# calls deeper and dying with a raw Perl message and a useless exit
	# status. The variant was brought forward into BUILD; the LEVEL was left
	# where it was, in the Bot, which is not built until `start`, so it was
	# outside bin/reversi's eval and died exactly the same way one option
	# along.
	ok(!eval { Game::Reversi::Terminal->new(level => 9); 1 },
		'an impossible level is refused by the constructor');
	like($@, qr/there is no level 9/, 'and says so plainly');
	unlike($@, qr/Bot\.pm line/,
		'without naming a file and a line three calls deeper');
	done_testing();
};

# The key loop, driven by `keysource` so nothing here needs a tty or
# Term::ReadKey. ONE character a call: a source handing back "\e[C" whole
# never becomes a right arrow.
sub picker {
	my ($keys, %o) = @_;
	open my $in, '<', \(my $script = "quit\n") or die $!;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my @chars = split //, $keys;

	my $t = Game::Reversi::Terminal->new(
		in => $in, out => $out, variant => 'othello', seed => 'pick',
		level => 1, ascii => 1, ansi => 0, picking => 1,
		keysource => sub { shift @chars },
		%o,
	);
	my $game = Game::Reversi->new(variant => 'othello', seed => 'pick');
	$t->game($game);
	return ($t, $game, \$text);
}

subtest 'a key at a time, named' => sub {
	my ($t) = picker("k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");

	my @got;
	while (defined(my $key = $t->read_key)) {
		push @got, $key eq ' ' ? 'space' : $key;
	}

	is_deeply(\@got, [ qw/ k up down right left page_up home enter tab backspace
		interrupt eof space q escape page_down / ],
		'a character comes back as itself and a sequence as a name');
	done_testing();
};

subtest 'an escape does not eat the key behind it' => sub {
	my ($t) = picker("\eq");
	is($t->read_key, 'escape', 'the escape is an escape');
	is($t->read_key, 'q', 'and the keystroke behind it survives');
	done_testing();
};

# THE CURSOR WALKS THE STARRED SQUARES AND NOTHING ELSE. In Go every point is
# a candidate; here between one and fifteen squares play at all, so a cursor
# that crawled the other fifty would spend its time on squares that refuse.
subtest 'the cursor walks only the squares that play' => sub {
	my ($t, $game, $text) = picker("\e[C\e[Cq");
	$t->enter_raw;
	$t->pick_square($game, 'b');

	my @named = $$text =~ /^\s+([a-h][1-8]): turns/mg;
	cmp_ok(scalar @named, '>=', 3, 'the cursor visited three squares');

	my %legal = map { Game::Reversi::Board->name_of($_->square) => 1 }
		@{ $game->legal('b') };
	my @wrong = grep { !$legal{$_} } @named;
	is_deeply(\@wrong, [], 'and every one of them was a legal move')
		or diag "visited: @named";

	# It has to be a REAL subset, or "every visited square is legal" is true
	# of a cursor that never moved.
	cmp_ok(scalar keys %legal, '<', 20, 'the legal set is small, as Reversi is');
	done_testing();
};

# THE LINE UNDER THE BOARD IS THE MOVE IT WOULD MAKE, and the oracle is the
# engine: the square is played on a CLONE and the clone is asked.
subtest 'the line under the board is what the move would turn' => sub {
	my ($t, $game, $text) = picker('q');

	my $legal = $game->legal('b');
	my $first = (sort { $a <=> $b } map { $_->square } @$legal)[0];
	my $line = $t->square_line($game, 'b', $first);

	like($line, qr/turns \d+ discs?/, 'it says how many it turns');
	like($line, qr/you would be \d+ to \d+/, 'and what the score would become');

	# The oracle, independently: play it for real in a second game.
	my $real = Game::Reversi->new(variant => 'othello', seed => 'pick');
	my $move = $real->play('b', $first);
	my $count = $real->counts;
	like($line, qr/turns \Q@{[ $move->turned ]}\E disc/,
		'and the count is the one the engine really makes');
	like($line, qr/\Q$count->{b}\E to \Q$count->{w}\E/,
		'as is the score');

	# NOTHING IS PLAYED by a preview.
	is_deeply($game->counts, { b => 2, w => 2 }, 'the board is untouched');
	done_testing();
};

subtest 'the marks say what the last move did' => sub {
	my ($t, $game) = picker('q');

	my $legal = $game->legal('b');
	my $move = $game->play('b', $legal->[0]->square);
	$t->remember($move);

	my $drawn = join "\n", $t->board_text($game, undef, $t->since);

	like($drawn, qr/\[X\]/, 'the square it was placed on is bracketed');
	like($drawn, qr/\bx\b/, 'and a disc it turned is drawn ringed');

	# BOTH ARE CHARACTERS. This board was rendered with ansi off, so anything
	# visible here survives --ascii, NO_COLOR and a redirected handle.
	is($t->ansi, 0, 'with no colour at all in it');
	cmp_ok($move->turned, '>', 0, 'and the move really did turn something');
	done_testing();
};

subtest 'enter plays the square under the cursor' => sub {
	my ($t, $game, $text) = picker("\r");
	$t->enter_raw;
	my $quit = $t->pick_square($game, 'b');

	is($quit, 0, 'the turn was taken');
	like($$text, qr/you play [a-h][1-8]/, 'and it says what it played');
	is($game->counts->{b} + $game->counts->{w}, 5, 'a disc went down');
	done_testing();
};

subtest 'q gives up, and a dud key says so' => sub {
	my ($stop, $game) = picker('q');
	$stop->enter_raw;
	is($stop->pick_square($game, 'b'), 1, 'q stops');

	my ($dud, $g2, $text) = picker('zq');
	$dud->enter_raw;
	$dud->pick_square($g2, 'b');
	like($$text, qr/that key does nothing here/, 'and a dud key says so');
	done_testing();
};

# Without Term::ReadKey and without a keysource there is nothing to read keys
# with, and the fallback is the typed game rather than a failure.
subtest 'no key source at all falls back to typing' => sub {
	open my $in, '<', \(my $script = "quit\n") or die $!;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my $t = Game::Reversi::Terminal->new(
		in => $in, out => $out, variant => 'othello', seed => 'fall',
		level => 1, ascii => 1, ansi => 0, picking => 1);

	is($t->keys_available, 0, 'nothing to read keys with');
	$t->start;
	like($text, qr/  > /, 'so the typed prompt was used');
	is($t->picking, 0, 'and it does not try the keys again');
	done_testing();
};

done_testing();
