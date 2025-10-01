use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test
my $marc_data = slurp($data->file('cnb001756719.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my $author = $ret->authors->[0];
is($author->name, '', 'Učebnice práva ve čtyřech knihách: Get author name.');
is($author->surname, 'Gaius', 'Učebnice práva ve čtyřech knihách: Get author surname.');
is($author->date_of_birth, undef, 'Učebnice práva ve čtyřech knihách: Get author date of birth.');
is($author->date_of_death, undef, 'Učebnice práva ve čtyřech knihách: Get author date of death.');
is($author->work_period_start, 110, 'Učebnice práva ve čtyřech knihách: Get author work period start.');
is($author->work_period_end, 180, 'Učebnice práva ve čtyřech knihách: Get author work period end.');
my $author_ext_ids_ar = $author->external_ids;
is(@{$author_ext_ids_ar}, 1, 'Učebnice práva ve čtyřech knihách: Get author external ids count (1).');
is($author_ext_ids_ar->[0]->name, 'nkcr_aut', 'Učebnice práva ve čtyřech knihách: Get author external value name (nkcr_aut).');
is($author_ext_ids_ar->[0]->value, 'jn19990002527', 'Učebnice práva ve čtyřech knihách: Get author NKCR id (jn19990002527).');
