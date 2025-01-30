use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb001042253.mrc')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_usmarc($marc_data),
);
my $ret = $obj->object;
my $external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 4, 'Sněženka: Get external ids count (3).');
is($external_ids_ar->[0]->name, 'cnb', 'Sněženka: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb001042253', 'Sněženka: Get ČČNB number (cnb001042253).');
is($external_ids_ar->[1]->name, 'cnb', 'Sněženka: Get external value name (cnb).');
is($external_ids_ar->[1]->value, 'cnb001250271', 'Sněženka: Get ČČNB number (cnb001250271).');
is($external_ids_ar->[1]->deprecated, 1, 'Sněženka: Get ČČNB number deprecation (1).');
is($external_ids_ar->[2]->name, 'lccn', 'Sněženka: Get external value name (lccn).');
is($external_ids_ar->[2]->value, '85710900', 'Sněženka: Get LCCN number (85710900).');
is($external_ids_ar->[3]->name, 'lccn', 'Sněženka: Get external value name (lccn).');
is($external_ids_ar->[3]->value, '85018016', 'Sněženka: Get LCCN number (85018016).');
