# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
eval {
	File::Object->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	File::Object->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	File::Object->new(
		'type' => 'XXX',
	);
};
is($EVAL_ERROR, "Bad 'type' parameter.\n", 'Bad \'type\' parameter.');
clean();

# Test.
eval {
	File::Object->new(
		'dir' => 'BAD_ARRAY',
	);
};
is($EVAL_ERROR, "'dir' parameter must be a reference to array.\n",
	'Bad \'dir\' parameter.');
clean();

# Test.
eval {
	File::Object->new(
		'type' => undef,
	);
};
is($EVAL_ERROR, "Bad 'type' parameter.\n", 'Bad undefined \'type\' parameter.');
clean();

# Test.
my $obj = File::Object->new;
isa_ok($obj, 'File::Object');

# Test.
$obj = File::Object->new(
	'dir' => ['foo', undef, 'bar'],
	'type' => 'dir',
);
is_deeply(
	$obj->{'dir'},
	[
		'foo',
		'bar',
	],
	'Test for removing undef directories.',
);
is_deeply(
	$obj->{'path'},
	[
		'foo',
		'bar',
	],
	'Test for path in situation with explicit dir.',
);

# Test.
$obj = File::Object->new(
	'type' => 'dir',
);
is_deeply(
	[
		$obj->{'path'}->[-2],
		$obj->{'path'}->[-1],
	],
	[
		't',
		'File-Object',
	],
	'Test for path in situation with implicit dir.',
);

# Test.
$obj = File::Object->new(
	'dir' => ['foo', 'bar'],
	'file' => 'baz',
	'type' => 'file',
);
is_deeply(
	$obj->{'path'},
	[
		'foo',
		'bar',
		'baz',
	],
	'Test for path in situation with explicit file.'
);

# Test.
$obj = File::Object->new(
	'type' => 'file',
);
is_deeply(
	[
		$obj->{'path'}->[-3],
		$obj->{'path'}->[-2],
		$obj->{'path'}->[-1],
	],
	[
		't',
		'File-Object',
		'03-new.t',
	],
	'Test for path in situation with implicit file.',
);
