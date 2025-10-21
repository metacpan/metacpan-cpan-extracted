use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Series;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
);
my $ret = $obj->series_ordinal_raw;
is($ret, undef, 'Get default series ordinal of series in raw form (undef - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::Series->new(
	'name' => 'book series',
	'series_ordinal_raw' => 'kniha II.',
);
$ret = $obj->series_ordinal_raw;
is($ret, 'kniha II.', 'Get explicit series ordinal of series in raw form (kniha II.).');
