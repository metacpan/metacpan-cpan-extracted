use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use License::SPDX;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my $ret = $obj->check_license('MIT');
is($ret, 1, 'Check license (MIT = 1).');

# Test.
$obj = License::SPDX->new;
$ret = $obj->check_license('BAD');
is($ret, 0, 'Check license (BAD = 0).');

# Test.
$obj = License::SPDX->new;
my $opts_hr = {
	'check_type' => 'id',
};
$ret = $obj->check_license('MIT', $opts_hr);
is($ret, 1, 'Check license with explicit type id (MIT = 1).');

# Test.
$obj = License::SPDX->new;
$ret = $obj->check_license('BAD', $opts_hr);
is($ret, 0, 'Check license with explicit type id (BAD = 0).');

# Test.
$obj = License::SPDX->new;
$opts_hr = {
	'check_type' => 'name',
};
$ret = $obj->check_license('MIT License', $opts_hr);
is($ret, 1, 'Check license with explicit type name (MIT License = 1).');

# Test.
$obj = License::SPDX->new;
$opts_hr = {
	'check_type' => 'name',
};
$ret = $obj->check_license('BAD', $opts_hr);
is($ret, 0, 'Check license with explicit type name (BAD = 0).');

# Test.
$obj = License::SPDX->new;
$opts_hr = {
	'check_type' => 'BAD',
};
eval {
	$obj->check_license('FOO', $opts_hr);
};
is($EVAL_ERROR, "Check type 'BAD' doesn't supported.\n",
	"Check type 'BAD' doesn't supported.");
clean();
