# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Utils qw(clean err_helper);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my @ret = err_helper('FOO', 'BAR');
is_deeply(
	\@ret,
	[
		{
			'msg' => [
				'FOO',
				'BAR',
			],
			'stack' => [],
		}
	],
	'Simple test.',
);

# Test.
clean();
@ret = err_helper(undef);
is_deeply(
	\@ret,
	[
		{
			'msg' => [
				'undef',
			],
			'stack' => [],
		}
	],
	'Test with undefined value.',
);
