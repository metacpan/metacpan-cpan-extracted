use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::CurrencyISO;

subtest 'code constants return their own code' => sub {
	is(USD, 'USD', 'USD returns "USD"');
	is(EUR, 'EUR', 'EUR returns "EUR"');
	is(GBP, 'GBP', 'GBP returns "GBP"');
	is(JPY, 'JPY', 'JPY returns "JPY"');
	is(CHF, 'CHF', 'CHF returns "CHF"');
	is(CAD, 'CAD', 'CAD returns "CAD"');
	is(AUD, 'AUD', 'AUD returns "AUD"');
	is(CNY, 'CNY', 'CNY returns "CNY"');
	is(INR, 'INR', 'INR returns "INR"');
	is(BRL, 'BRL', 'BRL returns "BRL"');
};

subtest 'meta accessor' => sub {
	my $meta = Code();
	is($meta->count, 176, '176 currency codes');
	ok($meta->valid('USD'), 'USD is valid');
	ok($meta->valid('EUR'), 'EUR is valid');
	ok(!$meta->valid('ZZZ'), 'ZZZ is not valid');
	is($meta->name('USD'), 'USD', 'name of USD is USD');
	is($meta->value('GBP'), 'GBP', 'value of GBP is GBP');
};

subtest 'DB round-trip safety' => sub {
	my $db_value = USD;
	is($db_value, 'USD', 'stored value is the ISO code itself');
	ok(Code()->valid($db_value), 'DB value validates back');
};

done_testing;
