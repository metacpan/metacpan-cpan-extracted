#!perl

# The Go Text Protocol, driven in process.
#
# GTP is what lets something from OUTSIDE have an opinion, which with one
# implementation of everything is the only non-self-referential answer available
# to "is this group dead" and "does the bot play well". xt/gnugo.t is the test
# that uses it for that; this one holds the protocol itself to its spec.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::GTP;
use Game::Go::Notation;

sub gtp { Game::Go::GTP->new(size => 9, level => 1, seed => 'gtp', @_) }

# A response with its trailing whitespace taken off for comparison. The space
# after "=" is in the grammar ('=' [id] ' ' response '\n\n'), so an empty body
# really does go out as "= \n\n" and a controller really does see that space.
sub ask {
	my ($engine, $line) = @_;
	my $r = $engine->handle($line);
	$r =~ s/\s+\z//;
	return $r;
}

subtest 'the response format, which every controller depends on' => sub {
	my $e = gtp();

	# "=" for success, "?" for failure, and then A BLANK LINE. A response
	# without the blank line hangs every controller there is.
	my $raw = $e->handle('protocol_version');
	like($raw, qr/\A=/, 'success starts with =');
	like($raw, qr/\n\n\z/, 'and ends with a blank line');

	my $bad = $e->handle('wibble');
	like($bad, qr/\A\?/, 'failure starts with ?');
	like($bad, qr/\n\n\z/, 'and also ends with a blank line');

	# An id is echoed back where one is given, which is how a controller
	# matches responses to commands.
	like($e->handle('42 protocol_version'), qr/\A=42 /, 'an id is echoed');
	like($e->handle('7 wibble'), qr/\A\?7 /, 'on failure too');
	done_testing();
};

subtest 'the identity commands' => sub {
	my $e = gtp();
	is(ask($e, 'protocol_version'), '= 2', 'protocol 2');
	is(ask($e, 'name'), '= Game::Go', 'name');
	is(ask($e, 'version'), "= $Game::Go::VERSION", 'version');

	my $list = ask($e, 'list_commands');
	for my $cmd (qw(boardsize clear_board komi play genmove undo showboard
	                final_score final_status_list quit)) {
		like($list, qr/^\Q$cmd\E$/m, "list_commands has $cmd");
		is(ask($e, "known_command $cmd"), '= true', "known_command $cmd");
	}
	is(ask($e, 'known_command wibble'), '= false', 'and false for one it has not');
	done_testing();
};

subtest 'an unknown command is answered, not fatal' => sub {
	# A controller sends commands an engine may not have and expects to be told
	# so. Dying would look like a crash to it.
	my $e = gtp();
	is(ask($e, 'wibble'), '? unknown command', 'unknown command');
	is(ask($e, 'protocol_version'), '= 2', 'and the engine carries on');
	done_testing();
};

subtest 'boardsize, komi and clear_board' => sub {
	my $e = gtp();
	is(ask($e, 'boardsize 13'), '=', 'boardsize 13');
	is($e->game->size, 13, 'and the game is on a 13x13 board');

	is(ask($e, 'boardsize 11'), '? unacceptable size', 'a size off the list is refused');
	is(ask($e, 'boardsize wibble'), '? unacceptable size', 'and so is nonsense');

	is(ask($e, 'komi 0.5'), '=', 'komi');
	is($e->game->komi, 0.5, 'and it took');
	is(ask($e, 'komi wibble'), '? syntax error', 'a komi that is not a number');

	$e->handle('boardsize 9');
	$e->handle('play b D4');
	is($e->game->board->at(3, 5), Game::Go::BLACK, 'a stone is on the board');
	is(ask($e, 'clear_board'), '=', 'clear_board');
	is($e->game->board->stones(Game::Go::BLACK), 0, 'and the board is empty again');
	done_testing();
};

subtest 'GTP vertices ARE this distribution human notation' => sub {
	# Columns A to T with I left out, rows from the bottom. There is no third
	# coordinate system here and nothing to get wrong twice.
	my $e = gtp();
	$e->handle('boardsize 9');

	$e->handle('play b A1');
	is($e->game->board->at(0, 8), Game::Go::BLACK, 'A1 is the bottom left');

	$e->handle('play w J9');
	is($e->game->board->at(8, 0), Game::Go::WHITE, 'J9 is the top right, I being skipped');

	is(ask($e, 'play b I5'), '? invalid coordinate', 'I is not a column');
	is(ask($e, 'play b Z9'), '? invalid coordinate', 'nor is one off the board');
	is(ask($e, 'play b A99'), '? invalid coordinate', 'nor a row off it');
	is(ask($e, 'play purple D4'), '? syntax error', 'and purple is not a colour');
	done_testing();
};

subtest 'play, pass and an illegal move' => sub {
	my $e = gtp();
	$e->handle('boardsize 9');

	is(ask($e, 'play b D4'), '=', 'a play');
	is(ask($e, 'play w pass'), '=', 'a pass');
	is(ask($e, 'play B E5'), '=', 'and play carries on after one');
	is(ask($e, 'play W PASS'), '=', 'a pass in upper case too');

	is(ask($e, 'play b D4'), '? illegal move', 'a point that is taken is refused');

	# TWO CONSECUTIVE PASSES STOP PLAY, and this distribution then wants the
	# dead stones agreed before it will take another move. A controller that
	# replays a record through the second pass and keeps going gets told so
	# rather than having the move quietly accepted.
	is(ask($e, 'play b pass'), '=', 'black passes');
	is($e->game->phase, 'marking', 'and play has stopped');
	is(ask($e, 'play w D5'), '? illegal move', 'so a move after it is refused');
	done_testing();
};

