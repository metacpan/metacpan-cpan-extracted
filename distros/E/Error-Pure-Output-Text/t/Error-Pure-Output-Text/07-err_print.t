# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Output::Text qw(err_print);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my @errors = (
	{
		'msg' => ['Error.'],
		'stack' => [
			{
				'args' => '(\'Error.\')',
				'class' => 'main',
				'line' => '12',
				'prog' => './example.pl',
				'sub' => 'err',
			},
		],
	},
);
my $ret = err_print(@errors);
is($ret, 'Error.', 'Print in simple error.');

# Test.
@errors = (
	{
		'msg' => ['Error.'],
		'stack' => [
			{
				'args' => '(\'Error.\')',
				'class' => 'main',
				'line' => '12',
				'prog' => './example.pl',
				'sub' => 'err',
			},
			{
				'args' => '',
				'class' => 'main',
				'line' => '10',
				'prog' => './example.pl',
				'sub' => 'eval {...}',
			},
		],
	},
);
$ret = err_print(@errors);
is($ret, 'Error.', 'Print in complicated error.');

# Test.
@errors = (
	{
		'msg' => ['Error 1.'],
		'stack' => [
			{
				'args' => '(\'Error 1.\')',
				'class' => 'main',
				'line' => '12',
				'prog' => './example.pl',
				'sub' => 'err',
			},
			{
				'args' => '',
				'class' => 'main',
				'line' => '10',
				'prog' => './example.pl',
				'sub' => 'eval {...}',
			},
		],
	},
	{
		'msg' => ['Error 2.'],
		'stack' => [
			{
				'args' => '(\'Error 2.\')',
				'class' => 'main',
				'line' => '12',
				'prog' => './example.pl',
				'sub' => 'err',
			},
			{
				'args' => '',
				'class' => 'main',
				'line' => '10',
				'prog' => './example.pl',
				'sub' => 'eval {...}',
			},
		],
	},
);
$ret = err_print(@errors);
is($ret, 'Error 2.', 'Print in more errors.');

# Test.
@errors = (
	{
		'msg' => [
			'Error.',
			'first', 0,
			'second', -1,
			'third', 1,
			'fourth', undef,
		],
		'stack' => [
			{
				'args' => '(\'Error.\')',
				'class' => 'main',
				'line' => '12',
				'prog' => './example.pl',
				'sub' => 'err',
			},
		],
	},
);
$ret = err_print(@errors);
is($ret, 'Error.', 'Print in different key=value pairs.');

# Test.
@errors = (
	{
		'msg' => ['Error.', undef],
		'stack' => [
			{
				'args' => '(\'Error.\')',
				'class' => 'main',
				'line' => '12',
				'prog' => './example.pl',
				'sub' => 'err',
			},
		],
	},
);
$ret = err_print(@errors);
is($ret, 'Error.', 'Print in simple error with undef value.');

# Test.
@errors = (
	{
		'msg' => ['Error.'],
		'stack' => [
			{
				'args' => '(\'Error.\')',
				'class' => 'Class',
				'line' => '12',
				'prog' => './example.pl',
				'sub' => 'err',
			},
		],
	},
);
$ret = err_print(@errors);
is($ret, 'Class: Error.', 'Print in simple error with class name');
