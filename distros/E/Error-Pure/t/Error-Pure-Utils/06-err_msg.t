# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Utils qw(clean err_helper err_msg);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
err_helper('FOO', 'BAR');
my @ret = err_msg();
is_deeply(
	\@ret,
	[
		'FOO',
		'BAR',
	],
	'Simple test.',
);
clean();

# Test.
err_helper('FOO', 'BAR');
err_helper('BAZ', 'BAF');
@ret = err_msg();
is_deeply(
	\@ret,
	[
		'BAZ',
		'BAF',
	],
	'Get messages of last error.',
);
clean();

# Test.
err_helper('FOO', 'BAR');
err_helper('BAZ', 'BAF');
@ret = err_msg(0);
is_deeply(
	\@ret,
	[
		'FOO',
		'BAR',
	],
	'Get messages of first error.',
);
clean();
