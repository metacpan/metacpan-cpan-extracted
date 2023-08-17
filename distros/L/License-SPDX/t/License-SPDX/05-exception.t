use strict;
use warnings;

use JSON::PP::Boolean;
use License::SPDX;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Booleans.
my $false = do { bless \(my $dummy = 0), "JSON::PP::Boolean" };

# Test.
my $obj = License::SPDX->new;
my $ret_hr = $obj->exception('LLVM-exception');
is_deeply(
	$ret_hr,
	{
		'reference' => './LLVM-exception.json',
		'isDeprecatedLicenseId' => $false,
		'detailsUrl' => './LLVM-exception.html',
		'referenceNumber' => 14,
		'name' => 'LLVM Exception',
		'licenseExceptionId' => 'LLVM-exception',
		'seeAlso' => [
			'http://llvm.org/foundation/relicensing/LICENSE.txt',
		],
	},
	'Look for LLVM license exception.',
);

# Test.
$obj = License::SPDX->new;
$ret_hr = $obj->exception('BAD');
is_deeply(
	$ret_hr,
	undef,
	'Look for BAD license exception.',
);
