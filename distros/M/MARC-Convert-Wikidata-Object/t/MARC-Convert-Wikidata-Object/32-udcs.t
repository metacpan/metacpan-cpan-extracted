use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is_deeply(
	$obj->udcs,
	[],
	'Get default UDCs list.',
);

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'udcs' => [
		'821.162.3-31',
		'(0:82-313.2)',
		'(0:82-313.2)',
	],
);
my @udcs = @{$obj->udcs};
is(@udcs, 3, 'Get number of UDCs.');
