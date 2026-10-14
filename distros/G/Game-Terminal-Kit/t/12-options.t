#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Options;

my %field = (
	level => { name => 'level', type => 'int', min => 1, max => 5, help => 'the strength of the bot' },
	side => { name => 'side', type => 'enum', choices => [qw(black white random)], help => 'your side' },
	hotseat => { name => 'hotseat', type => 'flag', help => 'two people' },
	flying => { name => 'flying', type => 'bool', help => 'three men may fly' },
	seed => { name => 'seed', type => 'str', help => 'the same game again' },
);
my @fields = @field{qw/level side hotseat flying seed/};

sub step { return Game::Terminal::Kit::Options::step_value(@_) }
sub check { return [ Game::Terminal::Kit::Options::check_value(@_) ] }
sub argv { return [ Game::Terminal::Kit::Options::argv_for(@_) ] }
sub wrong { return [ Game::Terminal::Kit::Options::validate(@_) ] }

subtest 'stepping a value' => sub {
	plan tests => 22;
	is step($field{level}, undef, +1), 1, 'a number left alone steps up to the least';
	is step($field{level}, undef, -1), 5, 'and down to the greatest';
	is step($field{level}, 3, +1), 4, 'up';
	is step($field{level}, 3, -1), 2, 'down';
	is step($field{level}, 5, +1), 5, 'stops at the top';
	is step($field{level}, 1, -1), 1, 'stops at the bottom';

	is step($field{side}, undef, +1), 'black', 'a choice left alone steps up to the first';
	is step($field{side}, undef, -1), 'random', 'and down to the last';
	is step($field{side}, 'black', +1), 'white', 'next';
	is step($field{side}, 'random', +1), 'black', 'round from the last';
	is step($field{side}, 'black', -1), 'random', 'round from the first';
	is step($field{side}, 'purple', +1), 'white', 'a value that is no choice counts as the first';

	is step($field{hotseat}, undef, +1), 1, 'a flag turns on';
	is step($field{hotseat}, 1, +1), undef, 'and off';
	is step($field{hotseat}, 1, -1), undef, 'either way';

	is step($field{flying}, undef, +1), 1, 'a bool left alone goes on';
	is step($field{flying}, 1, +1), 0, 'then off';
	is step($field{flying}, 0, +1), undef, 'then is left alone';
	is step($field{flying}, undef, -1), 0, 'and backwards goes off first';
	is step($field{flying}, 0, -1), 1, 'then on';

	is step($field{seed}, 'tuesday', +1), 'tuesday', 'text does not step';
	is step($field{seed}, undef, -1), undef, 'nor does no text';
};

subtest 'checking typed text' => sub {
	plan tests => 14;
	is_deeply check($field{level}, ''), [undef, undef], 'blank is left alone';
	is_deeply check($field{level}, undef), [undef, undef], 'so is nothing';
	is_deeply check($field{level}, '   '), [undef, undef], 'and space';
	is_deeply check($field{level}, ' 3 '), [3, undef], 'a number with space round it';
	is_deeply check($field{level}, '1'), [1, undef], 'the least';
	is_deeply check($field{level}, '5'), [5, undef], 'the greatest';
	is_deeply check($field{level}, '0'), [undef, 'level takes a whole number from 1 to 5'], 'one below';
	is_deeply check($field{level}, '6'), [undef, 'level takes a whole number from 1 to 5'], 'one above';
	is_deeply check($field{level}, '2.5'), [undef, 'level takes a whole number from 1 to 5'], 'not whole';
	is_deeply check($field{level}, 'three'), [undef, 'level takes a whole number from 1 to 5'], 'not a number';
	is_deeply check($field{side}, 'WHITE'), ['white', undef], 'a choice in any case, returned in its own';
	is_deeply check($field{side}, 'purple'), [undef, 'side takes black, white, random'], 'not a choice';
	is_deeply check($field{seed}, ' any thing '), ['any thing', undef], 'text is trimmed and kept';
	is_deeply check($field{hotseat}, 'x'), ['x', undef], 'a flag takes what it is given';
};

