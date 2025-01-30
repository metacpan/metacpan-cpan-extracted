use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 10;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb002662450.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my $isbn = $ret->isbns->[0];
is($isbn->isbn, '978-80-7404-144-0', 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 1 (978-80-7404-144-0).');
is($isbn->cover, 'paperback', 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 1 cover (paperback).');
is($isbn->collective, 0, 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 1 collective flag (0).');
$isbn = $ret->isbns->[1];
is($isbn->isbn, '978-80-204-3500-2', 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 2 (978-80-204-3500-2).');
is($isbn->cover, 'paperback', 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 2 cover (paperback).');
is($isbn->collective, 0, 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 2 collective flag (0).');
$isbn = $ret->isbns->[2];
is($isbn->isbn, '978-80-204-4479-0', 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 3 (978-80-204-3500-2).');
is($isbn->cover, undef, 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 3 cover (undef).');
is($isbn->collective, 1, 'Češi: 1992: jak Mečiar s Klausem rozdělili stát: Get isbn 3 collective flag (1).');
