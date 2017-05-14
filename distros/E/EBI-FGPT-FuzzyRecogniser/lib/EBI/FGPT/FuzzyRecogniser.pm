
=head1 NAME

EBI::FGPT::FuzzyRecogniser
 
=head1 DESCRIPTION

The module EBI::FGPT::FuzzyRecogniser takes in the constructor 
an ontology file (OWL/OBO/OMIM/MeSH) 
and parses it into an internal table of 
ontology terms (type of EBI::FGPT::FuzzyRecogniser::OntologyTerm). 
The module contains the find_match method which finds the best match 
for the supplied term in the given ontology. This can be then queried for ->match_similarity(),
 ->matched_value(), ->matched_label(), and ->matched_accession(). The best match is
based on the n-grams similarity metric.

=head1 SYNOPSIS
	
    use EBI::FGPT::FuzzyRecogniser;
	
	# instantiate and pass ontology file
	
    my $fuzzy = EBI::FGPT::FuzzyRecogniser->new( obofile => 'obo.txt' );
    
    # call find_match on a supplied term
    # finds the best match for the supplied term in the ontology.
    
    my $x = $fuzzy->find_match('submitter');



=head1 AUTHOR

Emma Hastings , <ehastings@cpan.org>

=head1 ACKNOWLEDGEMENTS

Tomasz Adamusiak <tomasz@cpan.org>
 
=head1 COPYRIGHT AND LICENSE

Copyright [2011] EMBL - European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific
language governing permissions and limitations under the
License.

=cut

package EBI::FGPT::FuzzyRecogniser;

use lib  'C:/Users/emma.EBI/Fuzzy/cpan-distribution/FuzzyRecogniser/lib';

use Moose;

use IO::File;
use Getopt::Long;

use GO::Parser;
use OWL::Simple::Parser 1.00;
use MeSH::Parser::ASCII 0.02;
use Bio::Phenotype::OMIM::OMIMparser;
use EBI::FGPT::FuzzyRecogniser::OntologyTerm;
use EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation;
use EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label;
use EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym;
use Log::Log4perl qw(:easy);
use IO::Handle;
use Benchmark ':hireswallclock';

use List::Util qw{min max};

use Data::Dumper;

our $VERSION = 0.09;

Log::Log4perl->easy_init( { level => $INFO, layout => '%-5p - %m%n' } );

# module attributes

has 'meshfile'       => ( is => 'rw', isa => 'Str' );
has 'obofile'        => ( is => 'rw', isa => 'Str' );
has 'owlfile'        => ( is => 'rw', isa => 'Str' );
has 'omimfile'       => ( is => 'rw', isa => 'Str' );
has 'ontology_terms' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] });

sub BUILD {

	my $self = shift;

	# ensure ontology files have been supplied

	unless (    $self->obofile()
			 || $self->owlfile()
			 || $self->meshfile()
			 || $self->omimfile() )
	{
		LOGDIE "No ontology file supplied";
	}

	INFO "Parsing file ";

	#establishes ontology object and passes it to
	#relevantparser

	$self->parseOWL( $self->owlfile )   if $self->owlfile;
	$self->parseOBO( $self->obofile )   if $self->obofile;
	$self->parseMeSH( $self->meshfile ) if $self->meshfile;
	$self->parseOMIM( $self->omimfile ) if $self->omimfile;
}

=over

=item find_match()

Finds the best match for the supplied term in the ontology.

=cut

sub find_match($) {
	my ( $self, $string_to_match ) = @_;

	# terms array was already prenormalised earlier
	my $annotationToMatch =
	  EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation->new( value => $string_to_match );

	my $matched_term;
	my $matched_value;
	my $type;
	my $max_similarity = undef;

	#loop through all ontology terms
	for my $term ( @{ $self->ontology_terms } ) {

		#loop through all the annotations on the ontology term
		for my $annotation ( @{ $term->annotations } ) {

			#compare this annotation against passed string
			my $similarity = $annotation->compare($annotationToMatch);
			if ( !( defined $max_similarity ) || $similarity > $max_similarity ) {
				$max_similarity = $similarity;
				$matched_term   = $term;
				$matched_value  = $annotation->value();
				$type           = ref($annotation);
			}
		}

	}

	return {
			 term => $matched_term,
			 value  => $matched_value,
			 similarity  => $max_similarity,
			 type => $type,
	};
}

=item createOntologyTerm()

Creates an OntologyTerm object given its accession and annotations

=cut

sub createOntologyTerm($$@) {
	my ( $accession, $label, @synonyms ) = @_;

	# Create annotation array
	my @annotations;

	# Create label
	my $label_annot = EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label->new( value => $label );

	# Add label to annotations
	# NOTE stored twice for convenience, see label field
	push @annotations, $label_annot;

	# Create synonym annotations
	for my $value (@synonyms) {

		# Create synonym
		my $synonym = EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym->new( value => $value );

		# Add synonym to term's annotations
		push @annotations, $synonym;
	}

	return
	  EBI::FGPT::FuzzyRecogniser::OntologyTerm->new(
													 accession   => $accession,
													 label       => $label,
													 annotations => \@annotations,
	  );
}

