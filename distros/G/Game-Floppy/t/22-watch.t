#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Floppy::Terminal;
use Game::Floppy::Bot;

# WATCH MODE READS NOTHING, so it works on a pipe. The bot is asked once a
# tick; with no keysource the terminal sleeps once a tick through the
# injectable sleeper and never touches Term::ReadKey. A watched game is one
# game: no again prompt.

sub watcher {
	my (%opt) = @_;
	my $output = '';
	open my $out, '>', \$output or die "cannot open a string handle: $!";
	my $typed = '';
	open my $in, '<', \$typed or die "cannot open a string handle: $!";
	my $slept = 0;
	my $terminal = Game::Floppy::Terminal->new(
		in => $in, out => $out, rows => 10, cols => 26, seed => 'watch',
		interactive => 0, ansi => 0, ascii => 1, watch => 1, level => 1,
		clock => sub { 1000 }, sleeper => sub { $slept++ },
		%opt,
	);
	return ($terminal, \$output, \$slept);
}

subtest 'the bot is asked once a tick' => sub {
	my $asked = 0;
	no warnings 'redefine';
	my $choose = \&Game::Floppy::Bot::choose;
	local *Game::Floppy::Bot::choose = sub { $asked++; $choose->(@_) };
	my ($t, $out) = watcher(max_ticks => 400, keysource => sub { undef });
	my $result = $t->start;
	ok($result, 'the game ended or was capped');
	is($asked, $t->ticker->ticks, 'one choice a tick');
	is($t->frames, $t->ticker->ticks + 1, 'frames are ticks plus one');
	is($t->games, 1, 'one game, no again prompt');
	cmp_ok($t->ticker->ticks, '>', 100, 'and it flew past the first tube');
	like($$out, qr/watching level 1/, 'the legend says what is being watched');
};

subtest 'with nothing to read it sleeps once a tick' => sub {
	my ($t, $out, $slept) = watcher(max_ticks => 50);
	is($t->keys_available, 0, 'no keys');
	ok($t->start, 'played anyway');
	is($$slept, $t->ticker->ticks, 'one sleep a tick');
	cmp_ok($t->ticker->ticks, '>', 0, 'ticks happened');
};

subtest 'the cap' => sub {
	my ($t) = watcher(max_ticks => 7, level => 3);
	my $result = $t->start;
	is($t->ticker->ticks, 7, 'stopped at the cap');
	is($t->stopped, 'capped', 'as capped');
	is($result->cause, 'quit', 'and the result is a quit');
};

subtest 'a watcher can still quit' => sub {
	my @keys = (undef, undef, 'q');
	my ($t) = watcher(max_ticks => 100, keysource => sub { shift @keys });
	$t->start;
	is($t->ticker->ticks, 2, 'two ticks then the q');
	is($t->stopped, 'quit', 'quit');
};

subtest 'a watcher cannot flap' => sub {
	my @keys = (' ', ' ', undef, 'q');
	my ($t) = watcher(max_ticks => 100, keysource => sub { shift @keys });
	$t->start;
	is($t->refused, 0, 'two spaces were ignored, not refused');
	is($t->game->bird->{y}, 179, 'and the bird simply fell');
};

subtest 'level 1 dies in the end and the game is one game' => sub {
	my ($t, $out) = watcher(level => 1, seed => 'short', max_ticks => 20000);
	my $result = $t->start;
	ok($result->died, 'the bot died (' . $result->cause . ')');
	cmp_ok($result->score, '>', 0, 'having scored');
	is($t->stopped, '', 'nothing stopped it but the game');
	is($t->games, 1, 'one game');
	cmp_ok($t->best, '>=', $result->score, 'best is at least the score');
};

done_testing();
