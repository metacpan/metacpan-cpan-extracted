#!perl

use lib  'C:/Users/emma.EBI/Fuzzy/cpan-distribution/FuzzyRecogniser/lib';

use Test::More;

use EBI::FGPT::FuzzyRecogniser;
use Data::Dumper;

# turn off info for test
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);

BEGIN { use_ok('EBI::FGPT::FuzzyRecogniser'); }
require_ok('EBI::FGPT::FuzzyRecogniser');

my $dirname = File::Basename::dirname($0);

#uses a chunk of an efo obo file as the ontology file
$abs_path = File::Spec->catfile( $dirname, 'data', 'efo_obo.txt' );

my $fuzzy = EBI::FGPT::FuzzyRecogniser->new( obofile => $abs_path );    # create an object


#test exact match
my $x = $fuzzy->find_match('submitter');
isa_ok( $x, 'HASH' );                                                   #check is a hash

is( $x->{'similarity'}, 100, 'similarity score equal to 100' );
is( $x->{'type'},
	'EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label',
	'Type is EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label' );
is( $x->{'term'}->accession(), 'EFO:0001741', 'EFO accession is equal to EFO:0001741 ' );
is( $x->{'value'},             'submitter',   'Value matched is submitter' );


#test value with a mis-spelling
$x = $fuzzy->find_match('cand7la');
isa_ok( $x, 'HASH' );                                                   #check is a hash

isnt( $x->{'similarity'}, 100, 'similarity score is not equal to 100' );
is( $x->{'type'},
	'EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label',
	'Type is EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label' );
is( $x->{'term'}->accession(), 'UO:0000014', 'EFO accession is equal to UO:0000014' );
is( $x->{'value'},             'candela',    'Term matched is candela' );

#test value with a odd characters
$x = $fuzzy->find_match('h@man-herpesvirus/~8');
isa_ok( $x, 'HASH' );                                                   #check is a hash

isnt( $x->{'similarity'}, 100, 'similarity score is not equal to 100' );
is( $x->{'type'},
	'EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label',
	'Type is EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label' );
is( $x->{'term'}->accession(), 'EFO:0002612',         'EFO accession is equal to EFO:0002612' );
is( $x->{'value'},             'human herpesvirus 8', 'Term matched is human herpesvirus 8' );




#test value with synonym
$x = $fuzzy->find_match('BRCA1');
isa_ok( $x, 'HASH' );                                                   #check is a hash
is( $x->{'similarity'}, 100, 'similarity score is equal to 100' );
is( $x->{'type'},
	'EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym',
	'Type is EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym' );
is( $x->{'term'}->accession(), 'EFO:0002611', 'EFO accession is equal to EFO:0002611' );
is( $x->{'term'}->label(),
	'hereditary breast and ovarian cancer',
	'Term matched is hereditary breast and ovarian cancer' );



done_testing($number_of_tests_run);
