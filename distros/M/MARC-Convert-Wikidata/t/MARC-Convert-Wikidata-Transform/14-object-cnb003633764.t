use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Warn;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb003633764.xml')->s);
my $obj;
warning_like
	{
		$obj = MARC::Convert::Wikidata::Transform->new(
			'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
		);
	}
	qr{Dotisk druhého vydání},
	"Test of warning about edition number.",
;
my $ret = $obj->object;
my $isbn_count = @{$ret->isbns};
is($isbn_count, 1, 'Holubí mambo: Get count of ISBNs in book (1).');
my $isbn = $ret->isbns->[0];
is($isbn->isbn, '978-80-7217-383-9', 'Holubí mambo: Get ISBN (978-80-7217-383-9).');
is($isbn->cover, 'paperback', 'Holubí mambo: Get ISBN cover (paperback).');
is($isbn->collective, 0, 'Holubí mambo: Get ISBN collective flag (0).');
is($isbn->valid, 0, 'Holubí mambo: Get ISBN valid flag (0).');
