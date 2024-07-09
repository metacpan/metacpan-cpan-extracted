use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->cover, undef, 'Get default book cover.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'cover' => 'hardback',
);
is($obj->cover, 'hardback', 'Get book cover.');
