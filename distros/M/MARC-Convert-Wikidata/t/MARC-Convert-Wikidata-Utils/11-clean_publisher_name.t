use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_publisher_name);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_publisher_name = decode_utf8('Archiv města Brna :');
my $ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Archiv města Brna'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('Muzejní a vlastivědná společnost,');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Muzejní a vlastivědná společnost'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('[ Družstevní pivovar a zemědělské podniky]');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Družstevní pivovar a zemědělské podniky'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('[Dědictví Sv. Cyrilla a Methoděje');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Dědictví Sv. Cyrilla a Methoděje'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('(Ústřední kulturní oddělení) Ú[střední] R[ada] O[dborů]');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('(Ústřední kulturní oddělení) Ú[střední] R[ada] O[dborů]'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('[?] Fleischer');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('[?] Fleischer'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('(Západočeská univerzita ;');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Západočeská univerzita'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));

# Test.
$input_publisher_name = decode_utf8('Galerie Benedikta Rejta]');
$ret = clean_publisher_name($input_publisher_name);
is($ret, decode_utf8('Galerie Benedikta Rejta'),
	encode_utf8("Publisher name '$input_publisher_name' after cleanup."));
