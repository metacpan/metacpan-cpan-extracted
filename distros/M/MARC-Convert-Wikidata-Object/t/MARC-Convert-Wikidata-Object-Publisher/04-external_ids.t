use strict;
use warnings;

use MARC::Convert::Wikidata::Object::ExternalId;
use MARC::Convert::Wikidata::Object::Publisher;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
	'name' => 'Academia',
);
my $ret = $obj->external_ids;
is_deeply($ret, [], 'Get external ids ([] - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::Publisher->new(
        'external_ids' => [
                MARC::Convert::Wikidata::Object::ExternalId->new(
                        'name' => 'nkcr_aut',
                        'value' => 'ko2002101950',
                ),
        ],
	'id' => '000010003',
	'name' => 'Academia',
	'place' => 'Praha',
);
$ret = $obj->external_ids;
is(@{$ret}, 1, 'Get external ids count (1).');
isa_ok($ret->[0], 'MARC::Convert::Wikidata::Object::ExternalId');
is($ret->[0]->name, 'nkcr_aut', 'Get external id name (nkcr_aut).');
is($ret->[0]->value, 'ko2002101950', 'Get external id value (ko2002101950).');
