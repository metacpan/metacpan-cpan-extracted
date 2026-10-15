#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal;
use Game::Terminal::Menu;

my @ALL = Game::Terminal::games();

my %FIELDS = (
	checkers => [
		{ name => 'level', type => 'int', min => 1, max => 5, help => 'the strength of the bot' },
		{ name => 'side', type => 'enum', choices => [qw(black white random)], help => 'your side; black moves first' },
		{ name => 'hotseat', type => 'flag', help => 'two people at one keyboard, no bot' },
		{ name => 'bot-vs-bot', type => 'flag', help => 'watch two bots play' },
		{ name => 'seed', type => 'str', help => 'the bot varies its easy levels with it' },
	],
	merrills => [
		{ name => 'level', type => 'int', min => 1, max => 5, help => "the bot's strength" },
		{ name => 'side', type => 'enum', choices => [qw(white black random)], help => 'your side' },
		{ name => 'hotseat', type => 'flag', help => 'two people at one keyboard, no bot' },
		{ name => 'bot-vs-bot', type => 'flag', help => 'watch two bots' },
		{ name => 'flying', type => 'bool', help => 'a side down to three men may fly' },
		{ name => 'seed', type => 'str', help => 'the same seed, the same game' },
	],
);

sub menu {
	my ($keys, %option) = @_;
	my @chars = split //, defined $keys ? $keys : '';
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	my @ran;
	my $menu = Game::Terminal::Menu->new(
		out => $out,
		interactive => 0,
		colour => 0,
		keysource => sub { shift @chars },
		picking => 1,
		games => [ map { { %{$_}, installed => 1, options => $FIELDS{ $_->{key} } || [] } } @ALL ],
		runner => sub { my ($row, $argv, %seam) = @_; push @ran, [ $row->{key}, @{$argv} ]; return (0, undef) },
		%option
	);
	return ($menu, \$output, \@ran);
}

my $DOWN = "\e[B";
my $UP = "\e[A";
my $RIGHT = "\e[C";
my $LEFT = "\e[D";
my $ENTER = "\r";
my $BACKSPACE = "\x7f";

subtest 'enter opens the form on Play, and enter again plays with nothing set' => sub {
	plan tests => 4;
	my ($menu, $output, $ran) = menu("$DOWN$DOWN$ENTER$ENTER" . 'q');
	$menu->start;
	is_deeply $ran, [['checkers']], 'checkers ran with no arguments';
	like ${$output}, qr/^checkers: English draughts$/m, 'the form carried the title';
	like ${$output}, qr/> Play/, 'with the cursor on Play';
	like ${$output}, qr/the game's own\s+the strength of the bot/, 'and level left to the game';
};

subtest 'down from Play wraps to the first field; right steps the level' => sub {
	plan tests => 2;
	my ($menu, $output, $ran) = menu("$DOWN$DOWN$ENTER$DOWN$RIGHT$RIGHT$RIGHT" . 'p' . 'q');
	$menu->start;
	is_deeply $ran, [['checkers', '--level', 3]], 'three rights from unset is 3';
	like ${$output}, qr/> level\s+3\s/, 'and the form showed it';
};

subtest 'an int stops at its ends, and left from unset is the top' => sub {
	plan tests => 2;
	my ($menu, undef, $ran) = menu("$DOWN$DOWN$ENTER$DOWN" . ($RIGHT x 9) . 'p' . 'q');
	$menu->start;
	is_deeply $ran, [['checkers', '--level', 5]], 'nine rights stop at 5';
	my ($left, undef, $ran2) = menu("$DOWN$DOWN$ENTER$DOWN$LEFT" . 'p' . 'q');
	$left->start;
	is_deeply $ran2, [['checkers', '--level', 5]], 'one left from unset is 5';
};

subtest 'backspace clears a field' => sub {
	plan tests => 1;
	my ($menu, undef, $ran) = menu("$DOWN$DOWN$ENTER$DOWN$RIGHT$RIGHT$BACKSPACE" . 'p' . 'q');
	$menu->start;
	is_deeply $ran, [['checkers']], 'cleared, nothing is sent';
};

