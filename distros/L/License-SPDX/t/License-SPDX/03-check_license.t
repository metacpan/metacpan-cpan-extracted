use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 5;
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
