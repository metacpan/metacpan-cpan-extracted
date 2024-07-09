use strict;
use warnings;

use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::People->new;
my $ret = $obj->full_name;
is($ret, undef, 'Get full name (undef - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::People->new(
	name => 'Petr',
	surname => 'Halouzka',
);
$ret = $obj->full_name;
is($ret, 'Petr Halouzka', 'Get full name (Petr Halouzka).');

# Test.
$obj = MARC::Convert::Wikidata::Object::People->new(
	name => 'Petr',
);
$ret = $obj->full_name;
is($ret, 'Petr', 'Get full name (Petr - only name).');

# Test.
$obj = MARC::Convert::Wikidata::Object::People->new(
	surname => 'Halouzka',
);
$ret = $obj->full_name;
is($ret, 'Halouzka', 'Get full name (Halouzka - only surname).');
