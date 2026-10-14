#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Builder;

use Game::Terminal::Kit::Test::Handle;
use Game::Terminal::Kit::Test::Screen qw/keysource capture typed kit within/;

subtest 'a handle that refuses' => sub {
	plan tests => 7;
	tie local *REFUSES, 'Game::Terminal::Kit::Test::Handle';
	my $handle = \*REFUSES;
	ok !eval { print {$handle} 'x'; 1 }, 'print dies';
	is $@, "wrote to a handle\n", 'saying it wrote';
	ok !eval { printf {$handle} '%s', 'x'; 1 }, 'printf dies';
	ok !eval { my $line = readline $handle; 1 }, 'readline dies';
	is $@, "read from a handle\n", 'saying it read';
	ok !eval { my $char = getc $handle; 1 }, 'getc dies';
	ok eval { binmode $handle; close $handle; 1 }, 'binmode and close are let through';
};

subtest 'keys from a string' => sub {
	plan tests => 5;
	my $source = keysource("a\e");
	is $source->(), 'a', 'the first character';
	is $source->(1), "\e", 'the second, whatever the wait';
	is $source->(), undef, 'then undef';
	is $source->(), undef, 'and undef again';
	is keysource(undef)->(), undef, 'no string is no keys';
};

subtest 'handles in memory' => sub {
	plan tests => 5;
	my ($out, $text) = capture();
	print {$out} 'one';
	print {$out} 'two';
	is ${$text}, 'onetwo', 'what was written is in the string';

	my $in = typed('first', "second\n", '');
	is scalar readline($in), "first\n", 'a line gains its newline';
	is scalar readline($in), "second\n", 'a line that has one keeps one';
	is scalar readline($in), "\n", 'an empty line is a line';
	is scalar readline($in), undef, 'then the end';
};

subtest 'a keyboard and a screen' => sub {
	plan tests => 12;
	my ($keys, $screen, $text) = kit(keys => "\e[B\rq", typed => ['yes']);
	isa_ok $keys, 'Game::Terminal::Kit::Keys';
	isa_ok $screen, 'Game::Terminal::Kit::Screen';
	ok $keys->keys_available, 'there are keys';
	is_deeply [map { $keys->read_key } 1 .. 4], ['down', 'enter', 'q', undef], 'the ones typed';
	is $keys->read_line, 'yes', 'and the line';
	is $screen->interactive, 0, 'the screen is not a terminal';
	is $screen->colour, 0, 'has no colour';
	is $screen->ascii, 1, 'and is ASCII';
	$screen->show(['a board']);
	is ${$text}, "a board\n", 'what it shows is in the string';

	($keys, $screen) = kit(colour => 1, columns => 40);
	ok !$keys->keys_available, 'with no keys there is no keyboard';
	is $screen->colour, 1, 'an argument is the screen\'s';
	is_deeply [$screen->size], [40, 24], 'whichever it is';
};

subtest 'a limit on how long' => sub {
	plan tests => 6;
	is within(5, sub { 'done' }), 'done', 'a body that ends returns its value';
	is_deeply [within(5, sub { (1, 2) })], [1, 2], 'or its list';
	ok !eval { within(5, sub { die "its own\n" }); 1 }, 'a body that dies still dies';
	is $@, "its own\n", 'with its own error';

	SKIP: {
		skip 'no alarm here', 2 if $^O eq 'MSWin32';
		my $builder = Test::Builder->new;
		my $inner = Test::Builder->create;
		my $said = '';
		open my $sink, '>', \$said or die $!;
		$inner->output($sink);
		$inner->failure_output($sink);
		$inner->todo_output($sink);
		my @result;
		{
			no warnings 'redefine';
			local *Test::Builder::new = sub { $inner };
			@result = within(1, sub { sleep 10; 'never' });
		}
		is_deeply \@result, [], 'a body that hangs returns nothing';
		like $said, qr/^not ok 1 - ended within 1 seconds$/m, 'and is one failed test';
	}
};

done_testing;
