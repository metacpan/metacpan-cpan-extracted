#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Picker;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Widget;
use Game::Terminal::Kit::Test::Screen qw/kit/;

sub picker { return Game::Terminal::Kit::Picker->new(@_) }
sub step { my ($picker, $key) = @_; return [ $picker->step($key) ] }
sub walk {
	my ($picker, $key, $times) = @_;
	my @seen = ($picker->current);
	for (1 .. $times) {
		$picker->step($key);
		push @seen, $picker->current;
	}
	return \@seen;
}

my @moves = map { { label => "move $_", value => "m$_" } } 1 .. 4;

subtest 'the rows' => sub {
	plan tests => 7;
	is_deeply [picker(items => [qw/alpha beta/])->lines], [' >  1. alpha', '    2. beta'],
		'strings, numbered, the cursor on the first';
	is_deeply [picker(items => [qw/alpha beta/], numbered => 0)->lines], [' > alpha', '   beta'], 'not numbered';
	is_deeply [picker(items => [{ label => 'a', about => 'first' }, { label => 'long', about => '' }, { label => 'c' }],
		numbered => 0)->lines],
		[' > a     first', '   long', '   c'], 'a second column, lined up, with nothing trailing';
	is_deeply [picker(items => [qw/a b/], head => ['a board', ''], legend => ['', 'keys'], numbered => 0)->lines],
		['a board', '', ' > a', '   b', '', 'keys'], 'the head above and the legend below, as given';
	is_deeply [picker(items => [])->lines], [], 'nothing to choose is no rows';
	is_deeply [picker(items => [qw/a b/], numbered => 0)->rows], [' > a', '   b'], 'rows alone';

	open my $sink, '>', \my $unused or die $!;
	my $screen = Game::Terminal::Kit::Screen->new(out => $sink, colour => 1);
	is_deeply [picker(items => ['a', { label => 'b', skip => 1 }], numbered => 0, screen => $screen)->lines],
		[" \e[1;7m> a\e[0m", "   \e[2mb\e[0m"], 'with colour the cursor is reversed and a skipped row dim';
};

subtest 'the cursor walks the drawn order' => sub {
	plan tests => 8;
	is_deeply walk(picker(items => \@moves), 'down', 4), [qw/m1 m2 m3 m4 m1/], 'down, and round';
	is_deeply walk(picker(items => \@moves), 'up', 4), [qw/m1 m4 m3 m2 m1/], 'up, and round';
	is_deeply walk(picker(items => \@moves), 'right', 2), [qw/m1 m2 m3/], 'right goes the way down does';
	is_deeply walk(picker(items => \@moves), 'left', 2), [qw/m1 m4 m3/], 'left the way up does';
	is_deeply walk(picker(items => \@moves), 'tab', 2), [qw/m1 m2 m3/], 'tab goes on';
	is_deeply walk(picker(items => \@moves), 'back_tab', 2), [qw/m1 m4 m3/], 'shift-tab goes back';
	is_deeply walk(picker(items => \@moves, across => 1), 'up', 2), [qw/m1 m2 m3/], 'in a row, up goes the way right does';
	is_deeply walk(picker(items => \@moves, across => 1), 'down', 2), [qw/m1 m4 m3/], 'and down the way left does';
};

subtest 'every event' => sub {
	plan tests => 17;
	my $picker = picker(items => \@moves, game_keys => { '?' => 'help', q => 'resign', k => 'king' });
	is_deeply step($picker, 'down'), ['moved'], 'a move';
	is_deeply step($picker, 'enter'), ['chosen', 'm2'], 'enter chooses what is under the cursor';
	is_deeply step($picker, ' '), ['chosen', 'm2'], 'so does space';
	is_deeply step($picker, 'escape'), ['back'], 'escape goes back';
	is_deeply step($picker, 'backspace'), ['back'], 'so does backspace';
	is_deeply step($picker, '?'), ['key', 'help'], 'a key of the game comes back by its name';
	is_deeply step($picker, 'q'), ['key', 'resign'], 'the game may take q';
	is_deeply step($picker, 'k'), ['key', 'king'], 'or any letter';
	is_deeply step($picker, 'x'), ['none'], 'a key that means nothing';
	is_deeply step($picker, 'eof'), ['quit'], 'the end of input quits';
	is_deeply step($picker, 'interrupt'), ['quit'], 'so does an interrupt';
	is_deeply step($picker, undef), ['quit'], 'and no key';
	is_deeply step(picker(items => \@moves), 'q'), ['quit'], 'q quits when the game has not taken it';
	is_deeply step(picker(items => ['only']), 'down'), ['none'], 'a move with nowhere to go is none';
	is_deeply step(picker(items => ['only']), 'enter'), ['chosen', 'only'], 'a string is its own value';
	is_deeply step(picker(items => [{ label => 'x', value => undef }]), 'enter'), ['chosen', undef], 'a value may be undef';
	is_deeply step(picker(items => []), 'enter'), ['none'], 'nothing to choose chooses nothing';
};

