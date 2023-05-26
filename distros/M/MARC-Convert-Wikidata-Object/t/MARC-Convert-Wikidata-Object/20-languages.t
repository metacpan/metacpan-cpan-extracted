use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply($obj->languages, [], 'Get default languages.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'languages' => ['cze'],
);
is_deeply($obj->languages, ['cze'], 'Get explicit languages (1).');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'languages' => ['cze', 'eng'],
);
is_deeply($obj->languages, ['cze', 'eng'], 'Get explicit languages (2).');
