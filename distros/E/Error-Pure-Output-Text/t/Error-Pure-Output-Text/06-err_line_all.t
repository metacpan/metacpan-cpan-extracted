# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Output::Text qw(err_line_all);
use Test::More 'tests' => 4;
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
my $ret = err_line_all(@errors);
is($ret, "#Error [example.pl:12] Error.\n", 'Line error in simple error.');

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
$ret = err_line_all(@errors);
is($ret, "#Error [example.pl:12] Error.\n", 'Line error in complicated '.
	'error.');

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
my $right_ret = <<'END';
#Error [example.pl:12] Error 1.
#Error [example.pl:12] Error 2.
END
$ret = err_line_all(@errors);
is($ret, $right_ret, 'Two line errors.');
