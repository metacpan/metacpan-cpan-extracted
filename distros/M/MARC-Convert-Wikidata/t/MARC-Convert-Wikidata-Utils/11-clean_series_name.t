use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_series_name);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_series_name = decode_utf8('Lidové umění slovesné. Řada A ;');
my $ret = clean_series_name($input_series_name);
is($ret, decode_utf8('Lidové umění slovesné. Řada A'),
	encode_utf8("Series name '$input_series_name' after cleanup."));

# Test.
$input_series_name = decode_utf8('[Hospodářská knihovna] :');
$ret = clean_series_name($input_series_name);
is($ret, decode_utf8('Hospodářská knihovna'),
	encode_utf8("Series name '$input_series_name' after cleanup."));
