#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Snake;
use Game::Snake::Terminal;

# NO TTY, NO Term::ReadKey, NO SLEEPING. The keys come from `keysource`,
# which is handed the seconds to wait and answers a character or undef; an
# undef to a timed wait IS the tick, by definition, so the clock here never
# moves and the game still runs. The invariant every subtest leans on:
#
#     ticks  == undefs answered to a timed wait
#     frames == ticks + 1  (the first frame)  + one a pause
#
# `interactive => 0` keeps the in-place redraw escapes out of the output so
# a frame can be counted by its status line.

sub terminal {
	my ($script, %opt) = @_;
	my @script = map { defined $_ ? split(//, $_) : undef } @$script;
	my $output = '';
	open my $out, '>', \$output or die "cannot open a string handle: $!";
	my $typed = '';
	open my $in, '<', \$typed or die "cannot open a string handle: $!";
	my $slept = 0;
	my $terminal = Game::Snake::Terminal->new(
		in          => $in,
		out         => $out,
		cols        => 12,
		rows        => 8,
		seed        => 'terminal',
		interactive => 0,
		ansi        => 0,
		ascii       => 1,
		max_ticks   => 200,
		keysource   => sub { @script ? shift @script : undef },
		clock       => sub { 1000 },
		sleeper     => sub { $slept++ },
		%opt,
	);
	return ($terminal, \$output, \$slept);
}

sub frames_in { my ($text) = @_; my @f = $text =~ /^ Snake   score/mg; return scalar @f }

subtest 'five ticks and a quit' => sub {
	my ($t, $out) = terminal([ "\e[A", (undef) x 5, 'q' ]);
	my $result = $t->start;
	ok($result, 'start returned a result');
	is($result->cause, 'quit', 'the game was quit');
	is($t->ticker->ticks, 5, 'five undefs, five ticks');
	is($t->frames, 6, 'six frames: the first and one a tick');
	is(frames_in($$out), 6, 'and six status lines were written');
	is($t->stopped, 'quit', 'stopped by a quit');
	is($t->raw, 0, 'raw mode left');
	like($$out, qr/^Quit at 0 points, 3 long$/m, 'the result sentence closes the output');
	is($t->game->ticks, 5, 'the engine agrees on the ticks');
};

subtest 'input that ends before the first key is a quit, not a tick' => sub {
	my ($t, $out) = terminal([ undef ]);
	my $result = $t->start;
	is($t->stopped, 'quit', 'quit');
	is($t->ticker->ticks, 0, 'with no tick: the snake does not leave before the player finds the arrows');
	is($t->frames, 1, 'after the one frame it was shown');
};

subtest 'the first key steers before the first tick' => sub {
	my ($t, $out) = terminal([ "\e[A", undef, 'q' ]);
	$t->start;
	is($t->game->heading, 'up', 'heading up');
	my ($head) = @{ $t->game->segments };
	is_deeply([ $head->{x}, $head->{y} ], [ 4, 4 ], 'the head went up from (4,5)');
	like($$out, qr/\|(  ){4}\^\^/, 'and the head is drawn as ^^ in the second frame');
};

subtest 'two quick keys both take, across two ticks' => sub {
	my ($t) = terminal([ "\e[A", "\e[D", undef, undef, 'q' ]);
	$t->start;
	my ($head) = @{ $t->game->segments };
	is_deeply([ $head->{x}, $head->{y} ], [ 3, 4 ], 'up then left: the head is at (3,4)');
	is($t->game->heading, 'left', 'heading left');
};

subtest 'a reverse is refused in silence' => sub {
	my ($t, $out) = terminal([ "\e[C", undef, 'q' ]);
	$t->start;
	is($t->refused, 1, 'one refusal counted');
	is($t->game->heading, 'left', 'still heading left');
	is($t->ticker->ticks, 1, 'one tick');
	unlike($$out, qr/refus|cannot/i, 'and nothing was said about it');
};

subtest 'a run into the wall' => sub {
	my ($t, $out) = terminal([ "\e[A", (undef) x 40 ]);
	my $result = $t->start;
	is($result->cause, 'wall', 'died at the wall');
	is($t->ticker->ticks, 6, 'five moves up from row 5 and the fatal tick');
	is($t->frames, 7, 'frames are ticks plus one');
	is($t->stopped, '', 'not stopped by anything but the game');
	like($$out, qr/^ Snake   score 0   length 3   speed 2\/s   Game over: hit the wall at 0 points, 3 long$/m,
		'the last frame carries the sentence on its status line');
	like($$out, qr/^Game over: hit the wall at 0 points, 3 long$/m, 'and the sentence closes the output');
};

subtest 'pause' => sub {
	my ($t, $out) = terminal([ "\e[A", undef, 'p', 'p', undef, 'q' ]);
	$t->start;
	is($t->ticker->ticks, 2, 'two ticks either side of the pause');
	is($t->frames, 4, 'four frames: first, tick, pause, tick');
	like($$out, qr/^ Snake   score 0   length 3   speed 2\/s   paused$/m, 'the pause frame says paused');

	($t) = terminal([ "\e[A", undef, 'p', undef ]);
	$t->start;
	is($t->ticker->ticks, 1, 'an undef while paused is end of input, not a tick');
	is($t->stopped, 'quit', 'and quits');

	($t) = terminal([ "\e[A", undef, ' ', "\e[D", undef, 'q' ]);
	$t->start;
	is($t->game->heading, 'left', 'space pauses and an arrow resumes, steering');
	is($t->ticker->ticks, 2, 'with the ticks on either side');
};

subtest 'a bare escape does nothing and does not eat the key behind it' => sub {
	my ($t) = terminal([ "\e[A", undef, "\e", 'q' ]);
	$t->start;
	is($t->stopped, 'quit', 'the q after the escape quit');
	is($t->ticker->ticks, 1, 'and the escape itself was not a tick');
};

subtest 'glyphs' => sub {
	my ($t, $out) = terminal([ "\e[A", 'q' ], ascii => 1);
	$t->start;
	like($$out, qr/##/, 'ascii body');
	my @board = grep { /\A\|/ } split /\n/, $$out;
	is(scalar @board, 8, 'eight board rows in the one frame');
	is(length $_, 2 * 12 + 2, 'each board row is 2*cols+2 bytes') for @board[0 .. 1];
	like($$out, qr/^\+-{24}\+$/m, 'ascii frame');

	($t, $out) = terminal([ "\e[A", 'q' ], ascii => 0);
	$t->start;
	unlike($$out, qr/##/, 'no ascii body in a wide frame');
	like($$out, qr/\x{e2}\x{96}\x{88}/, 'and a block glyph instead');
};

subtest 'colour carries no information' => sub {
	my ($t, $plain) = terminal([ "\e[A", undef, 'q' ], ansi => 0);
	$t->start;
	my ($c, $coloured) = terminal([ "\e[A", undef, 'q' ], ansi => 1);
	$c->start;
	like($$coloured, qr/\e\[1;32m/, 'the coloured run has paint');
	(my $stripped = $$coloured) =~ s/\e\[[0-9;]*m//g;
	is($stripped, $$plain, 'stripped of every escape it is the plain run, byte for byte');

	local $ENV{NO_COLOR} = '1';
	my ($n, $none) = terminal([ "\e[A", 'q' ], ansi => 1);
	$n->start;
	unlike($$none, qr/\e\[/, 'NO_COLOR beats ansi => 1');
};

subtest 'the sleeper is never called while a keysource exists' => sub {
	my ($t, $out, $slept) = terminal([ "\e[A", (undef) x 10, 'q' ]);
	$t->start;
	is($$slept, 0, 'no sleep');
};

subtest 'the board is fitted to the window' => sub {
	my ($t) = terminal([ 'q' ], cols => undef, rows => undef, width => 80, height => 24);
	is($t->game->cols, 39, '80 columns hold 39 cells');
	is($t->game->rows, 19, '24 lines hold 19 rows');
	is($t->too_narrow, undef, 'and it fits');

	($t) = terminal([ 'q' ], cols => undef, rows => undef, width => 300, height => 100);
	is($t->game->cols, 40, 'a huge window is capped at 40');
	is($t->game->rows, 28, 'by 28');

	($t) = terminal([ 'q' ], cols => undef, rows => undef, width => 10, height => 5);
	is($t->game->cols, 10, 'a tiny window is floored at 10');
	is($t->game->rows, 8, 'by 8');
	like($t->too_narrow, qr/needs 22 by 13/, 'which the window cannot hold');

	($t) = terminal([ 'q' ], cols => undef, rows => undef);
	is($t->game->cols, 40, 'with nothing to measure the default is 40');
	is($t->game->rows, 28, 'by 28');
};

subtest 'an explicit board that does not fit is refused' => sub {
	my ($t, $out) = terminal([ "\e[A", 'q' ], cols => 40, rows => 28, width => 80, height => 24);
	my $result = $t->start;
	is($result, undef, 'start returned nothing');
	is($t->stopped, 'narrow', 'stopped as narrow');
	like($t->refusal, qr/^This window is 80 columns by 24 lines, and a 40 by 28 board needs 82 by 33\./,
		'with both sizes in the sentence');
	is($t->frames, 0, 'no frame was drawn');
	is($$out, '', 'and nothing was written');
};

subtest 'no keys and no watch cannot play' => sub {
	my ($t, $out) = terminal([], keysource => undef);
	is($t->keys_available, 0, 'a string handle is not a terminal');
	my $result = $t->start;
	is($result, undef, 'start returned nothing');
	is($t->stopped, 'keys', 'stopped as keys');
	is($t->refusal, $t->cannot_play, 'with the sentence');
	like($t->refusal, qr/Term::ReadKey.*--watch/, 'which names the module and the way round');
	is($t->frames, 0, 'no frame');
};

subtest 'the key names' => sub {
	my ($t) = terminal([ split //, "k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~" ]);
	my @got;
	while (defined(my $key = $t->read_key(1))) {
		push @got, $key eq ' ' ? 'space' : $key;
	}
	is_deeply(\@got, [ qw/ k up down right left page_up home enter tab backspace interrupt eof space q escape page_down / ],
		'every sequence by name, a lone escape as escape');
};

subtest 'the arguments are checked' => sub {
	for my $case (
		[ { level => 4 },     qr/a level is one of 1 2/, 'a level off the ladder' ],
		[ { cols => 'x' },    qr/cols must be a whole/,    'a width that is not a number' ],
		[ { cols => 5 },      qr/at least 6 by 6/,         'a board too small for the engine' ],
		[ { clock => 'now' }, qr/the clock is a code/,     'a clock that is not code' ],
	) {
		my ($args, $why, $name) = @$case;
		my $t = eval { terminal([], %$args) };
		like($@, $why, "$name is refused");
	}
};

subtest 'quiet draws nothing but says how it ended' => sub {
	my ($t, $out) = terminal([ "\e[A", (undef) x 3, 'q' ], quiet => 1);
	$t->start;
	is($t->frames, 0, 'no frames');
	is($$out, "Quit at 0 points, 3 long\n", 'only the sentence');
};

done_testing();
