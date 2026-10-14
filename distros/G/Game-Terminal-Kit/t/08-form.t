#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Form;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Test::Screen qw/kit/;

my @fields = (
	{ name => 'level', type => 'int', min => 1, max => 5, help => 'the strength of the bot' },
	{ name => 'side', type => 'enum', choices => [qw(black white random)], help => 'your side' },
	{ name => 'hotseat', type => 'flag', help => 'two people' },
	{ name => 'flying', type => 'bool', help => 'three men may fly' },
	{ name => 'seed', type => 'str', help => 'the same game again' },
);

sub form { return Game::Terminal::Kit::Form->new(title => 'checkers: English draughts', fields => \@fields, @_) }
sub press { my ($form, @keys) = @_; my @last; @last = $form->step($_) for @keys; return \@last }

subtest 'the screen' => sub {
	plan tests => 5;
	my $form = form();
	is_deeply [$form->lines], [
		'checkers: English draughts', '',
		"   level       the game's own     the strength of the bot",
		"   side        the game's own     your side",
		'   hotseat     off                two people',
		"   flying      the game's own     three men may fly",
		"   seed        the game's own     the same game again",
		'   extra       (none)             anything else, as on the command line',
		'', ' > Play', '',
		'left and right change a value, enter edits a text, backspace clears,',
		'enter on Play starts, escape goes back',
	], 'the title, the fields, extra, Play under the cursor, the keys';
	is $form->at, 6, 'the cursor starts on Play';

	my @plain = form(extra => 0, title => '', legend => [], action => 'Deal',
		values => { level => 3, hotseat => 1, flying => 0 }, at => 0)->lines;
	is_deeply \@plain, [
		' > level       3                  the strength of the bot',
		"   side        the game's own     your side",
		'   hotseat     on                 two people',
		'   flying      off                three men may fly',
		"   seed        the game's own     the same game again",
		'', '   Deal',
	], 'no title, no extra, no legend, another action, values set, the cursor on a field';

	my $log = Game::Terminal::Kit::Log->new->note('level takes a whole number from 1 to 5');
	is_deeply [(form(log => $log, legend => [])->lines)[-3 .. -1]],
		[' > Play', '', 'level takes a whole number from 1 to 5'], 'the log is under Play';
	is_deeply [form(fields => [], extra => 0, title => '', legend => [])->lines], ['', ' > Play'], 'a game with no options still has Play';
};

subtest 'playing as it comes, and going back' => sub {
	plan tests => 8;
	my $form = form();
	is_deeply [$form->step('enter')], ['chosen', {}], 'enter on Play with nothing set';
	is_deeply [$form->argv], [], 'sends nothing';
	is_deeply [$form->step(' ')], ['chosen', {}], 'space on Play too';
	is_deeply [$form->step('escape')], ['back'], 'escape goes back';
	is_deeply [$form->step('q')], ['back'], 'q goes back too, and does not quit';
	is_deeply [$form->step('eof')], ['quit'], 'the end of input quits';
	is_deeply [$form->step('left')], ['none'], 'left on Play does nothing';
	is_deeply [form(at => 0)->step('p')], ['chosen', {}], 'p plays from any row';
};

subtest 'moving' => sub {
	plan tests => 5;
	my $form = form();
	is_deeply press($form, 'up'), ['moved'], 'up from Play';
	is $form->at, 5, 'is the extra field';
	is_deeply [press($form, 'down', 'down'), $form->at], [['moved'], 0], 'down from Play goes round to the first';
	is_deeply [press($form, 'k'), $form->at], [['moved'], 6], 'k is up';
	is_deeply [press($form, 'j', 'tab', 'back_tab'), $form->at], [['moved'], 0], 'j and tab are down, shift-tab up';
};

subtest 'a number' => sub {
	plan tests => 9;
	my $form = form(at => 0);
	is_deeply press($form, 'right'), ['changed'], 'right from the game\'s own';
	is $form->values->{level}, 1, 'is the least';
	press($form, ('right') x 2);
	is_deeply [$form->argv], ['--level', 3], 'right twice more sends level 3';
	press($form, ('right') x 9);
	is $form->values->{level}, 5, 'right stops at the top';
	press($form, 'backspace');
	ok !exists $form->values->{level}, 'backspace puts it back to the game\'s own';
	press($form, 'left');
	is $form->values->{level}, 5, 'left from the game\'s own is the greatest';
	is_deeply [$form->step('enter')], ['edit', $fields[0]], 'enter asks for a typed number';
	ok $form->set('level', ' 2 '), 'a typed number is taken';
	is $form->values->{level}, 2, 'and kept';
};