=item parseMeSH()

Custom MeSH parser for the MeSH ASCII format.

=cut

sub parseMeSH($) {
	my ( $self, $file ) = @_;
	my $term;
	INFO "Parsing MeSH file $file ...";

	my $parser = MeSH::Parser::ASCII->new( meshfile => $file );

	# parse the file
	$parser->parse();

	# loop through all the headings
	while ( my ( $id, $heading ) = each %{ $parser->heading } ) {
		my $accession = $id;
		my $label     = $heading->{label};
		my @synonyms  = @{ $heading->{synonyms} };
		my $term      = createOntologyTerm( $accession, $label, @synonyms );

		# Add term to ontology_terms array
		push @{ $self->ontology_terms }, $term;
	}
}

=item parseMeSH()

Custom OMIM parser.

=cut

sub parseOMIM($) {
	my ( $self, $file ) = @_;
	INFO "Parsing OMIM file $file ...";

	my $synonym_count;

	# FIXME: The external parser is suboptimal in many ways
	# if this becomes more often used consider creating
	# a custom one from sratch
	my $parser = Bio::Phenotype::OMIM::OMIMparser->new( -omimtext => $file );

	# loop through all the records
	while ( my $omim_entry = $parser->next_phenotype() ) {

		# *FIELD* NO
		my $id = $omim_entry->MIM_number();
		$id = 'OMIM:' . $id;

		# *FIELD* TI - first line
		my $title = $omim_entry->title();
		$title =~ s/^.\d+ //;       # remove id from title
		$title =~ s/INCLUDED//g;    # remove INCLUDED as it screws up scoring

		# *FIELD* TI - additional lines
		my $alt = $omim_entry->alternative_titles_and_symbols();

		# OMIM uses this weird delimiter ;;
		# to signal sections irrespective of actual line endings
		# this is a major headache to resolve, the parser doesn't
		# do this and we're not going to bother with it either
		$alt =~ s/;;//g;
		$alt =~ s/INCLUDED//g;      # remove INCLUDED as it screws up scoring
		my @synonyms = split m!\n!, $alt;

		# if alt doesn't start with ;; it's an overspill from the
		# title (go figure!)
		if (    $alt ne ''
			 && $omim_entry->alternative_titles_and_symbols() !~ /^;;/ )
		{
			$title .= shift @synonyms;
		}

		# Instantiate new ontology term

		my $term = createOntologyTerm( $id, $title, @synonyms );

		# Add term to ontology_terms array
		push @{ $self->ontology_terms }, $term;

		$synonym_count += scalar @synonyms;

	}

}

=item parseOBO()

Custom OBO parser.

=cut

sub parseOBO($) {
	my ( $self, $file ) = @_;
	INFO "Parsing obo file $file ...";
	my $parser = new GO::Parser( { handler => 'obj' } );
	$parser->parse($file);
	my $graph = $parser->handler->graph();

	# load terms into hash
	my $class_count;
	my $synonym_count;

	for my $OBOclass ( @{ $graph->get_all_terms() } ) {
		if ( $OBOclass->is_obsolete ) {
			INFO $OBOclass->public_acc() . ' obsoleted';
			next;
		}
		$class_count++;
		$synonym_count += scalar( @{ $OBOclass->synonym_list() } );

		# Instantiate new ontology term
		my $accession = $OBOclass->public_acc();
		my $label     = $OBOclass->name();
		my @synonyms  = @{ $OBOclass->synonym_list() };
		my $term      = createOntologyTerm( $accession, $label, @synonyms );

		# Add term to  array
		push @{ $self->ontology_terms }, $term;
	}

	INFO "Loaded " . $class_count . " classes and " . $synonym_count . " synonyms";

}

=item parseOWL()

Custom OWL parser.

=cut

sub parseOWL($) {
	my ( $self, $file ) = @_;
	INFO "Parsing owl file $file ...";
	my $parser;

	# invoke parser
	$parser = OWL::Simple::Parser->new( owlfile => $file );

	# parse file
	$parser->parse();

	while ( my ( $id, $OWLClass ) = each %{ $parser->class } ) {
		unless ( defined $OWLClass->label ) {
			WARN "Undefined label in $id";
		}
		elsif ( $OWLClass->label =~ /obsolete/ ) {
			next;
		}

		# Instantiate new ontology term
		my $accession = $OWLClass->id();
		my $label     = $OWLClass->label();
		my @synonyms  = @{ $OWLClass->synonyms() };

		my $term = createOntologyTerm( $accession, $label, @synonyms );

		# Add term to  array
		push @{ $self->ontology_terms }, $term;
	}

}
1;    # End of EBI::FGPT::FuzzyRecogniser
