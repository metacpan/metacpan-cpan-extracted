use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_series_ordinal);
use Test::More 'tests' => 19;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_series_ordinal = 'sv. 4';
my $ret = clean_series_ordinal($input_series_ordinal);
is($ret, '4', "Series ordinal '$input_series_ordinal' after cleanup.");

# Test.
$input_series_ordinal = 'Sv. 13';
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '13', "Series ordinal '$input_series_ordinal' after cleanup.");

# Test.
$input_series_ordinal = 'svazek 99';
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '99', "Series ordinal '$input_series_ordinal' after cleanup.");

# Test.
$input_series_ordinal = decode_utf8('č.10');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '10', encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('Č. 36');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '36', encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('č.1057-58');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '1057-1058', encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('č.957-58');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '957-958', encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('č.1007-8');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '1007-1008', encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('číslo 1');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 1, encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = '82. svazek';
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 82, "Series ordinal '$input_series_ordinal' after cleanup.");

# Test.
$input_series_ordinal = 'Sv. 2.';
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 2, "Series ordinal '$input_series_ordinal' after cleanup.");

# Test.
$input_series_ordinal = decode_utf8('sv. č. 40');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 40, encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('Výst. 80');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 80, encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('Výstava 48');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 48, encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test.
$input_series_ordinal = decode_utf8('kn. 43');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 43, encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test
$input_series_ordinal = decode_utf8('kniha 75.');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 75, encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test
$input_series_ordinal = decode_utf8('kn. 71, 72');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, '71-72', encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));

# Test
$input_series_ordinal = decode_utf8('díl. I');
$ret = clean_series_ordinal($input_series_ordinal);
is($ret, 'I', encode_utf8("Series ordinal '$input_series_ordinal' after cleanup."));
