use strict;
use Finance::Bank::SCSB::TW;
use Test::More;
use UNIVERSAL::isa;

unless ($ENV{TEST_SCSB_BANK}) {
    plan skip_all => 'Testing requires it to hit scsb.com.tw website. Set TEST_SCSB_BANK env variable for reallying running the test.';
}
else {
    plan tests => 8;
}

my $rate = Finance::Bank::SCSB::TW->currency_exchange_rate;

ok($rate->isa('ARRAY'));
ok($rate->isa("Finance::Bank::SCSB::TW::CurrencyExchangeRateCollection"));
is(ref($rate->[0]), 'HASH');

is($rate->[0]{en_currency_name}, 'USD CASH');

my $rates_for_usd = $rate->for_currency("usd");

is(0+ @$rates_for_usd, 3);
is($rates_for_usd->[0]{en_currency_name}, 'USD CASH');
is($rates_for_usd->[1]{en_currency_name}, 'USD');
is($rates_for_usd->[2]{en_currency_name}, 'USD');
