use strict;
use warnings;

use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::People->new;
my $ret = $obj->work_period_start;
is($ret, undef, 'Get work period start (undef - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::People->new(
	work_period_start => 1900,
);
$ret = $obj->work_period_start;
is($ret, '1900', 'Get work period start (1900).');
