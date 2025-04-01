use strict;
use warnings;

use MARC::Convert::Wikidata::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object->new;
is($obj->title, undef, 'Get default title.');

# Test.
$obj = MARC::Convert::Wikidata::Object->new(
	'title' => 'Title',
);
is($obj->title, 'Title', 'Get explicit title.');
