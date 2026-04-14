use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::CountryISO;

subtest 'alpha-2 code constants' => sub {
	is(US, 'US', 'US => "US"');
	is(GB, 'GB', 'GB => "GB"');
	is(DE, 'DE', 'DE => "DE"');
	is(FR, 'FR', 'FR => "FR"');
	is(JP, 'JP', 'JP => "JP"');
	is(CN, 'CN', 'CN => "CN"');
	is(AU, 'AU', 'AU => "AU"');
	is(BR, 'BR', 'BR => "BR"');
	is(IN, 'IN', 'IN => "IN"');
	is(ZA, 'ZA', 'ZA => "ZA"');
	is(ZW, 'ZW', 'ZW => "ZW"');
};

subtest 'alpha-2 meta' => sub {
	my $meta = Alpha2();
	ok($meta->valid('US'),   'US is valid');
	ok($meta->valid('GB'),   'GB is valid');
	ok(!$meta->valid('XX'),  'XX is not valid');
	is($meta->name('US'), 'US', 'name of US is US');
	is($meta->count, 249, '249 alpha-2 codes');
};

subtest 'alpha-3 code constants' => sub {
	is(USA, 'USA', 'USA => "USA"');
	is(GBR, 'GBR', 'GBR => "GBR"');
	is(DEU, 'DEU', 'DEU => "DEU"');
	is(FRA, 'FRA', 'FRA => "FRA"');
	is(JPN, 'JPN', 'JPN => "JPN"');
	is(CHN, 'CHN', 'CHN => "CHN"');
	is(AUS, 'AUS', 'AUS => "AUS"');
	is(BRA, 'BRA', 'BRA => "BRA"');
	is(IND, 'IND', 'IND => "IND"');
	is(ZAF, 'ZAF', 'ZAF => "ZAF"');
	is(ZWE, 'ZWE', 'ZWE => "ZWE"');
};

subtest 'alpha-3 meta' => sub {
	my $meta = Alpha3();
	ok($meta->valid('USA'),   'USA is valid');
	ok($meta->valid('GBR'),   'GBR is valid');
	ok(!$meta->valid('XXX'),  'XXX is not valid');
	is($meta->name('USA'), 'USA', 'name of USA is USA');
	is($meta->count, 249, '249 alpha-3 codes');
};

subtest 'DB round-trip safety' => sub {
	my $code = US;
	is($code, 'US', 'constant eq string for DB storage');
	ok(Alpha2()->valid($code), 'DB value validates back');
};

done_testing;
