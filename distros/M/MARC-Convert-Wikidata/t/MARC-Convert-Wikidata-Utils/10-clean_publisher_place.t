use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_publisher_place);
use Test::More 'tests' => 27;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Test.
my $input_publisher_place = 'V Praze : ';
my $ret = clean_publisher_place($input_publisher_place);
is($ret, 'Praha', "Publisher name '$input_publisher_place' after cleanup.");

# Test.
$input_publisher_place = decode_utf8('V Brně');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Brno', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = '[Praha]';
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Praha', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = '[Praha';
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Praha', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Ústí nad Labem');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Ústí nad Labem'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('Plzeň ;');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Plzeň'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Pardubicích :');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Pardubice'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('[V Pardubicích] :');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Pardubice'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = 'V Olomouci :';
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Olomouc', "Publisher name '$input_publisher_place' after cleanup.");

# Test.
$input_publisher_place = decode_utf8('V Ostravě :');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Ostrava', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('Karlových Varech');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Karlovy Vary', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = 'Nymburce';
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Nymburk', "Publisher name '$input_publisher_place' after cleanup.");

# Test.
$input_publisher_place = decode_utf8('V Jimramově');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Jimramov', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('Veletiny :');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Veletiny', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Jihlavě');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Jihlava', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Blansku');
$ret = clean_publisher_place($input_publisher_place);
is($ret, 'Blansko', encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Přerově');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Přerov'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('Č. Budějovice');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('České Budějovice'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Poděbradech');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Poděbrady'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Telči');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Telč'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Hradci Králové');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Hradec Králové'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Přelouči');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Přelouč'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('V Litoměřicích');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Litoměřice'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('S.l.');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('sine loco'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('Praha?');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Praha'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));

# Test.
$input_publisher_place = decode_utf8('Náchodě');
$ret = clean_publisher_place($input_publisher_place);
is($ret, decode_utf8('Náchod'), encode_utf8("Publisher name '$input_publisher_place' after cleanup."));
