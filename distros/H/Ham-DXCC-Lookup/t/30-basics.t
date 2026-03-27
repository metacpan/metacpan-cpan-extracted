use strict;
use warnings;
use Test::Most;
use Test::Settings;

if(Test::Settings::want_smoke) {
	ok(1);
} else {
	use_ok('Ham::DXCC::Lookup', 'lookup_dxcc');
	cmp_ok(lookup_dxcc('K1ZZ')->{'dxcc_name'}, 'eq', 'United States', 'K1ZZ country');
	cmp_ok(lookup_dxcc('G4ABC')->{'dxcc_name'}, 'eq', 'England', 'G4ABC country');
	cmp_ok(lookup_dxcc('JA1XYZ')->{'dxcc_name'}, 'eq', 'Japan', 'JA1XYZ country');
}

done_testing();
