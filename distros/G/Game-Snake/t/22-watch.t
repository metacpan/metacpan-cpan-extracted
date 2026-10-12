#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Snake::Terminal;
use Game::Snake::Bot;

# WATCH MODE READS NOTHING, so it works on a pipe. The bot is asked once a
# tick; with no keysource the terminal sleeps once a tick through the
# injectable sleeper and never touches Term::ReadKey.

sub watcher {
	my (%opt) = @_;
	my $output = '';
	open my $out, '>', \$output or die "cannot open a string handle: $!";
	my $typed = '';
	open my $in, '<', \$typed or die "cannot open a string handle: $!";
	my $slept = 0;
	my $terminal = Game::Snake::Terminal->new(
		in => $in, out => $out, cols => 12, rows => 8, seed => 'watch',
		interactive => 0, ansi => 0, ascii => 1, watch => 1, level => 1,
		clock => sub { 1000 }, sleeper => sub { $slept++ },
		%opt,
	);
	return ($terminal, \$output, \$slept);
}

subtest 'the bot is asked once a tick' => sub {
	my $asked = 0;
	no warnings 'redefine';
	my $choose = \&Game::Snake::Bot::choose;
	local *Game::Snake::Bot::choose = sub { $asked++; $choose->(@_) };
	my ($t, $out) = watcher(max_ticks => 200, keysource => sub { undef });
	my $result = $t->start;
	ok($result, 'the game ended or was capped');
	is($asked, $t->ticker->ticks, 'one choice a tick');
	is($t->frames, $t->ticker->ticks + 1, 'frames are ticks plus one');
	cmp_ok($t->ticker->ticks, '>', 10, 'and it was a game, not two ticks');
	like($$out, qr/watching level 1/, 'the legend says what is being watched');
};

subtest 'with nothing to read it sleeps once a tick' => sub {
	my ($t, $out, $slept) = watcher(max_ticks => 50);
	is($t->keys_available, 0, 'no keys');
	my $result = $t->start;
	ok($result, 'played anyway');
	is($$slept, $t->ticker->ticks, 'one sleep a tick');
	cmp_ok($t->ticker->ticks, '>', 0, 'ticks happened');
};

subtest 'the cap' => sub {
	my ($t) = watcher(max_ticks => 7, level => 2);
	my $result = $t->start;
	is($t->ticker->ticks, 7, 'stopped at the cap');
	is($t->stopped, 'capped', 'as capped');
	is($result->cause, 'quit', 'and the result is a quit');
};

subtest 'a watcher can still quit' => sub {
	my @keys = (undef, undef, 'q');
	my ($t) = watcher(max_ticks => 100, keysource => sub { shift @keys });
	my $result = $t->start;
	is($t->ticker->ticks, 2, 'two ticks then the q');
	is($t->stopped, 'quit', 'quit');
};

subtest 'a watcher cannot steer' => sub {
	my @keys = (split(//, "\e[C"), undef, 'q');
	my ($t) = watcher(max_ticks => 100, keysource => sub { shift @keys });
	$t->start;
	is($t->refused, 0, 'the reverse arrow was ignored, not refused');
	is($t->ticker->ticks, 1, 'and cost no tick');
};

subtest 'level 2 plays a whole game to its end' => sub {
	my ($t) = watcher(level => 2, cols => 10, rows => 8, seed => 'whole');
	my $result = $t->start;
	ok($result->died, 'the bot died in the end (' . $result->cause . ')');
	cmp_ok($result->score, '>', 0, 'having scored');
	is($t->stopped, '', 'and nothing stopped it but the game');
};

done_testing();
