use strict;
use warnings;

use File::Object;
use MARC::Convert::Wikidata::Transform;
use MARC::File::XML;
use MARC::Record;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 21;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $marc_data = slurp($data->file('cnb000040543.xml')->s);
my $obj = MARC::Convert::Wikidata::Transform->new(
	'marc_record' => MARC::Record->new_from_xml($marc_data, 'UTF-8'),
);
my $ret = $obj->object;
my @translators = @{$ret->translators};
is($translators[0]->date_of_birth, 1940, 'Get first translator date of birth (1940).');
is($translators[0]->date_of_death, 2005, 'Get first translator date of death (2005).');
is($translators[0]->name, 'Bohdan', 'Get first translator name (Bohdan).');
is($translators[0]->surname, 'Zelinka', 'Get first translator surname (Zelinka).');
is($translators[0]->external_ids->[0]->name, 'nkcr_aut', 'Get first translator external id name (nkcr_aut).');
is($translators[0]->external_ids->[0]->value, 'jk01152417', 'Get first translator external id value (jk01152417).');
is($translators[1]->name, decode_utf8('Antonín'), 'Get second translator name (Antonín).');
is($translators[1]->surname, 'Vrba', 'Get second translator surname (Vrba).');
is($translators[1]->external_ids->[0]->name, 'nkcr_aut', 'Get second translator external id name (nkcr_aut).');
is($translators[1]->external_ids->[0]->value, 'jk01150955', 'Get second translator external id value (jk01150955).');
my @compilers = @{$ret->compilers};
is($compilers[0]->date_of_birth, 1940, 'Get first compiler date of birth (1940).');
is($compilers[0]->date_of_death, 2005, 'Get first compiler date of death (2005).');
is($compilers[0]->name, 'Bohdan', 'Get first compiler name (Bohdan).');
is($compilers[0]->surname, 'Zelinka', 'Get first compiler surname (Zelinka).');
is($compilers[0]->external_ids->[0]->name, 'nkcr_aut', 'Get first compiler external id name (nkcr_aut).');
is($compilers[0]->external_ids->[0]->value, 'jk01152417', 'Get first compiler external id value (jk01152417).');
is($compilers[1]->name, decode_utf8('Antonín'), 'Get second compiler name (Antonín).');
is($compilers[1]->surname, 'Vrba', 'Get second compiler surname (Vrba).');
is($compilers[1]->external_ids->[0]->name, 'nkcr_aut', 'Get second compiler external id name (nkcr_aut).');
is($compilers[1]->external_ids->[0]->value, 'jk01150955', 'Get first compiler external id value (jk01150955).');
