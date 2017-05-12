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

#uses a EFO owl file as the ontology file
$abs_path = File::Spec->catfile( $dirname, 'data', 'efo_part.owl' );

my $fuzzy = EBI::FGPT::FuzzyRecogniser->new( owlfile => $abs_path );    # create an object

#test two similar terms 

my $x = $fuzzy->find_match('Mus musculus');
isa_ok( $x, 'HASH' );                                                   #check is a hash

is( $x->{'similarity'}, 100, 'similarity score equal to 100' );
is( $x->{'type'},
	'EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label',
	'Type is EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label' );
is( $x->{'term'}->accession(),
	'http://purl.org/obo/owl/NCBITaxon#NCBITaxon_10090',
	'EFO accession is equal to http://purl.org/obo/owl/NCBITaxon#NCBITaxon_10090' );
is( $x->{'value'}, 'Mus musculus', 'Value matched is Mus musculus' );

$x = $fuzzy->find_match('Mus musculus musculus');
isa_ok( $x, 'HASH' );    #check is a hash

is( $x->{'similarity'}, 100, 'similarity score is not equal to 100' );
is( $x->{'type'},
	'EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label',
	'Type is EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label' );
is( $x->{'term'}->accession(),
	'http://purl.org/obo/owl/NCBITaxon#NCBITaxon_39442',
	'EFO accession is equal to http://purl.org/obo/owl/NCBITaxon#NCBITaxon_39442' );
is( $x->{'value'}, 'Mus musculus musculus', 'Term matched is Mus musculus musculus' );

done_testing($number_of_tests_run);
