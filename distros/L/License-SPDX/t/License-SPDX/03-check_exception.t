use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use License::SPDX;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my $ret = $obj->check_exception('LLVM-exception');
is($ret, 1, 'Check license exception (LLVM-exception = 1).');

# Test.
$obj = License::SPDX->new;
$ret = $obj->check_exception('BAD');
is($ret, 0, 'Check license exception (BAD = 0).');

# Test.
$obj = License::SPDX->new;
my $opts_hr = {
	'check_type' => 'id',
};
$ret = $obj->check_exception('LLVM-exception', $opts_hr);
is($ret, 1, 'Check license exception with explicit type id (LLVM-exception = 1).');

# Test.
$obj = License::SPDX->new;
$ret = $obj->check_exception('BAD', $opts_hr);
is($ret, 0, 'Check license exception with explicit type id (BAD = 0).');

# Test.
$obj = License::SPDX->new;
$opts_hr = {
	'check_type' => 'name',
};
$ret = $obj->check_exception('LLVM Exception', $opts_hr);
is($ret, 1, 'Check license exception with explicit type name (LLVM Exception = 1).');

# Test.
$obj = License::SPDX->new;
$opts_hr = {
	'check_type' => 'name',
};
$ret = $obj->check_exception('BAD', $opts_hr);
is($ret, 0, 'Check license exception with explicit type name (BAD = 0).');

# Test.
$obj = License::SPDX->new;
$opts_hr = {
	'check_type' => 'BAD',
};
eval {
	$obj->check_exception('FOO', $opts_hr);
};
is($EVAL_ERROR, "Check type 'BAD' doesn't supported.\n",
	"Check type 'BAD' doesn't supported.");
clean();
