=head1 NAME

EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation

=head1 SYNOPSIS

  EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation contains two fields- value
  and normalised_value

  my $annotationToMatch =
  EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation->new( value => $string_to_match );


=head2 METHODS

=over

=item normalise()

Normalises a string by changing it lowercase and
splitting into 4-grams.

=back

=over

=item compare()

Counts how many n-grmas are shared between annotations

=back

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

package EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation;


use Moose;
use List::Util qw{min max};

our $VERSION = 0.09;

has 'value' => (
				 is  => 'rw',
				 isa => 'Str',
);

has 'normalised_value' => (
							is         => 'ro',
							isa        => 'HashRef',
							lazy_build => 1
);

sub _build_normalised_value {
	my $self = shift;
	return normalise( $self->value );
}

sub normalise {
	my $string = shift;
	$string = lc($string);
	my $q = 4;

	my $ngram;

	# pad the string
	for ( 1 .. $q - 1 ) {
		$string = '^' . $string;
		$string = $string . '$';
	}

	# split ito ngrams
	for my $i ( 0 .. length($string) - $q ) {
		$ngram->{ substr( $string, $i, $q ) }++;
	}

	return $ngram;
}

sub compare($$) {
	# passed string_to_match wrapped in an annotation object
	my ( $self, $annotationToMatch ) = @_;
	#retrieve normalised hashes for the string values of the annotations
	my $template                     = $self->normalised_value();
	my $normalised_annotationToMatch = $annotationToMatch->normalised_value();

	my $ngrams_matched = 0;
	#count ngrams shared between this annotation and the annotation to match
	for my $template_ngram ( keys %{$template} ) {
		$ngrams_matched++ if exists $normalised_annotationToMatch->{$template_ngram};
	}

	# normalise
	return
	  int(
		 $ngrams_matched / max( scalar keys %$template, scalar keys %$normalised_annotationToMatch )
		   * 100 );
}

1;                     # End of EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation
