
=head1 NAME

EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym 

=head1 SYNOPSIS

EBI::FGPT::FuzzyRecogniser::OntologyTerm::Label and 
EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym  
both extend EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation, 
which contains two fields value and normalised_value.

my $synonym = EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym->new( value => $value);

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

package EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym;

use Moose;
our $VERSION = 0.09;

extends 'EBI::FGPT::FuzzyRecogniser::OntologyTerm::Annotation';

1;    # End of EBI::FGPT::FuzzyRecogniser::OntologyTerm::Synonym
