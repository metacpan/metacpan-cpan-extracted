use strict;
use warnings;

use Error::Pure::Output::Bio qw(err_bio);
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
my $right_ret = <<"END";
------------- EXCEPTION -------------
MSG: Error.
STACK: main ./example.pl:12
-------------------------------------
END
my $ret = err_bio(@errors);
is($ret, $right_ret, 'Backtrace print in simple error (scalar mode).');

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
		],
	},
);
my @right_ret = (
	'------------- EXCEPTION -------------',
	'MSG: Error.',
	'STACK: main ./example.pl:12',
	'-------------------------------------',
);
my @ret = err_bio(@errors);
is_deeply(
	\@ret,
	\@right_ret,
	'Backtrace print in simple error (array mode).',
);

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
$right_ret = <<"END";
------------- EXCEPTION -------------
MSG: Error.
STACK: main ./example.pl:12
STACK: main ./example.pl:10
-------------------------------------
END
$ret = err_bio(@errors);
is($ret, $right_ret, 'Backtrace print in complicated error.');

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
$right_ret = <<"END";
------------- EXCEPTION -------------
MSG: Error 1.
STACK: main ./example.pl:12
STACK: main ./example.pl:10
-------------------------------------
------------- EXCEPTION -------------
MSG: Error 2.
STACK: main ./example.pl:12
STACK: main ./example.pl:10
-------------------------------------
END
$ret = err_bio(@errors);
is($ret, $right_ret, 'Backtrace print in more errors.');

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
$right_ret = <<"END";
------------- EXCEPTION -------------
MSG: Error.
VALUE: first
VALUE: second: -1
VALUE: third: 1
VALUE: fourth
STACK: main ./example.pl:12
-------------------------------------
END
$ret = err_bio(@errors);
is($ret, $right_ret, 'Backtrace print in different key=value pairs.');

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
$right_ret = <<"END";
------------- EXCEPTION -------------
MSG: Error.
STACK: main ./example.pl:12
-------------------------------------
END
$ret = err_bio(@errors);
is($ret, $right_ret, 'Backtrace print in simple error with undef value.');
