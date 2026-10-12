#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Snake;
use Game::Snake::Bot;
use Game::Snake::Terminal;

# ---- WRITTEN DOWN BEFORE THE RUN ---------------------------------------------
#
#   GAMES     two thousand through the engine, the bot at both levels in
#             turn, each game from its own seed on one of three boards; then
#             two hundred through the terminal, watched, with a keysource
#             that never answers, so every tick is a tick and no sleep,
#             capped at five thousand ticks each.
#
#   ASSERTED  every game ends with a cause the result class knows, or hits
#             the cap (flood-fill can circle for ever round food that sits
#             in a pocket smaller than itself, and that is a property of the
#             rule, not a fault); the snake's length plus the growth still
#             owed is the start length plus the meals; free cells
#             and the snake make the board; the same seed is the same game
#             twice (every tenth game is replayed and compared); the terminal
#             draws one frame a tick and one more; nothing warns.
#
#   REPORTED  how the games ended, the mean score a level, and the time.
#
#     SNAKE_SOAK=1 prove -l xt/soak.t
#     SNAKE_SOAK=1 SNAKE_SOAK_GAMES=200 prove -l xt/soak.t

plan skip_all => 'set SNAKE_SOAK to run the soak: it plays thousands of games'
	unless $ENV{SNAKE_SOAK};

my $GAMES = $ENV{SNAKE_SOAK_GAMES} || 2000;
my @LEVELS = Game::Snake::Bot->levels;
my @BOARDS = ([ 10, 8 ], [ 16, 12 ], [ 24, 16 ]);
my %IS_CAUSE = map { $_ => 1 } @{ Game::Snake::Result->causes };

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub play {
	my ($n) = @_;
	my $level = $LEVELS[ $n % @LEVELS ];
	my $board = $BOARDS[ $n % @BOARDS ];
	my $game = Game::Snake->new(cols => $board->[0], rows => $board->[1], seed => "soak:$n");
	my $meals = 0;
	while ($game->status ne 'finished' && $game->ticks < 50_000) {
		my $direction = Game::Snake::Bot->choose($game, level => $level);
		$game->turn($direction) if $direction ne $game->heading;
		$meals++ if $game->tick->{ate};
	}
	return ($game, $level, $meals);
}

my (%ended, %score, %played, @wrong);
my $started = time;
for my $n (1 .. $GAMES) {
	my ($game, $level, $meals) = play($n);
	my $capped = $game->status ne 'finished';
	$game->quit if $capped;
	my $result = $game->result;
	push @wrong, "game $n ended as '" . $result->cause . "'" unless $IS_CAUSE{ $result->cause };
	push @wrong, "game $n is " . $game->length . ' long with ' . $game->growing . ' owed after ' . $meals . ' meals'
		unless $game->length + $game->growing == 3 + $meals;
	push @wrong, "game $n: free cells and the snake do not make the board"
		unless scalar($game->free_cells) + $game->length == $game->cols * $game->rows;
	$ended{ $capped ? 'capped' : $result->cause }++;
	$score{$level} += $game->score;
	$played{$level}++;
	if ($n % 10 == 0) {
		my ($again) = play($n);
		push @wrong, "game $n replayed differently"
			unless $again->score == $game->score && $again->ticks == $game->ticks
				&& $again->result->cause eq $result->cause;
	}
}
is_deeply(\@wrong, [], "$GAMES engine games were sound") or diag join "\n", @wrong[0 .. ($#wrong > 9 ? 9 : $#wrong)];
is_deeply([ sort keys %ended ], [ grep { $ended{$_} } qw/ body capped full quit wall / ], 'every ending is a known cause or the cap');
diag(sprintf 'engine: %d games in %ds; endings %s; mean score %s', $GAMES, time - $started,
	join(' ', map { "$_=$ended{$_}" } sort keys %ended),
	join(' ', map { sprintf '%d:%.0f', $_, $score{$_} / $played{$_} } sort keys %played));

my @terminal_wrong;
my $terminals = int($GAMES / 10) || 1;
for my $n (1 .. $terminals) {
	my $output = '';
	open my $out, '>', \$output or die $!;
	my $typed = '';
	open my $in, '<', \$typed or die $!;
	my $terminal = Game::Snake::Terminal->new(
		in => $in, out => $out, cols => 12, rows => 8, seed => "soak-terminal:$n",
		interactive => 0, ansi => 0, ascii => 1, watch => 1, level => $LEVELS[ $n % @LEVELS ], max_ticks => 5000,
		keysource => sub { undef }, clock => sub { 1000 }, sleeper => sub { die 'the terminal slept' },
	);
	my $result = $terminal->start;
	push @terminal_wrong, "terminal game $n did not end" and next unless $result;
	push @terminal_wrong, "terminal game $n drew " . $terminal->frames . ' frames for ' . $terminal->ticker->ticks . ' ticks'
		unless $terminal->frames == $terminal->ticker->ticks + 1;
	push @terminal_wrong, "terminal game $n ended '" . $result->cause . "' but stopped '" . $terminal->stopped . "'"
		unless $terminal->stopped eq '' || $terminal->stopped eq 'capped';
}
is_deeply(\@terminal_wrong, [], "$terminals terminal games were sound") or diag join "\n", @terminal_wrong[0 .. 9];

is_deeply(\@warnings, [], 'nothing warned') or diag join '', @warnings[0 .. ($#warnings > 4 ? 4 : $#warnings)];

done_testing();
