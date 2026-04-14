use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Country;

subtest 'alpha-2 code constants' => sub {
	is(US, 'United States',          'US => United States');
	is(GB, 'United Kingdom',         'GB => United Kingdom');
	is(DE, 'Germany',                'DE => Germany');
	is(FR, 'France',                 'FR => France');
	is(JP, 'Japan',                  'JP => Japan');
	is(CN, 'China',                  'CN => China');
	is(AU, 'Australia',              'AU => Australia');
	is(BR, 'Brazil',                 'BR => Brazil');
	is(IN, 'India',                  'IN => India');
	is(ZA, 'South Africa',           'ZA => South Africa');
	is(NZ, 'New Zealand',            'NZ => New Zealand');
	is(CA, 'Canada',                 'CA => Canada');
	is(MX, 'Mexico',                 'MX => Mexico');
	is(KR, 'South Korea',            'KR => South Korea');
	is(AF, 'Afghanistan',            'AF => Afghanistan');
	is(ZW, 'Zimbabwe',               'ZW => Zimbabwe');
};

subtest 'alpha-2 meta accessor' => sub {
	my $meta = Alpha2();
	ok($meta->valid('United States'),   'United States is valid');
	ok($meta->valid('Germany'),         'Germany is valid');
	ok(!$meta->valid('Narnia'),         'Narnia is not valid');
	is($meta->name('United States'), 'US', 'name of United States is US');
	is($meta->name('Japan'),         'JP', 'name of Japan is JP');
	is($meta->value('GB'),   'United Kingdom', 'value of GB is United Kingdom');
	is($meta->count, 249, '249 alpha-2 codes');
};

subtest 'alpha-3 code constants' => sub {
	is(USA, 'United States',          'USA => United States');
	is(GBR, 'United Kingdom',         'GBR => United Kingdom');
	is(DEU, 'Germany',                'DEU => Germany');
	is(FRA, 'France',                 'FRA => France');
	is(JPN, 'Japan',                  'JPN => Japan');
	is(CHN, 'China',                  'CHN => China');
	is(AUS, 'Australia',              'AUS => Australia');
	is(BRA, 'Brazil',                 'BRA => Brazil');
	is(IND, 'India',                  'IND => India');
	is(ZAF, 'South Africa',           'ZAF => South Africa');
	is(AFG, 'Afghanistan',            'AFG => Afghanistan');
	is(ZWE, 'Zimbabwe',               'ZWE => Zimbabwe');
};

subtest 'alpha-3 meta accessor' => sub {
	my $meta = Alpha3();
	ok($meta->valid('United States'),   'United States is valid');
	ok(!$meta->valid('Narnia'),         'Narnia is not valid');
	is($meta->name('United States'), 'USA', 'name of United States is USA');
	is($meta->value('GBR'), 'United Kingdom', 'value of GBR is United Kingdom');
	is($meta->count, 249, '249 alpha-3 codes');
};

subtest 'alpha-2 and alpha-3 agree' => sub {
	is(US, USA, 'US and USA both resolve to United States');
	is(GB, GBR, 'GB and GBR both resolve to United Kingdom');
	is(JP, JPN, 'JP and JPN both resolve to Japan');
	is(DE, DEU, 'DE and DEU both resolve to Germany');
	is(ZA, ZAF, 'ZA and ZAF both resolve to South Africa');
};

subtest 'edge cases' => sub {
	is(DO, 'Dominican Republic',                       'DO (keyword-like) works');
	is(MY, 'Malaysia',                                  'MY (keyword-like) works');
	is(NO, 'Norway',                                    'NO (keyword-like) works');
	is(IO, 'British Indian Ocean Territory',            'IO works');
	is(GS, 'South Georgia and the South Sandwich Islands', 'long name works');
};

done_testing;