subtest 'a choice, a flag and a bool' => sub {
	plan tests => 10;
	my $form = form(at => 1);
	press($form, 'right');
	is $form->values->{side}, 'black', 'right is the first choice';
	press($form, 'left');
	is $form->values->{side}, 'random', 'left goes round';
	is_deeply [press($form, 'enter'), $form->values->{side}], [['changed'], 'black'], 'enter steps a choice';

	press($form, 'down', 'enter');
	is_deeply [$form->argv], ['--side', 'black', '--hotseat'], 'enter turns a flag on';
	press($form, ' ');
	ok !exists $form->values->{hotseat}, 'and space turns it off, leaving nothing set';

	press($form, 'down', 'enter');
	is_deeply [$form->argv], ['--side', 'black', '--flying'], 'a bool goes on';
	press($form, 'enter');
	is_deeply [$form->argv], ['--side', 'black', '--no-flying'], 'then off, which is sent';
	press($form, 'enter');
	is_deeply [$form->argv], ['--side', 'black'], 'then back to the game\'s own';
	press($form, 'delete');
	ok !exists $form->values->{flying}, 'delete clears as backspace does';
	is_deeply press($form, 'x'), ['none'], 'a stray key on a field does nothing';
};

subtest 'text' => sub {
	plan tests => 13;
	my $log = Game::Terminal::Kit::Log->new;
	my $form = form(at => 4, log => $log);
	is_deeply [$form->step('right')], ['none'], 'right on text does nothing';
	is_deeply [$log->lines], ['seed is typed: press enter'], 'and says why';
	$log->shown;
	is_deeply [$form->step('enter')], ['edit', $fields[4]], 'enter asks for a line';
	ok $form->set('seed', '  tuesday '), 'the line is taken';
	is_deeply [$form->argv], ['--seed', 'tuesday'], 'and sent trimmed';
	ok $form->set('seed', ''), 'a blank line is taken';
	ok !exists $form->values->{seed}, 'and clears';

	ok !$form->set('level', '9'), 'a number out of range is refused';
	is_deeply [$log->lines], ['level takes a whole number from 1 to 5'], 'with the reason noted';
	ok !exists $form->values->{level}, 'and nothing kept';
	ok !$form->set('nonesuch', 'x'), 'a field that is not there is refused';

	$form->set('extra', ' --fen "a b" -x ');
	$form->set('level', '4');
	is_deeply [$form->argv], ['--level', 4, '--fen', 'a b', '-x'], 'extra is split like a shell and last';
	$form->set('extra', '  ');
	is_deeply [$form->argv], ['--level', 4], 'and a blank extra clears it';
};

subtest 'the values are the caller\'s' => sub {
	plan tests => 3;
	my %remembered = (level => 5);
	my $form = form(values => \%remembered, at => 1);
	press($form, 'right');
	is_deeply \%remembered, { level => 5, side => 'black' }, 'changed in place';
	is_deeply [form(values => \%remembered)->argv], ['--level', 5, '--side', 'black'], 'so a form opened again finds them';
	is_deeply [form()->argv], [], 'and a form given none starts with none';
};

subtest 'run' => sub {
	plan tests => 9;
	my ($keys, $screen, $text) = kit(keys => "\r");
	is_deeply [form()->run($keys, $screen)], ['chosen', {}], 'enter plays as it comes';

	($keys, $screen) = kit(keys => "\e[B\e[C\e[C\e[C\e[A\r");
	my $form = form();
	is_deeply [$form->run($keys, $screen)], ['chosen', { level => 3 }], 'down to level, right three times, up to Play, enter';
	is_deeply [$form->argv], ['--level', 3], 'sends level 3';

	($keys, $screen, $text) = kit(keys => "\e[A\e[A\rtues\x7fsday\r\e[B\e[B\r");
	$form = form();
	is_deeply [$form->run($keys, $screen)], ['chosen', { seed => 'tuesday' }], 'up to seed, enter, a typed line, down to Play, enter';
	like ${$text}, qr/^   seed        the game's own     the same game again\n.*\n\nseed: tues$/ms,
		'the line is typed under the form';

	my $log = Game::Terminal::Kit::Log->new;
	($keys, $screen, $text) = kit(keys => "\e[B\r9\r\e[A\r");
	$form = form(log => $log);
	is_deeply [$form->run($keys, $screen)], ['chosen', {}], 'a number that is refused leaves nothing set';
	like ${$text}, qr/^level takes a whole number from 1 to 5$/m, 'and the reason was drawn';

	($keys, $screen) = kit(keys => "\e[B\r3\e\e");
	is_deeply [form()->run($keys, $screen)], ['back'], 'escape from the line keeps the form; escape again goes back';
	($keys, $screen) = kit(keys => "\e[B\r3");
	is_deeply [form()->run($keys, $screen)], ['quit'], 'keys running out in the line quits';
};

done_testing;
