#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Floppy;
use Game::Floppy::Bot;
use Game::Floppy::Terminal;

# ---- WRITTEN DOWN BEFORE THE RUN ---------------------------------------------
#
#   GAMES     two thousand through the engine, the bot at the three levels in
#             turn, each game from its own seed, capped at 5,000 ticks (the
#             top level does not die within 200,000); then two hundred through
#             the terminal, watched, with a keysource that never answers, so
#             every tick is a tick and no sleep, capped at 2,000 ticks each.
#
#   ASSERTED  every game ends with a cause the result class knows, or caps;
#             tubes times the tube score is the score; the same seed is the
#             same game twice (every tenth game replayed and compared); the
#             terminal draws one frame a tick and one more; nothing warns.
#
#   REPORTED  how the games ended, the mean score a level, and the time.
#
#     FLOPPY_SOAK=1 prove -l xt/soak.t
#     FLOPPY_SOAK=1 FLOPPY_SOAK_GAMES=200 prove -l xt/soak.t

plan skip_all => 'set FLOPPY_SOAK to run the soak: it plays thousands of games'
	unless $ENV{FLOPPY_SOAK};

my $GAMES = $ENV{FLOPPY_SOAK_GAMES} || 2000;
my @LEVELS = Game::Floppy::Bot->levels;
my %IS_CAUSE = map { $_ => 1 } @{ Game::Floppy::Result->causes };

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub play {
	my ($n) = @_;
	my $level = $LEVELS[ $n % @LEVELS ];
	my $game = Game::Floppy->new(seed => "soak:$n");
	while ($game->status ne 'finished' && $game->ticks < 5000) {
		$game->flap if Game::Floppy::Bot->choose($game, level => $level);
		$game->tick;
	}
	return ($game, $level);
}

my (%ended, %score, %played, @wrong);
my $started = time;
for my $n (1 .. $GAMES) {
	my ($game, $level) = play($n);
	my $capped = $game->status ne 'finished';
	$game->quit if $capped;
	my $result = $game->result;
	push @wrong, "game $n ended as '" . $result->cause . "'" unless $IS_CAUSE{ $result->cause };
	push @wrong, "game $n scored " . $game->score . ' for ' . $game->passed . ' tubes'
		unless $game->passed * $game->tube_score == $game->score;
	$ended{ $capped ? 'capped' : $result->cause }++;
	$score{$level} += $game->score;
	$played{$level}++;
	if ($n % 10 == 0) {
		my ($again) = play($n);
		push @wrong, "game $n replayed differently"
			unless $again->score == $game->score && $again->ticks == $game->ticks;
	}
}
is_deeply(\@wrong, [], "$GAMES engine games were sound") or diag join "\n", @wrong[0 .. ($#wrong > 9 ? 9 : $#wrong)];
is_deeply([ sort keys %ended ], [ grep { $ended{$_} } qw/ capped ground quit sky tube / ], 'every ending is a known cause or the cap');
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
	my $terminal = Game::Floppy::Terminal->new(
		in => $in, out => $out, rows => 10, cols => 26, seed => "soak-terminal:$n",
		interactive => 0, ansi => 0, ascii => 1, watch => 1, level => $LEVELS[ $n % @LEVELS ], max_ticks => 2000,
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
