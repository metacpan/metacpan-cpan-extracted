#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use File::Tudo qw(tudo);

use File::Spec;

use Test::More;

my $SAMPLE = File::Spec->catfile(qw(t data sample.todo));
my $TEMP = 'tudo-test';

plan tests => 15;

sub slurp {

	my $file = shift;

	local $/ = undef;

	open my $fh, '<', $file
		or die "Failed to open $file for reading: $!";

	my $slurp = readline $fh;

	close $fh;

	return $slurp;

}

my $obj;

$obj = File::Tudo->new($TEMP, { read => 0 });
isa_ok($obj, 'File::Tudo');
is($obj->path, $TEMP, 'path() is correct');
is_deeply($obj->todo, [], 'Default todo list is empty');

ok($obj->read($SAMPLE), 'read() was successful');

is(+@{$obj->todo}, 6, 'Correct number of TODOs read');

is(
	$obj->todo->[0],
	"Health is merely the slowest possible rate at which one can die.",
	'Single-line TODOs are read correctly'
);

is(
	$obj->todo->[1],
	"",
	'Empty TODOs are read correctly'
);

is_deeply(
	[ @{$obj->todo}[2..$#{$obj->todo}] ],
	[
		join("\n",
			"Always borrow money from a pessimist; he doesn't expect to be paid",
			"back."
		),
		join("\n",
			"Democracy is a device that insures we shall be governed no better than",
			"we deserve.",
			" -- George Bernard Shaw"
		),
		join("\n",
			"Main's Law:",
			"    For every action there is an equal and opposite government program.",
		),
		join("\n",
			"A budget is just a method of worrying before you spend money, as well",
			"as afterward."
		),
	],
	'Multiline TODOs are read correctly'
);

$obj->todo([
	"TODO 1",
	"TODO\n2",
	"TODO 3"
]);

is_deeply(
	$obj->todo,
	[
		"TODO 1",
		"TODO\n2",
		"TODO 3"
	],
	'File::Todo todo array is mutable'
);

ok($obj->write, 'write() was successful');

is(
	slurp($obj->path),
	<<'HERE',
TODO 1
--
TODO
2
--
TODO 3
--
HERE
	'write() writes TODO files correctly'
);

ok(tudo('TODO 4', $TEMP), 'tudo() was successful');

is(
	slurp($TEMP),
	<<'HERE',
TODO 1
--
TODO
2
--
TODO 3
--
TODO 4
--
HERE
	'tudo() appends TODOs correctly'
);

unlink $TEMP;

ok(tudo('TODO 4', $TEMP), 'tudo() with non-existant file was successful');

is(
	slurp($TEMP),
	<<'HERE',
TODO 4
--
HERE
	'tudo() creates new TODO files correctly'
);

END { unlink $TEMP if -e $TEMP }
