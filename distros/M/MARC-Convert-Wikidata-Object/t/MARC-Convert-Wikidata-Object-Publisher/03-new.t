use strict;
use warnings;

use Error::Pure::Utils qw(clean);
use English;
use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'name' => 'Academia',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::Publisher');

# Test.
$obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'id' => '000010003',
	'name' => 'Academia',
	'place' => 'Praha',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::Publisher');

# Test.
eval {
	MARC::Convert::Wikidata::Object::Publisher->new;
};
is($EVAL_ERROR, "Parameter 'name' is required.\n",
	"Parameter 'name' is required.");
clean();
