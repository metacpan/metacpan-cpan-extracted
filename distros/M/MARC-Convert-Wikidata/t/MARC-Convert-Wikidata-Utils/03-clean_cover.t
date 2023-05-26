use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_cover);
use Test::More 'tests' => 11;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_cover = decode_utf8('(Brož.) :');
my $ret = clean_cover($input_cover);
is($ret, 'paperback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('(brož.) :');
$ret = clean_cover($input_cover);
is($ret, 'paperback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('brož.)');
$ret = clean_cover($input_cover);
is($ret, 'paperback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('brožováno) :');
$ret = clean_cover($input_cover);
is($ret, 'paperback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('(Váz.) :');
$ret = clean_cover($input_cover);
is($ret, 'hardback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('(váz.) :');
$ret = clean_cover($input_cover);
is($ret, 'hardback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('váz.)');
$ret = clean_cover($input_cover);
is($ret, 'hardback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('(Vázáno) :');
$ret = clean_cover($input_cover);
is($ret, 'hardback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('vázáno) :');
$ret = clean_cover($input_cover);
is($ret, 'hardback', encode_utf8("Date '$input_cover' after cleanup."));

# Test.
$input_cover = decode_utf8('(vázáno)');
$ret = clean_cover($input_cover);
is($ret, 'hardback', encode_utf8("Date '$input_cover' after cleanup."));
