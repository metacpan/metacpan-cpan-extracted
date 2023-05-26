use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_date);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_date = '2020.';
my $ret = clean_date($input_date);
is($ret, 2020, "Date '$input_date' after cleanup.");

# Test.
$input_date = decode_utf8('2020 př. Kr.');
$ret = clean_date($input_date);
is($ret, -2020, encode_utf8("Date '$input_date' after cleanup."));

# Test.
$input_date = decode_utf8('2020 březen 03.');
$ret = clean_date($input_date);
is($ret, '2020-03-03', encode_utf8("Date '$input_date' after cleanup."));

# Test.
$input_date = decode_utf8('2020 leden 3.');
$ret = clean_date($input_date);
is($ret, '2020-01-3', encode_utf8("Date '$input_date' after cleanup."));

# Test.
$input_date = undef;
$ret = clean_date($input_date);
is($ret, undef, encode_utf8("Undefined date after cleanup."));