subtest 'genmove returns a legal vertex' => sub {
	my $e = gtp();
	$e->handle('boardsize 9');

	my $r = ask($e, 'genmove b');
	like($r, qr/\A= (?:[A-HJ-T][0-9]+|pass|resign)\z/, "genmove gave $r");

	if ($r =~ /= ([A-HJ-T][0-9]+)/) {
		my $where = $1;
		my ($col, $row) = Game::Go::Notation::from_human(9, $where);
		ok(defined $col, "$where is a real point");
		is($e->game->board->at($col, $row), Game::Go::BLACK,
			'and the engine put its own stone there');
	}

	# It alternates without being told: a controller plays one side and asks
	# for the other.
	like(ask($e, 'genmove w'), qr/\A= /, 'and white can be asked for one too');
	done_testing();
};

subtest 'undo' => sub {
	my $e = gtp();
	$e->handle('boardsize 9');
	$e->handle('play b D4');
	$e->handle('play w E5');
	is($e->game->board->stones(Game::Go::WHITE), 1, 'two stones on the board');

	is(ask($e, 'undo'), '=', 'undo');
	is($e->game->board->stones(Game::Go::WHITE), 0, 'the last one is gone');
	is($e->game->board->at(3, 5), Game::Go::BLACK, 'and the first is still there');

	is(ask($e, 'undo'), '=', 'undo again');
	is($e->game->board->stones(Game::Go::BLACK), 0, 'and the board is empty');

	is(ask($e, 'undo'), '? cannot undo', 'and there is nothing left to undo');
	done_testing();
};

subtest 'showboard and final_score' => sub {
	my $e = gtp();
	$e->handle('boardsize 9');
	$e->handle('play b D4');

	my $board = ask($e, 'showboard');
	like($board, qr/X/, 'showboard draws the stones');
	is(scalar(my @lines = split /\n/, $board), 10, 'nine rows and the = line');

	my $score = ask($e, 'final_score');
	like($score, qr/\A= (?:[BW]\+[0-9.]+|0)\z/, "final_score gave $score");

	# It agrees with the engine's own scorer, which is the thing a referee
	# would be comparing against.
	my $raw = $e->game->raw_score;
	my ($b, $w) = ($raw->{score_b} / 10, $raw->{score_w} / 10);
	my $want = $b == $w ? '0' : $b > $w ? 'B+' . ($b - $w) : 'W+' . ($w - $b);
	is($score, "= $want", 'and it is the engine scorer, not a second one');
	done_testing();
};

subtest 'final_status_list' => sub {
	# THE ONE A REFEREE IS FOR. GNU Go answers this too, and comparing the two
	# is the only outside opinion on dead stones this distribution can get.
	my $e = gtp();
	$e->handle('boardsize 9');
	$e->handle('play b D4');
	$e->handle('play w E5');

	my $dead = ask($e, 'final_status_list dead');
	like($dead, qr/\A=/, 'dead answers');
	my $alive = ask($e, 'final_status_list alive');
	like($alive, qr/\A=/, 'and alive');

	# Every stone is in exactly one of the two lists. AN EMPTY LIST IS "=" WITH
	# NOTHING AFTER IT, so the body comes off by matching rather than by
	# stripping a prefix that is not there.
	my @d = grep { length } split /\s+/, ($dead  =~ /\A=\s*(.*)\z/ ? $1 : '');
	my @a = grep { length } split /\s+/, ($alive =~ /\A=\s*(.*)\z/ ? $1 : '');
	is(scalar(@d) + scalar(@a), 2, 'and between them they name both stones');

	my %seen;
	$seen{$_}++ for @d, @a;
	is(scalar(grep { $_ > 1 } values %seen), 0, 'with no stone in both lists');

	is(ask($e, 'final_status_list wibble'), '? syntax error', 'an unknown status');
	done_testing();
};

subtest 'quit, and the run loop' => sub {
	my $e = gtp();
	is(ask($e, 'quit'), '=', 'quit answers');
	ok($e->quit, 'and sets the flag the loop reads');

	# The loop, on two filehandles, which is how bin/go-gtp and a test both
	# drive the same code.
	my $script = "boardsize 9\nplay b D4\nshowboard\nquit\n";
	open my $in, '<', \$script or die $!;
	my $out = '';
	open my $fh, '>', \$out or die $!;

	gtp()->run($in, $fh);
	my @responses = split /\n\n/, $out;
	is(scalar @responses, 4, 'four commands, four responses');
	like($responses[2], qr/X/, 'with the board among them');
	done_testing();
};

subtest 'comments and blank lines are ignored' => sub {
	my $e = gtp();
	is($e->handle('# just a comment'), '', 'a comment produces no response');
	is($e->handle(''), '', 'nor does a blank line');
	is($e->handle('   '), '', 'nor whitespace');
	is(ask($e, 'protocol_version # trailing'), '= 2', 'and a trailing comment is stripped');
	done_testing();
};

done_testing();
