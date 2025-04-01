use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is(scalar @{$obj->covers}, 0, 'Get book covers (no covers).');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'covers' => ['hardback'],
);
is($obj->covers->[0], 'hardback', 'Get book covers (hardback).');
