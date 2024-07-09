use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->full_name, undef, 'Get default full name.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'title' => 'Foo',
);
is($obj->full_name, 'Foo', 'Get explicit full name (without subtitle).');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'title' => 'Foo',
	'subtitles' => ['Bar'],
);
is($obj->full_name, 'Foo: Bar', 'Get explicit full name (one subtitle).');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'title' => 'Foo',
	'subtitles' => ['Bar', 'Baz'],
);
is($obj->full_name, 'Foo: Bar: Baz', 'Get explicit full name (two subtitles).');
