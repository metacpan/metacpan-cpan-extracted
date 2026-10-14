#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Line;
use Game::Terminal::Kit::Test::Screen qw/kit/;

sub step { my ($line, $key) = @_; return [ $line->step($key) ] }

subtest 'typing' => sub {
	plan tests => 13;
	my $line = Game::Terminal::Kit::Line->new(prompt => 'seed: ');
	is_deeply [$line->lines], ['seed: '], 'the prompt alone to begin with';
	is_deeply step($line, 'a'), ['changed'], 'a letter changes it';
	is_deeply step($line, ' '), ['changed'], 'so does a space';
	is_deeply step($line, 'q'), ['changed'], 'and q is a letter here';
	is_deeply [$line->lines], ['seed: a q'], 'what was typed is after the prompt';
	is_deeply step($line, 'backspace'), ['changed'], 'backspace takes one off';
	is $line->text, 'a ', 'the last one';
	is_deeply step($line, 'up'), ['none'], 'a key with a name does nothing';
	is_deeply step($line, 'tab'), ['none'], 'nor tab';
	is_deeply step($line, "\x01"), ['none'], 'nor a control character';
	is $line->text, 'a ', 'and the text is as it was';
	is_deeply step($line, 'enter'), ['chosen', 'a '], 'enter answers with the text, untrimmed';
	is_deeply step($line, 'escape'), ['back'], 'escape gives up';
};

subtest 'the ends' => sub {
	plan tests => 9;
	my $line = Game::Terminal::Kit::Line->new;
	is_deeply step($line, 'backspace'), ['none'], 'backspace on nothing does nothing';
	is_deeply step($line, 'enter'), ['chosen', ''], 'enter on nothing is an empty answer';
	is_deeply step($line, 'eof'), ['quit'], 'the end of input quits';
	is_deeply step($line, 'interrupt'), ['quit'], 'so does an interrupt';
	is_deeply step($line, undef), ['quit'], 'and no key at all';

	$line = Game::Terminal::Kit::Line->new(limit => 2, text => 'a');
	is_deeply step($line, 'b'), ['changed'], 'up to the limit';
	is_deeply step($line, 'c'), ['none'], 'and no further';
	is $line->text, 'ab', 'the text stops at the limit';
	is_deeply [Game::Terminal::Kit::Line->new(head => ['a board', ''], prompt => '> ', text => 'x')->lines],
		['a board', '', '> x'], 'the head is drawn above';
};

subtest 'run reads until it is answered' => sub {
	plan tests => 6;
	my ($keys, $screen, $text) = kit(keys => "ab\x7fc\e[A\r");
	my $line = Game::Terminal::Kit::Line->new(prompt => ': ');
	is_deeply [$line->run($keys, $screen)], ['chosen', 'ac'], 'typed, rubbed out, typed, entered';
	is ${$text}, ": \n: a\n: ab\n: a\n: ac\n: ac\n", 'one frame a key, the arrow drawing it again unchanged';

	($keys, $screen) = kit(keys => "ab\e");
	is_deeply [Game::Terminal::Kit::Line->new->run($keys, $screen)], ['back'], 'escape goes back';
	($keys, $screen) = kit(keys => 'ab');
	is_deeply [Game::Terminal::Kit::Line->new->run($keys, $screen)], ['quit'], 'keys running out quits';
	($keys, $screen) = kit(keys => "a\x04");
	is_deeply [Game::Terminal::Kit::Line->new->run($keys, $screen)], ['quit'], 'control-D quits';

	($keys, $screen) = kit(keys => "xy\r");
	my $stepped = Game::Terminal::Kit::Line->new;
	my @last;
	while (defined(my $key = $keys->read_key)) { @last = $stepped->step($key) }
	is_deeply \@last, ['chosen', 'xy'], 'stepping by hand gives what run gives';
};

done_testing;