subtest 'the command line for some values' => sub {
	plan tests => 9;
	is_deeply argv(\@fields, {}), [], 'nothing set sends nothing';
	is_deeply argv(\@fields), [], 'nor do no values at all';
	is_deeply argv(undef, { level => 3 }), [], 'nor do no fields';
	is_deeply argv(\@fields, { seed => 'tuesday', level => 3 }), ['--level', 3, '--seed', 'tuesday'],
		'in the order of the fields, not of the values';
	is_deeply argv(\@fields, { hotseat => 1 }), ['--hotseat'], 'a flag on';
	is_deeply argv(\@fields, { hotseat => 0 }), [], 'a flag off sends nothing';
	is_deeply argv(\@fields, { flying => 1 }), ['--flying'], 'a bool on';
	is_deeply argv(\@fields, { flying => 0 }), ['--no-flying'], 'a bool off is sent';
	is_deeply argv(\@fields, { level => 0, extra => q{--fen "a b" -x}, unknown => 1 }),
		['--level', 0, '--fen', 'a b', '-x'],
		'a zero is sent, extra is split like a shell and last, a value with no field is dropped';
};

subtest 'a sound table has nothing wrong' => sub {
	plan tests => 3;
	is_deeply wrong(\@fields), [], 'the five kinds together';
	is_deeply wrong([]), [], 'no options at all';
	is_deeply wrong([{ name => 'bot-vs-bot', type => 'flag', help => 'watch' },
		{ name => 'colour', type => 'enum', choices => [qw(b w)], help => 'your stones' },
		{ name => 'level', type => 'int', min => 0, max => 0, help => 'one rung' }]), [],
		'a dash in a name, a field called colour, a range of one';
};

subtest 'each thing that can be wrong' => sub {
	my @cases = (
		[{}, 'the options are not an array reference'],
		[['level'], 'option 0 is not a hash reference'],
		[[{ type => 'flag', help => 'x' }], 'option 0 has no name a command line could carry'],
		[[{ name => '--level', type => 'flag', help => 'x' }], 'option 0 has no name a command line could carry'],
		[[{ name => 'Level', type => 'flag', help => 'x' }], 'option 0 has no name a command line could carry'],
		[[$field{seed}, $field{seed}], 'seed is there twice'],
		[[{ name => 'ascii', type => 'flag', help => 'x' }], 'ascii is a name the launcher keeps'],
		[[{ name => 'extra', type => 'str', help => 'x' }], 'extra is a name the launcher keeps'],
		[[{ name => 'seed', type => 'str' }], 'seed has no help'],
		[[{ name => 'seed', type => 'str', help => '' }], 'seed has no help'],
		[[{ name => 'seed', help => 'x' }], 'seed has no known type'],
		[[{ name => 'seed', type => 'text', help => 'x' }], 'seed has no known type'],
		[[{ name => 'level', type => 'int', min => 1, help => 'x' }], 'level needs a whole min and max, min first'],
		[[{ name => 'level', type => 'int', min => 5, max => 1, help => 'x' }], 'level needs a whole min and max, min first'],
		[[{ name => 'level', type => 'int', min => 1, max => 2.5, help => 'x' }], 'level needs a whole min and max, min first'],
		[[{ name => 'side', type => 'enum', help => 'x' }], 'side needs two or more choices'],
		[[{ name => 'side', type => 'enum', choices => ['only'], help => 'x' }], 'side needs two or more choices'],
		[[{ name => 'side', type => 'enum', choices => ['a', ''], help => 'x' }], 'side needs two or more choices'],
	);
	plan tests => @cases + 2;
	is_deeply wrong($_->[0]), [ $_->[1] ], $_->[1] for @cases;
	is_deeply wrong([{ name => 'help', type => 'colour' }]),
		['help is a name the launcher keeps', 'help has no help', 'help has no known type'],
		'everything wrong with one field is said, in order';
	is_deeply wrong(['x', $field{seed}, { name => 'seed', type => 'str', help => 'x' }]),
		['option 0 is not a hash reference', 'seed is there twice'],
		'and a bad field does not hide the next';
};

subtest 'the lists' => sub {
	plan tests => 2;
	is_deeply [Game::Terminal::Kit::Options::types()], [qw/bool enum flag int str/], 'the types';
	is_deeply [Game::Terminal::Kit::Options::reserved()], [qw/ascii extra help pick version/], 'the kept names';
};

done_testing;
