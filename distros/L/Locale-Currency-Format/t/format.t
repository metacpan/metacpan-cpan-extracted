#!/bin/perl

use Test::More tests => 28;

BEGIN {
	use_ok('Locale::Currency::Format');
}
is( currency_format( 'usd', 1000 ), '1,000.00 USD', "USD" );
is( currency_format( 'usd', 1000, FMT_NOZEROS ), '1,000 USD',          "Format USD No Zeros" );
is( currency_format( 'usd', 1000, FMT_HTML ),    '&#x0024;1,000.00',   "Format USD HTML" );
is( currency_format( 'usd', 1000, FMT_NAME ),    "1,000.00 US Dollar", "Format USD Name" );
is( currency_format( 'usd', 1000, FMT_SYMBOL ),  "\x{0024}1,000.00",   "Format USD Symbol" );
is( currency_format('usd'), undef, "Not Blank" );
is( currency_format(),      undef, "Not Blank" );
is( currency_format( 'us', 1000 ), undef, "Check US" );
is( currency_symbol( 'vnd', SYM_UTF ),  "\x{20AB}", "Check VND Symbol" );
is( currency_symbol( 'vnd', SYM_HTML ), "&#x20AB;", "Check VND HTML" );
is( currency_symbol(), undef, "Check symbol" );
is( currency_symbol( 'usd', 10 ), undef, "Check USD symbol" );
is( currency_symbol('vn'),  undef, "Check VN symbol" );
is( currency_symbol('aed'), undef, "Check SED symbol" );
is( currency_set( 'USD', '#.###,## $', FMT_COMMON ), 'USD', "Setting custom currency" );
is( currency_format( 'USD', 1000, FMT_COMMON ), '1.000,00 $', "Check custom" );
is( currency_set('USD'), 'USD', "Reset custom currency" );
is( currency_format( 'USD', 1000, FMT_COMMON ), '$1,000.00', "Check custom reset is" );
is( currency_set( 'GBP', "\x{00A3}#,###.##", FMT_COMMON ), 'GBP', "custom GBP" );
is( decimal_precision('usd'),   2,                "Check USD decimal precision" );
is( decimal_precision('bhd'),   3,                "Check BHD decimal precision" );
is( decimal_separator('usd'),   '.',              "Check USD decimal seperator" );
is( decimal_separator('eur'),   ',',              "Check EUR decimal seperator" );
is( thousands_separator('usd'), ',',              "Check USD thousands seperator" );
is( thousands_separator('eur'), '.',              "Check EUR thousands seperator" );
is( currency_name('usd'),       'US Dollar',      "Check USD currency name" );
is( currency_name('gbp'),       'Pound Sterling', "Check GBP currency name" );
