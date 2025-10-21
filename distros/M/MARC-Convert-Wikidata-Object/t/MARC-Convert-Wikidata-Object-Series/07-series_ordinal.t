use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
);
my $ret = $obj->series_ordinal;
is($ret, undef, 'Get default series ordinal of series (undef - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
	'series_ordinal' => '2',
);
$ret = $obj->series_ordinal;
is($ret, '2', 'Get explicit series ordinal of series (2).');

# Test.
$obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
	'series_ordinal' => 'II',
);
$ret = $obj->series_ordinal;
is($ret, 'II', 'Get explicit series ordinal of series (II).');

# Test.
## cnb000641953
$obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
	'series_ordinal' => '1057-58',
);
$ret = $obj->series_ordinal;
is($ret, '1057-58', 'Get explicit series ordinal of series (1057-58).');
