use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
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
	'Get languages.',
);
