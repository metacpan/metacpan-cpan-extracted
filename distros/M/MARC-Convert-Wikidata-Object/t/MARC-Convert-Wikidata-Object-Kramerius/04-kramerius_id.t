use strict;
use warnings;

use MARC::Convert::Wikidata::Object::Kramerius;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Kramerius->new;
is($obj->kramerius_id, undef, 'Get undefined Kramerius system id.');

# Test.
$obj = MARC::Convert::Wikidata::Object::Kramerius->new(
	'kramerius_id' => 'nkp',
	'object_id' => '814e66a0-b6df-11e6-88f6-005056827e52',
);
is($obj->kramerius_id, 'nkp', 'Get Kramerius system id.');
