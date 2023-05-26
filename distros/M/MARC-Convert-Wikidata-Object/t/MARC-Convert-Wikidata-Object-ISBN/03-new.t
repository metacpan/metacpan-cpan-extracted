use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Convert::Wikidata::Object::ISBN;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '978-1-61189-009-9',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::ISBN');

# Test.
$obj = MARC::Convert::Wikidata::Object::ISBN->new(
	'isbn' => '80-270-8205-6',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::ISBN');

# Test.
eval {
	MARC::Convert::Wikidata::Object::ISBN->new(
		'isbn' => 'foo',
	);
};
is($EVAL_ERROR, "ISBN 'foo' isn't valid.\n", "ISBN 'foo' isn't valid.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::ISBN->new;
};
is($EVAL_ERROR, "Parameter 'isbn' is required.\n", "Parameter 'isbn' is required.");
clean();

# Test.
eval {
	MARC::Convert::Wikidata::Object::ISBN->new(
		'cover' => 'bad',
		'isbn' => '80-270-8205-6',
	);
};
is($EVAL_ERROR, "ISBN cover 'bad' isn't valid.\n",
	"ISBN cover 'bad' isn't valid.");
clean();
