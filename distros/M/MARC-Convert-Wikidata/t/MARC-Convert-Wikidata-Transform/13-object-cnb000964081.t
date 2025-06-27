use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000964081.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my @covers = sort @{$ret->covers};
is(scalar @covers, 2, 'Get cover count (2).');
is_deeply(
	\@covers,
	[
		'hardback',
		'paperback',
	],
	'Get covers (hardback, paperback).',
);
my @isbns = @{$ret->isbns};
is(scalar @isbns, 2, 'Get ISBN count (2).');
is($isbns[0]->isbn, '80-7033-674-9', 'Bič: Get ISBN-10 (80-7033-674-9).');
is($isbns[0]->cover, 'hardback', 'Bič: Get ISBN cover (hardback).');
is($isbns[1]->isbn, '80-7033-675-7', 'Bič: Get ISBN-10 (80-7033-675-7).');
is($isbns[1]->cover, 'paperback', 'Bič: Get ISBN cover (paperback).');
