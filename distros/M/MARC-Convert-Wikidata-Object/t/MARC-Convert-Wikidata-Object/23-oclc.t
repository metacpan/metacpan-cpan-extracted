use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->oclc, undef, 'Get default OCLC control number.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'oclc' => 320118185,
);
is($obj->oclc, 320118185, 'Get explicit OCLC control number.');
