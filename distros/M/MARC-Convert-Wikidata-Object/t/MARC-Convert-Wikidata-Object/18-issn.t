use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->issn, undef, 'Get default ISSN number.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'issn' => '0544-3830',
);
is($obj->issn, '0544-3830', 'Get explicit ISSN number.');
