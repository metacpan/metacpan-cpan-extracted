use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 19;
use Test::NoWarnings;
use Test::Warn;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test
my $marc_data = slurp($data->file('cnb002031137.xml')->s);
my $obj;
warning_like
	{
		$obj = MARC::Convert::Wikidata::Transform->new(
			'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
		);
	}
	qr{^People type 'pbl' doesn't exist\.},
	"Test of warning about 'pbl' people type.",
;
my $ret = $obj->object;
my $languages_ar = $ret->languages;
is_deeply(
	$languages_ar,
	[
		'cze',
		'ger',
		'fre',
	],
	'Památky krasopisné: Get languages (cze, ger, fre).',
);
my $external_ids_ar = $ret->external_ids;
is(@{$external_ids_ar}, 5, 'Památky krasopisné: Get external ids count (5).');
is($external_ids_ar->[0]->name, 'cnb', 'Památky krasopisné: Get external value name (cnb).');
is($external_ids_ar->[0]->value, 'cnb002031137', 'Památky krasopisné: Get ČČNB id (cnb002031137).');
is($external_ids_ar->[0]->deprecated, 0, 'Památky krasopisné: Get ČČNB deprecated flag (0).');
is($external_ids_ar->[1]->name, 'cnb', 'Památky krasopisné: Get external value name (cnb).');
is($external_ids_ar->[1]->value, 'cnb001268082', 'Památky krasopisné: Get ČČNB id (cnb001268082).');
is($external_ids_ar->[1]->deprecated, 1, 'Památky krasopisné: Get ČČNB deprecated flag (1).');
is($external_ids_ar->[2]->name, 'cnb', 'Památky krasopisné: Get external value name (cnb).');
is($external_ids_ar->[2]->value, 'cnb001268083', 'Památky krasopisné: Get LCCN id (cnb001268083).');
is($external_ids_ar->[2]->deprecated, 1, 'Památky krasopisné: Get ČČNB deprecated flag (1).');
is($external_ids_ar->[3]->name, 'lccn', 'Památky krasopisné: Get external value name (lccn).');
is($external_ids_ar->[3]->value, '85699136', 'Památky krasopisné: Get LCCN id (85699136).');
is($external_ids_ar->[3]->deprecated, 0, 'Památky krasopisné: Get ČČNB deprecated flag (0).');
is($external_ids_ar->[4]->name, 'lccn', 'Památky krasopisné: Get external value name (lccn).');
is($external_ids_ar->[4]->value, '85699139', 'Památky krasopisné: Get LCCN number (85699139).');
is($external_ids_ar->[4]->deprecated, 0, 'Památky krasopisné: Get ČČNB deprecated flag (0).');
