use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Currency;

subtest 'major currency constants' => sub {
	is(USD, 'United States Dollar',    'USD => United States Dollar');
	is(EUR, 'Euro',                    'EUR => Euro');
	is(GBP, 'Pound Sterling',         'GBP => Pound Sterling');
	is(JPY, 'Japanese Yen',           'JPY => Japanese Yen');
	is(CHF, 'Swiss Franc',            'CHF => Swiss Franc');
	is(AUD, 'Australian Dollar',      'AUD => Australian Dollar');
	is(CAD, 'Canadian Dollar',        'CAD => Canadian Dollar');
	is(CNY, 'Chinese Yuan Renminbi',  'CNY => Chinese Yuan Renminbi');
	is(INR, 'Indian Rupee',           'INR => Indian Rupee');
	is(BRL, 'Brazilian Real',         'BRL => Brazilian Real');
};

subtest 'regional currencies' => sub {
	is(ZAR, 'South African Rand',           'ZAR => South African Rand');
	is(MXN, 'Mexican Peso',                 'MXN => Mexican Peso');
	is(KRW, 'South Korean Won',             'KRW => South Korean Won');
	is(SGD, 'Singapore Dollar',             'SGD => Singapore Dollar');
	is(THB, 'Thai Baht',                    'THB => Thai Baht');
	is(TRY, 'Turkish Lira',                 'TRY => Turkish Lira');
	is(PLN, 'Polish Zloty',                 'PLN => Polish Zloty');
	is(SEK, 'Swedish Krona',                'SEK => Swedish Krona');
	is(NOK, 'Norwegian Krone',              'NOK => Norwegian Krone');
	is(NZD, 'New Zealand Dollar',           'NZD => New Zealand Dollar');
};

subtest 'supranational and special codes' => sub {
	is(XAF, 'Central African CFA Franc',    'XAF => CFA Franc BEAC');
	is(XOF, 'West African CFA Franc',       'XOF => CFA Franc BCEAO');
	is(XCD, 'East Caribbean Dollar',        'XCD => East Caribbean Dollar');
	is(XPF, 'CFP Franc',                    'XPF => CFP Franc');
	is(XDR, 'Special Drawing Rights (IMF)', 'XDR => SDR');
	is(XCG, 'Caribbean Guilder',            'XCG => Caribbean Guilder');
};

subtest 'precious metals' => sub {
	is(XAU, 'Gold (Troy Ounce)',      'XAU => Gold');
	is(XAG, 'Silver (Troy Ounce)',    'XAG => Silver');
	is(XPT, 'Platinum (Troy Ounce)',  'XPT => Platinum');
	is(XPD, 'Palladium (Troy Ounce)', 'XPD => Palladium');
};

subtest 'meta accessor' => sub {
	my $meta = Code();
	ok($meta->valid('United States Dollar'),   'USD value is valid');
	ok($meta->valid('Euro'),                   'EUR value is valid');
	ok(!$meta->valid('Bitcoin'),               'Bitcoin is not valid');
	is($meta->name('United States Dollar'), 'USD', 'name of USD');
	is($meta->name('Euro'),                 'EUR', 'name of EUR');
	is($meta->value('JPY'), 'Japanese Yen',        'value of JPY');
	ok($meta->count > 160, 'more than 160 currency codes');
};

subtest 'special codes' => sub {
	is(XTS, 'Code Reserved for Testing',  'XTS => testing code');
	is(XXX, 'No Currency',                'XXX => no currency');
	is(ZWG, 'Zimbabwe Gold',              'ZWG => Zimbabwe Gold');
};

done_testing;
