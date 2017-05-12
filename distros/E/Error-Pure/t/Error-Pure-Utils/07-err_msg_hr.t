# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Utils qw(clean err_helper err_msg_hr);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
err_helper('Error', 'key1', 'val1', 'key2', 'val2');
my $ret_hr = err_msg_hr();
is_deeply(
	$ret_hr,
	{
		'key1' => 'val1',
		'key2' => 'val2',
	},
	'Simple test.',
);
clean();

# Test.
err_helper('Error', 'key1', 'val1', 'key2', 'val2');
err_helper('Error', 'key3', 'val3', 'key4', 'val4');
$ret_hr = err_msg_hr();
is_deeply(
	$ret_hr,
	{
		'key3' => 'val3',
		'key4' => 'val4',
	},
	'Get structure of last error message.',
);
clean();

# Test.
err_helper('Error', 'key1', 'val1', 'key2', 'val2');
err_helper('Error', 'key3', 'val3', 'key4', 'val4');
$ret_hr = err_msg_hr(0);
is_deeply(
	$ret_hr,
	{
		'key1' => 'val1',
		'key2' => 'val2',
	},
	'Get structure of first error message.',
);
clean();
