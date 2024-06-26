use strict;
use warnings;

use MARC::Convert::Wikidata::Object::People;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = MARC::Convert::Wikidata::Object::People->new;
my $ret = $obj->work_period_end;
is($ret, undef, 'Get work period end (undef - default).');

# Test.
$obj = MARC::Convert::Wikidata::Object::People->new(
	work_period_end => 1960,
);
$ret = $obj->work_period_end;
is($ret, '1960', 'Get work period end (1960).');