subtest 'an enum cycles and a flag toggles' => sub {
	plan tests => 2;
	my ($menu, undef, $ran) = menu("$DOWN$DOWN$ENTER$DOWN$DOWN$RIGHT$RIGHT$DOWN$RIGHT" . 'p' . 'q');
	$menu->start;
	is_deeply $ran, [['checkers', '--side', 'white', '--hotseat']], 'side went black then white, hotseat on';
	my ($twice, undef, $ran2) = menu("$DOWN$DOWN$ENTER$DOWN$DOWN$DOWN$RIGHT$RIGHT" . 'p' . 'q');
	$twice->start;
	is_deeply $ran2, [['checkers']], 'a flag toggled twice is off again';
};

subtest 'a bool cycles own, on, off' => sub {
	plan tests => 3;
	my $to_flying = "mmm$ENTER" . ($DOWN x 5);
	my ($on, undef, $ran) = menu("$to_flying$RIGHT" . 'p' . 'q');
	$on->start;
	is_deeply $ran, [['merrills', '--flying']], 'one right is on';
	my ($off, undef, $ran2) = menu("$to_flying$RIGHT$RIGHT" . 'p' . 'q');
	$off->start;
	is_deeply $ran2, [['merrills', '--no-flying']], 'two is off';
	my ($own, undef, $ran3) = menu("$to_flying$RIGHT$RIGHT$RIGHT" . 'p' . 'q');
	$own->start;
	is_deeply $ran3, [['merrills']], 'and three is the game\'s own again';
};

subtest 'a typed field reads a line from in' => sub {
	plan tests => 3;
	open my $in, '<', \"tuesday\n--fen \"a b\" --x\n" or die $!;
	my ($menu, $output, $ran) = menu("$DOWN$DOWN$ENTER$UP$UP$ENTER$DOWN$ENTER" . 'p' . 'q', in => $in);
	$menu->start;
	is_deeply $ran, [['checkers', '--seed', 'tuesday', '--fen', 'a b', '--x']],
		'the seed and the extra line, the extra split like a shell';
	like ${$output}, qr/^seed: /m, 'the seed was prompted for';
	like ${$output}, qr/^extra: /m, 'and so was extra';
};

subtest 'a typed int is checked against its range' => sub {
	plan tests => 2;
	open my $in, '<', \"9\n4\n" or die $!;
	my ($menu, $output, $ran) = menu("$DOWN$DOWN$ENTER$DOWN$ENTER$ENTER" . 'p' . 'q', in => $in);
	$menu->start;
	is_deeply $ran, [['checkers', '--level', 4]], '9 was refused and 4 taken';
	like ${$output}, qr/level takes a whole number from 1 to 5/, 'with the reason on the screen';
};

subtest 'escape goes back with nothing run, and the values are remembered' => sub {
	plan tests => 2;
	my ($menu, undef, $ran) = menu("$DOWN$DOWN$ENTER$DOWN$RIGHT$RIGHT\e" . "$ENTER$ENTER" . 'q');
	$menu->start;
	is_deeply $ran, [['checkers', '--level', 2]], 'the escape ran nothing; the second visit found level 2 and played it';
	is_deeply $menu->values->{checkers}, { level => 2 }, 'and the memory holds it';
};

subtest 'a game with no options still has extra and Play' => sub {
	plan tests => 2;
	my ($menu, $output, $ran) = menu("ccc$ENTER$ENTER" . 'q');
	$menu->start;
	is_deeply $ran, [['cribbage']], 'cribbage played';
	like ${$output}, qr/extra\s+\(none\)/, 'with an extra line offered';
};

subtest 'the prompt without keys asks for an options line' => sub {
	plan tests => 3;
	my @ran;
	my $output = '';
	open my $out, '>', \$output or die $!;
	open my $in, '<', \"3\n--level 2 --seed \"x y\"\n3\n\n\n" or die $!;
	my $menu = Game::Terminal::Menu->new(
		in => $in, out => $out, interactive => 0, colour => 0, picking => 0,
		games => [ map { { %{$_}, installed => 1 } } @ALL ],
		runner => sub { my ($row, $argv) = @_; push @ran, [ $row->{key}, @{$argv} ]; return (0, undef) },
	);
	is $menu->start, 0, 'a blank line at the game prompt leaves';
	is_deeply \@ran, [['checkers', '--level', 2, '--seed', 'x y'], ['checkers']],
		'the options line is split like a shell, and blank means none';
	like $output, qr/Options for checkers, as on the command line/, 'the line was asked for';
};

done_testing;
