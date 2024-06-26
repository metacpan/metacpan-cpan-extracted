use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'name' => 'Academia',
);
my $id = $obj->id;
is($id, undef, 'Get id (default - undef).');

# Test.
$obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'id' => '000010003',
	'name' => 'Academia',
);
$id = $obj->id;
is($id, '000010003', 'Get id (000010003).');