subtest 'home, end and the digits' => sub {
	plan tests => 10;
	my $picker = picker(items => \@moves);
	is_deeply step($picker, 'end'), ['moved'], 'end';
	is $picker->current, 'm4', 'is the last';
	is_deeply step($picker, 'end'), ['none'], 'end again is none';
	$picker->step('home');
	is $picker->current, 'm1', 'home is the first';
	$picker->step('page_down');
	is $picker->current, 'm4', 'page down is the last';
	$picker->step('page_up');
	is $picker->current, 'm1', 'page up is the first';
	$picker->step('3');
	is $picker->current, 'm3', 'a digit is that row';
	is_deeply step($picker, '5'), ['none'], 'a digit past the end is none';
	is $picker->current, 'm3', 'and the cursor stays';
	is_deeply step(picker(items => \@moves, numbered => 0), '3'), ['none'], 'digits do nothing when the rows are not numbered';
};

subtest 'an item that is drawn and cannot be chosen' => sub {
	plan tests => 11;
	my @hand = (
		{ label => 'taken', value => 'T', skip => 1 },
		{ label => 'K hearts', value => 'KH', meld => 1 },
		{ label => '4 diamonds', value => '4D' },
		{ label => 'pile', value => 'P', skip => 1 },
		{ label => '9 clubs', value => '9C' },
		{ label => 'last', value => 'L', skip => 1 },
	);
	my $picker = picker(items => \@hand, numbered => 0);
	is $picker->at, 1, 'the cursor starts on the first that can be chosen';
	is_deeply [$picker->lines], ['   taken', ' > K hearts', '   4 diamonds', '   pile', '   9 clubs', '   last'],
		'every item is drawn';
	is_deeply walk($picker, 'down', 3), [qw/KH 4D 9C KH/], 'down steps over the skipped ones, and round';
	is_deeply walk($picker, 'up', 3), [qw/KH 9C 4D KH/], 'and so does up';
	$picker->step('end');
	is $picker->current, '9C', 'end is the last that can be chosen';
	$picker->step('home');
	is $picker->current, 'KH', 'home the first';
	is $picker->skipped(0) + $picker->skipped(3) + $picker->skipped(1), 2, 'skipped says which';

	is picker(items => \@hand, prefer => sub { !$_[0]{meld} })->current, '4D', 'the cursor rests on what is preferred';
	is_deeply step(picker(items => \@hand), '1'), ['none'], 'a digit does not land on a skipped row';

	my $none = picker(items => [{ label => 'a', skip => 1 }, { label => 'b', skip => 1 }], numbered => 0);
	is_deeply [$none->lines], ['   a', '   b'], 'all skipped is drawn with no cursor';
	is_deeply [step($none, 'down'), step($none, 'enter'), step($none, 'home'), $none->current],
		[['none'], ['none'], ['none'], undef], 'and nothing moves or is chosen';
};

subtest 'a window on a long list' => sub {
	plan tests => 7;
	my @twenty = map { "row $_" } 1 .. 20;
	my $picker = picker(items => \@twenty, numbered => 0);
	is_deeply [$picker->rows], [' > row 1', (map { "   row $_" } 2 .. 8), '    12 further down'], 'at the top';
	$picker->step('down') for 1 .. 9;
	is_deeply [$picker->rows],
		['    5 further up', (map { "   row $_" } 6 .. 9), ' > row 10', (map { "   row $_" } 11 .. 13), '    7 further down'],
		'in the middle, the cursor four rows down';
	$picker->step('end');
	is_deeply [$picker->rows], ['    12 further up', (map { "   row $_" } 13 .. 19), ' > row 20'], 'at the bottom';
	is scalar(grep { m/^ > / } map { $picker->step('up'); $picker->rows } 1 .. 20), 20,
		'the cursor is in the window after every step of a whole turn';

	is scalar(@{[ picker(items => \@twenty, window => 0)->rows ]}), 20, 'a window of 0 draws them all';
	is scalar(@{[ picker(items => [@twenty[0 .. 7]])->rows ]}), 8, 'a list the size of the window has no counts';
	is_deeply [picker(items => \@twenty, window => 3, at => 19, numbered => 0)->rows],
		['    17 further up', '   row 18', '   row 19', ' > row 20'], 'a small window, starting at the end';
};

