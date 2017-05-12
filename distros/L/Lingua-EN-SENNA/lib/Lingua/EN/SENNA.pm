package Lingua::EN::SENNA;
use strict;
use warnings;

our $VERSION = '0.04';

our $SENNA_path = $INC{"Lingua/EN/SENNA.pm"};
$SENNA_path =~ s/\.pm$/\/third-party\/senna\//;

require XSLoader;
XSLoader::load('Lingua::EN::SENNA', $VERSION);

1;
__END__

=pod 

=head1 NAME

C<Lingua::EN::SENNA> - Perl wrapper for the SENNA NLP toolkit

=head1 SYNOPSIS

  use Lingua::EN::SENNA;
  $tagger = Lingua::EN::SENNA->new();
  $sentences = ["The fox swallowed the cheese",
                 "John loves Mary",
                 "He likes to code and sing but not to dance"];
  $tokens = $tagger->tokenize($sentences);
  $part_of_speech_tags = $tagger->pos_tag($sentences);
  $analysis = $tagger->analyze($sentences,{POS=>1, CHK=>1, NER=>1, SRL=>1, PSG=>1});

=head1 DESCRIPTION

This package wraps around and bundles with the SENNA NLP toolkit.
SENNA performs sentence-level analysis, hence it expects each inidividual input to be a natural language sentence.
Thus, one needs to independently discover sentences, e.g. by using L<Lingua::EN::Sentence> or similar.

The supported SENNA features are currently: Tokenization, POS, CHK, NER, SRL, PSG.

The wrapper is still experimental and does not support the full range of SENNA customizability options.
For unsupported options, the wrapper assumes SENNA's original default behaviour.

For the original documentation, please consult:
http://ml.nec-labs.com/senna/

=head2 METHODS

=over 4

=item C<< $tokens = $tagger->tokenize($sentences); >>

Returns an array reference of words for every sentence.
The input is an array references of strings, each string representing a single sentence.

=item C<< $part_of_speech_tags = $tagger->pos_tag($sentences); >>

For every sentence, returns an array ref of hash references.
Each hash reference contains a "word" and "POS" keys, for each tokenized
word and its respective part-of-speech tag.

The input is an array reference of strings, each string representing a single sentence.

=item C<< $analysis = $tagger->analyze($sentences,{POS=>1, CHK=>1, NER=>1, SRL=>1, PSG=>1}); >>

General method, invoking any combination of SENNA analysis components.

For every sentence, returns an array ref of hash references.
Each hash reference contains a "word" and "POS" keys, for each tokenized
word and its respective part-of-speech tag.

The input is an array reference of strings, each string representing a single sentence,
followed by a hash references of options. The allowed option keys represent
SENNA analysis components. Supported are: POS, CHK, NER, SRL and PSG.


=back

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

 Research software, produced as part of work done by 
 the KWARC group at Jacobs University Bremen.
 Released under the SENNA license, see LICENSE file for details.

=cut