use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Convert::Wikidata::Object::Work;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Work->new(
        'title' => 'O ethice a alkoholismu',
);
isa_ok($obj, 'MARC::Convert::Wikidata::Object::Work');

# Test.
eval {
	MARC::Convert::Wikidata::Object::Work->new;
};
is($EVAL_ERROR, "Parameter 'title' is required.\n",
	"Parameter 'title' is required.");
clean();