subtest 'choosing several' => sub {
	plan tests => 10;
	my $picker = picker(items => [qw/A B C D/], need => 2, numbered => 0);
	is_deeply [$picker->rows], [' > [ ] A', '   [ ] B', '   [ ] C', '   [ ] D'], 'boxes';
	$picker->step('down') for 1 .. 2;
	is_deeply step($picker, 'enter'), ['changed'], 'the first tick is not an answer';
	is_deeply [$picker->rows], ['   [ ] A', '   [ ] B', ' > [x] C', '   [ ] D'], 'and is drawn';
	is_deeply step($picker, 'enter'), ['changed'], 'enter again unticks';
	is_deeply $picker->chosen, [], 'so nothing is ticked';
	$picker->step(' ');
	$picker->step('up') for 1 .. 2;
	is_deeply step($picker, 'enter'), ['chosen', ['A', 'C']], 'the second tick answers, in drawn order';
	is_deeply $picker->chosen, [0, 2], 'chosen holds the indexes';

	is $picker->reset([qw/X Y/]), $picker, 'reset returns the picker';
	is_deeply [$picker->rows], [' > [ ] X', '   [ ] Y'], 'new items, nothing ticked, the cursor at rest';
	is_deeply step(picker(items => [qw/A B/], need => 1), 'enter'), ['chosen', ['A']], 'a need of one answers at once, with a list';
};

subtest 'what just happened is in every frame' => sub {
	plan tests => 8;
	my $log = Game::Terminal::Kit::Log->new;
	$log->record('White took b6.');
	my $picker = picker(items => [qw/a b/], numbered => 0, log => $log, head => ['board'],
		game_keys => { '?' => 'help' });
	is_deeply [$picker->lines], ['board', 'White took b6.', '', ' > a', '   b'], 'the log between the head and the rows';
	$picker->step('x');
	is_deeply [$picker->lines],
		['board', 'White took b6.', 'That key does nothing here. Press ? for the ones that do.', '', ' > a', '   b'],
		'a key that does nothing is noted';

	my ($keys, $screen, $text) = kit(keys => "\e[Bx\e[A\r");
	is_deeply [$picker->run($keys, $screen)], ['chosen', 'a'], 'down, a stray key, up, enter';
	my @frames = split /(?=^board$)/m, ${$text};
	is scalar(@frames), 4, 'four keys were read, so four frames were drawn';
	is scalar(grep { m/^White took b6\.$/m } @frames), 4, 'and the move is in every one';
	is scalar(grep { m/does nothing/ } @frames), 2, 'the note is in the frame it was owed and the one after the stray key';
	is_deeply [$log->lines], ['White took b6.'], 'afterwards the record is kept and the notes are gone';

	my $quiet = picker(items => [qw/a b/]);
	is_deeply [$quiet->step('x'), $quiet->lines], ['none', ' >  1. a', '    2. b'], 'without a log nothing is said';
};

subtest 'run, and the same by hand' => sub {
	plan tests => 8;
	my ($keys, $screen, $text) = kit(keys => "\e[B\e[B\r");
	is_deeply [picker(items => \@moves)->run($keys, $screen)], ['chosen', 'm3'], 'down twice and enter';
	like ${$text}, qr/\A >  1\. move 1\n/, 'the first frame has the cursor on the first row';
	like ${$text}, qr/ >  3\. move 3\n    4\. move 4\n\z/, 'and the last on the third';

	($keys, $screen) = kit(keys => "\e[B\e[B\r");
	my $by_hand = picker(items => \@moves);
	my @last;
	while (defined(my $key = $keys->read_key)) { @last = $by_hand->step($key) }
	is_deeply \@last, ['chosen', 'm3'], 'stepping by hand gives what run gives';

	($keys, $screen) = kit(keys => "\e[B");
	is_deeply [picker(items => \@moves)->run($keys, $screen)], ['quit'], 'keys running out quits';
	($keys, $screen) = kit(keys => "\e");
	is_deeply [picker(items => \@moves)->run($keys, $screen)], ['back'], 'escape goes back';
	($keys, $screen) = kit(keys => "\e[B?");
	is_deeply [picker(items => \@moves, game_keys => { '?' => 'help' })->run($keys, $screen)], ['key', 'help'],
		'a key of the game ends run';

	ok Game::Terminal::Kit::Widget::goes_on('moved') && Game::Terminal::Kit::Widget::goes_on('changed')
		&& Game::Terminal::Kit::Widget::goes_on('none') && !Game::Terminal::Kit::Widget::goes_on('chosen')
		&& !Game::Terminal::Kit::Widget::goes_on(undef), 'three events go on and the rest end';
};

done_testing;
