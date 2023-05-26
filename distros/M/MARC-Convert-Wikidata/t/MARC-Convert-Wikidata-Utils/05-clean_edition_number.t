use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_edition_number);
use Test::More 'tests' => 46;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_edition_number = '1. vyd.';
my $ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = decode_utf8('1. vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('První vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Druhé vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Vydání: první');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = 'II. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = '2. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

$input_edition_number = '[2. vyd.]';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = '2. opr. a rozmn. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = decode_utf8('2., rozš. a aktualiz. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = '2., upr. vyd.';
$ret = clean_edition_number($input_edition_number);
is($ret, 2, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = 'Vyd. 1.';
$ret = clean_edition_number($input_edition_number);
is($ret, 1, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = decode_utf8('Druhé, přepracované a doplněné vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = undef;
$ret = clean_edition_number($input_edition_number);
is($ret, undef, 'Undefined edition number after cleanup.');

# Test.
$input_edition_number = decode_utf8('Vydání 1.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Vydání druhé');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Vydání první');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Vydání dvacáté');
$ret = clean_edition_number($input_edition_number);
is($ret, 20, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Druhé, rozšířené vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('2., rozš. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('1. české vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Druhé vydání v českém jazyce');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('V českém jazyce vydání první');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('V češtině první vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('II. vydání s vyobrazeními');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Druhé, aktualizované vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('2., upr. a dopl. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('9., přeprac. a dopl. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 9, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('3., přeprac. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 3, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('České vyd. 1.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('1. čes. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Lidové vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, undef, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('4. vyd');
$ret = clean_edition_number($input_edition_number);
is($ret, 4, "Edition number '$input_edition_number' after cleanup.");

# Test.
$input_edition_number = decode_utf8('3., dopln. a přeprac. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 3, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('[1. souborné vyd.]');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('1. autoris. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('I. aut. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('1., autoriz. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('1., autorisované vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('3., nezm. vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 3, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Třetí revidované vydání');
$ret = clean_edition_number($input_edition_number);
is($ret, 3, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Vydání: 3.');
$ret = clean_edition_number($input_edition_number);
is($ret, 3, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('Vydanie prvé');
$ret = clean_edition_number($input_edition_number);
is($ret, 1, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('2., dopln. a upravené vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 2, encode_utf8("Edition number '$input_edition_number' after cleanup."));

# Test.
$input_edition_number = decode_utf8('3., rozš: vyd.');
$ret = clean_edition_number($input_edition_number);
is($ret, 3, encode_utf8("Edition number '$input_edition_number' after cleanup."));
