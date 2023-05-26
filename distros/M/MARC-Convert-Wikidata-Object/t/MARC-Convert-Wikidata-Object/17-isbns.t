use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply($obj->isbns, [], 'Get default ISBNs.');

# Test.
my $isbn = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '80-85812-08-8',
);
$obj = MARC::Convert::Wikidata::Object->new(
	'isbns' => [$isbn],
);
is($obj->isbns->[0]->isbn, '80-85812-08-8', 'Get explicit ISBN 10.');

# Test.
$isbn = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '978-80-00-05046-1',
);
$obj = MARC::Convert::Wikidata::Object->new(
	'isbns' => [$isbn],
);
is($obj->isbns->[0]->isbn, '978-80-00-05046-1', 'Get explicit ISBN 10.');
