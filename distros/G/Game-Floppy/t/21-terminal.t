#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Floppy;
use Game::Floppy::Terminal;

# NO TTY, NO Term::ReadKey, NO SLEEPING. The keys come from `keysource`,
# which is handed the seconds to wait and answers one byte or undef; an undef
# to a timed wait IS the tick, so the clock here never moves and the game
# still runs. The invariant every subtest leans on:
#
#     ticks  == undefs answered to a timed wait
#     frames == ticks + 1 a game  (+ one a pause)
#
# In a script a ' ' is a flap and an undef a tick; the first element is the
# key that starts the game.

sub terminal {
	my ($script, %opt) = @_;
	my @script = map { defined $_ ? split(//, $_) : undef } @$script;
	my $output = '';
	open my $out, '>', \$output or die "cannot open a string handle: $!";
	my $typed = '';
	open my $in, '<', \$typed or die "cannot open a string handle: $!";
	my $slept = 0;
	my $terminal = Game::Floppy::Terminal->new(
		in          => $in,
		out         => $out,
		rows        => 10,
		cols        => 26,
		seed        => 'terminal',
		interactive => 0,
		ansi        => 0,
		ascii       => 1,
		keysource   => sub { @script ? shift @script : undef },
		clock       => sub { 1000 },
		sleeper     => sub { $slept++ },
		%opt,
	);
	return ($terminal, \$output, \$slept);
}

sub frames_in { my ($text) = @_; my @f = $text =~ /^ Floppy   score/mg; return scalar @f }

subtest 'a flap, five ticks and a quit' => sub {
	my ($t, $out) = terminal([ ' ', (undef) x 5, 'q' ]);
	my $result = $t->start;
	ok($result, 'start returned a result');
	is($result->cause, 'quit', 'the game was quit');
	is($t->ticker->ticks, 5, 'five undefs, five ticks');
	is($t->frames, 6, 'six frames: the first and one a tick');
	is(frames_in($$out), 6, 'and six status lines were written');
	is($t->game->bird->{y}, 149 + 12, 'the flap landed on the first tick, then four falls');
	is($t->games, 1, 'one game');
	is($t->stopped, 'quit', 'stopped by a quit');
	is($t->raw, 0, 'raw mode left');
	like($$out, qr/^Quit at 0 points after 5 ticks$/m, 'the result sentence closes the output');
	like($$out, qr/space to start/, 'the first frame said how to start');
};

subtest 'input that ends before the first key is a quit, not a tick' => sub {
	my ($t) = terminal([ undef ]);
	$t->start;
	is($t->stopped, 'quit', 'quit');
	is($t->ticker->ticks, 0, 'with no tick: the bird does not fall before the player finds the keys');
	is($t->frames, 1, 'after the one frame it was shown');
};

subtest 'never flapped, the bird dies on the ground with the sentence on the last frame' => sub {
	my ($t, $out) = terminal([ 'x', (undef) x 100 ]);
	my $result = $t->start;
	is($result->cause, 'ground', 'ground');
	is($t->ticker->ticks, 75, 'at tick 75');
	is($t->frames, 76, 'frames are ticks plus one');
	is($t->stopped, 'quit', 'then the input ran out at the again prompt, which is a quit');
	like($$out, qr/^ Floppy   score 0   best 0   Game over: fell to the ground at 0 points after 75 ticks$/m,
		'the last frame carries the sentence');
	like($$out, qr/space plays again; q quits/, 'and offers another game');
	like($$out, qr/^Game over: fell to the ground at 0 points after 75 ticks$/m, 'the sentence closes the output');
};

subtest 'space plays again' => sub {
	my ($t, $out) = terminal([ 'x', (undef) x 75, ' ', (undef) x 3, 'q' ]);
	my $result = $t->start;
	is($t->games, 2, 'two games');
	is($result->cause, 'quit', 'the second was quit');
	is($t->game->ticks, 3, 'after three ticks');
	is($t->game->bird->{y}, 149 + 6, 'with the restarting space as its first flap');
	is($t->frames, 76 + 4, 'frames: 76 for the first game, 4 for the second');
	is($t->ticker->ticks, 75 + 3, 'ticks across both');
	is($t->best, 0, 'no best yet, nothing was scored');
};

subtest 'a second flap in one tick is refused and counted' => sub {
	my ($t) = terminal([ ' ', ' ', undef, 'q' ]);
	$t->start;
	is($t->refused, 1, 'one refusal');
	is($t->game->bird->{y}, 149, 'one lift, not two');
};

subtest 'pause' => sub {
	my ($t, $out) = terminal([ ' ', undef, 'p', 'p', undef, 'q' ]);
	$t->start;
	is($t->ticker->ticks, 2, 'two ticks either side of the pause');
	is($t->frames, 4, 'four frames: first, tick, pause, tick');
	like($$out, qr/^ Floppy   score 0   best 0   paused$/m, 'the pause frame says paused');
	($t) = terminal([ ' ', undef, 'p', undef ]);
	$t->start;
	is($t->ticker->ticks, 1, 'an undef while paused is end of input');
	is($t->stopped, 'quit', 'and quits');
	($t) = terminal([ ' ', undef, 'p', ' ', undef, 'q' ]);
	$t->start;
	is($t->ticker->ticks, 2, 'space resumes a pause');
	is($t->game->bird->{y}, 149 + 3 - 30, 'and flaps');
};

subtest 'a bare escape does nothing and does not eat the key behind it' => sub {
	my ($t) = terminal([ ' ', undef, "\e", 'q' ]);
	$t->start;
	is($t->stopped, 'quit', 'the q after the escape quit');
	is($t->ticker->ticks, 1, 'and the escape itself was not a tick');
};

subtest 'the view and its glyphs' => sub {
	my ($t, $out) = terminal([ ' ', 'q' ], ascii => 1);
	is_deeply([ $t->view ], [ 26, 10 ], 'the view asked for');
	$t->start;
	my @board = grep { /\A\|/ } split /\n/, $$out;
	is(scalar @board, 10, 'ten board rows in the one frame');
	is(length $board[0], 26 + 2, 'each row is cols + 2 bytes');
	like($$out, qr/^\+-{26}\+$/m, 'ascii frame');
	like($$out, qr/\|.*(?:o\@|\@o).*\|/, 'the bird is a blob with its centre marked (two cells on this coarse view)');
	my ($row) = grep { /\@/ } @board;
	is(index($row, '@'), 1 + int(80 / (516 / 26)), 'the centre cell is in the column of x 80');
	is((grep { $board[$_] =~ /\@/ } 0 .. $#board)[0], int(176 / (400 / 10)), 'and in the row of y 176');
	($t, $out) = terminal([ ' ', 'q' ], ascii => 0);
	$t->start;
	like($$out, qr/\xE2\x97\x89/, 'the wide centre glyph');
	unlike($$out, qr/o\@|\@o/, 'and no ascii bird');
};

subtest 'pipes are drawn to the lip, with a half block for half a cell' => sub {
	my ($t, $out) = terminal([ (undef) x 240 ], seed => 'pipes', max_ticks => 240, watch => 1, level => 3, rows => 20, cols => 52);
	my $game = $t->game;
	$t->start;
	ok(@{ $game->tubes }, 'a tube is on the field at the cap');
	my $tube = $game->tubes->[0];
	my $ppr = 400 / 20;
	my $full = int($tube->{gap_top} / $ppr);
	my @lines = $t->board_lines;
	my $col = int(($tube->{x} + 10) / (516 / 52));
	my @column = map { substr($lines[ $_ + 1 ], $col + 1, 1) } 0 .. 19;
	is(join('', @column[0 .. $full - 1]), '#' x $full, "rows above gap_top $tube->{gap_top} are pipe") if $full;
	my $rest = $tube->{gap_top} - $full * $ppr;
	is($column[$full], $rest >= $ppr / 2 ? '=' : ' ', 'the lip cell is a half block iff half covered');
	my $bottom_row = int($tube->{gap_bottom} / $ppr);
	is($column[$bottom_row + 1], '#', 'below gap_bottom is pipe') if $bottom_row + 1 < 20;
};

subtest 'colour carries no information' => sub {
	my ($t, $plain) = terminal([ ' ', (undef) x 3, 'q' ], ansi => 0);
	$t->start;
	my ($c, $coloured) = terminal([ ' ', (undef) x 3, 'q' ], ansi => 1);
	$c->start;
	like($$coloured, qr/\e\[1;36m/, 'the coloured run has paint');
	(my $stripped = $$coloured) =~ s/\e\[[0-9;]*m//g;
	is($stripped, $$plain, 'stripped of every escape it is the plain run, byte for byte');
	local $ENV{NO_COLOR} = '1';
	my ($n, $none) = terminal([ ' ', 'q' ], ansi => 1);
	$n->start;
	unlike($$none, qr/\e\[/, 'NO_COLOR beats ansi => 1');
};

subtest 'the sleeper is never called while a keysource exists' => sub {
	my ($t, $out, $slept) = terminal([ ' ', (undef) x 10, 'q' ]);
	$t->start;
	is($$slept, 0, 'no sleep');
};

subtest 'the view is fitted to the window' => sub {
	my ($t) = terminal([ 'q' ], rows => undef, cols => undef, columns => 80, lines => 24);
	is_deeply([ $t->view ], [ 49, 19 ], '80x24 holds 19 rows by 49');
	is($t->too_narrow, undef, 'and it fits');
	($t) = terminal([ 'q' ], rows => undef, cols => undef, columns => 100, lines => 30);
	is_deeply([ $t->view ], [ 65, 25 ], '100x30 is capped at 25 rows, 65 columns');
	($t) = terminal([ 'q' ], rows => undef, cols => undef, columns => 40, lines => 40);
	is_deeply([ $t->view ], [ 36, 14 ], 'a narrow window shrinks the rows to fit the columns');
	($t) = terminal([ 'q' ], rows => undef, cols => undef);
	is_deeply([ $t->view ], [ 52, 20 ], 'with nothing to measure the view is 52 by 20');
	($t) = terminal([ 'q' ], rows => undef, cols => undef, columns => 10, lines => 5);
	like($t->too_narrow, qr/needs 28 by 15/, 'a tiny window is floored at 10 rows and refused');
};

subtest 'an explicit view that does not fit is refused' => sub {
	my ($t, $out) = terminal([ ' ', 'q' ], rows => 25, cols => 65, columns => 80, lines => 24);
	my $result = $t->start;
	is($result, undef, 'start returned nothing');
	is($t->stopped, 'narrow', 'stopped as narrow');
	like($t->refusal, qr/^This window is 80 columns by 24 lines, and a view 65 by 25 needs 67 by 30\./, 'with both sizes');
	is($t->frames, 0, 'no frame was drawn');
	is($$out, '', 'and nothing was written');
};

subtest 'no keys and no watch cannot play' => sub {
	my ($t) = terminal([], keysource => undef);
	is($t->keys_available, 0, 'a string handle is not a terminal');
	is($t->start, undef, 'start returned nothing');
	is($t->stopped, 'keys', 'stopped as keys');
	is($t->refusal, $t->cannot_play, 'with the sentence');
	like($t->refusal, qr/Term::ReadKey.*--watch/, 'which names the module and the way round');
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
		[ { level => 4 },     qr/a level is one of 1 2 3/, 'a level off the ladder' ],
		[ { cols => 'x' },    qr/cols must be a whole/,    'a width that is not a number' ],
		[ { rows => 5 },      qr/at least 10 by 10/,       'a view too small' ],
		[ { clock => 'now' }, qr/the clock is a code/,     'a clock that is not code' ],
	) {
		my ($args, $why, $name) = @$case;
		my $t = eval { terminal([], %$args) };
		like($@, $why, "$name is refused");
	}
};

subtest 'quiet draws nothing but says how it ended' => sub {
	my ($t, $out) = terminal([ ' ', (undef) x 3, 'q' ], quiet => 1);
	$t->start;
	is($t->frames, 0, 'no frames');
	is($$out, "Quit at 0 points after 3 ticks\n", 'only the sentence');
};

done_testing();
