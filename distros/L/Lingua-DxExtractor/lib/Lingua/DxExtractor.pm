package Lingua::DxExtractor;

use 5.008008;
use strict;
use warnings;

our $VERSION = '2.31';

use Text::Sentence qw( split_sentences );
use Lingua::NegEx qw( negation_scope );


use Class::MakeMethods (
  'Template::Hash:array' => [
        'target_phrases', 'skip_phrases',
		'absolute_present_phrases', 'absolute_negative_phrases',
  ],
  'Template::Hash:scalar' => [
        'orig_text', 'final_answer', 'ambiguous', 
		'start_phrase',
  ],
  'Template::Hash:hash' => [
        'target_sentence', 'negex_debug',
  ],
);

######################################################################

sub new {
  my $callee = shift;
  my $package = ref $callee || $callee;
  my $self = shift;
  bless $self, $package;
  die 'Need to define target phrases' unless $self->target_phrases;
  return $self;
}

sub process_text {
  my ($self,$text) = @_;
  $self->orig_text( $text );
  $self->examine_text;
  return $self->final_answer;
}

sub examine_text {
  my $self = shift;
  my $text = $self->orig_text;
  return if ! $text;
  
  my $start_phrase = $self->start_phrase;
  if ( $start_phrase and $text =~ /$start_phrase(.*)\Z/ix ) {
    $text = $1;
  }
  $text =~ s/\s+/ /gxms;
  # treat colon ':' like a period '.'
  $text =~ s/:/./g;
  
  my @sentences = split_sentences( $text );
  foreach my $line ( @sentences ) {
  
    next if scalar grep { $line =~ /\b$_\b/i } @{$self->skip_phrases};
    next unless grep { $line =~ /\b$_\b/i } @{$self->target_phrases};
  	
    $self->target_sentence->{ $line } = 'present';
    my $n_scope = negation_scope( $line );

     if ( $n_scope ) {
      $self->negex_debug->{ $line } = @$n_scope[0] . ' - ' . @$n_scope[1];
      my @words;
      foreach ( split /\s/xms, $line ) {
        s/\W//xms;
        push @words, $_;
      }
      foreach my $c ( @$n_scope[0] .. @$n_scope[1] ) {
        my @match = grep { $words[ $c ] =~ /$_/ixms } @{$self->target_phrases};
		
	    if ( scalar @match ) {
          $self->target_sentence->{ $line } = 'absent';
          last;
        }
      }
    }
  }
  
  if ( scalar keys %{$self->target_sentence} ) {
    my %final_answer;
    while ( my($sentence,$answer) = each %{$self->target_sentence} ) {
      $final_answer{ $answer }++;
      $self->final_answer( $answer );
    }
    if ( scalar keys %final_answer > 1 ) {
      $self->ambiguous( 1 ); 
      $final_answer{ 'absent' } ||= 0;
      $final_answer{ 'present' } ||= 0;

      if ( $final_answer{ 'absent' } > $final_answer{ 'present' } ) {
        $self->final_answer( 'absent' );
      } elsif ( $final_answer{ 'present' } > $final_answer{ 'absent' } ) {
        $self->final_answer( 'present' );
      } else {
	  # There are an equal number of absent/present findings - defaulting to present
        $self->final_answer( 'present' );
      }
    }

  } elsif ( ! scalar keys %{$self->target_sentence} ) {
    $self->final_answer( 'absent' );
  }
  

  if ( grep { $text =~ /$_/i } @{$self->absolute_negative_phrases} and $self->final_answer eq 'present' ) {
    $self->final_answer( 'absent' );
	$self->ambiguous( 3 ); 
  }
  if ( grep { $text =~ /$_/i } @{$self->absolute_present_phrases} and $self->final_answer eq 'absent' ) {
    $self->final_answer( 'present' );
	$self->ambiguous( 2 );
  }
}

sub debug {
  my $self = shift;
  my $out = "Target Phrases(" . (join ', ', map { qq{'$_'} } @{$self->target_phrases}) . ")\r\n\r\n";
  $out .= "Skip Phrases(" . (join ', ', map { qq{'$_'} } @{$self->skip_phrases}) . ")\r\n\r\n" if $self->skip_phrases;
  $out .= "Absolute Present Phrases(" . (join ', ', map { qq{'$_'} } @{$self->absolute_present_phrases}) . ")\r\n\r\n" if $self->absolute_present_phrases;
  $out .= "Absolute Negative Phrases(" . (join ', ', map { qq{'$_'} } @{$self->absolute_negative_phrases}) . ")\r\n\r\n" if $self->absolute_negative_phrases;
  $out .= "Start Phrase( '" . $self->start_phrase . "' )\r\n\r\n" if $self->start_phrase;
  
  $out .= "Sentences with a target phrase match:\r\n";
  my $count = 1;
  while ( my($sentence,$answer) = each %{$self->target_sentence} ) {
    $out .= "$count) $sentence -- $answer. "; 
	$count++;
    $out .= "NegEx: " . ($self->negex_debug->{ $sentence } || 'None') . "\r\n";
  }
  $out .= "\r\nAmbiguous: " . ($self->ambiguous ==  1 ? 'Yes' : ( $self->ambiguous == 2 ? 'Absolute Present Phrase was present but the answer was going to be absent.' : ( $self->ambiguous == 3 ? 'Absolute Negative Phrase was present but the answer was going to be present.' : 'No' ) ) );
  $out .= "\r\nFinal Answer: " . $self->final_answer . "\r\n";
  return $out;
}

sub reset {
  my $self = shift;
  $self->orig_text( '' );
  $self->target_sentence( {} );
  $self->final_answer( '' );
  $self->ambiguous( '' );
}

1;

=head1 NAME

Lingua::DxExtractor - Perl extension to extract the presence or absence of a clinical condition from medical reports. 

=head1 SYNOPSIS

  use Lingua::DxExtractor; 

  $extractor = Lingua::DxExtractor->new( { 
	target_phrases => [ qw( embolus embolism emboli defect pe clot clots ) ], 
	skip_phrases => [ qw( history indication technique nondiagnostic ) ], 
	absolute_present_phrases => [ ( 'This is definitely a PE', 'absolutely positive for pe' ) ],
	absolute_negative_phrases => [ ( 'there is no way this is a pe', 'no clots seen at all' ) ],
	start_phrase => 'Impression:',
  } ); 
 
  $text = <<END; 
  Indication: To rule out pulmonary embolism. Findings: There is no evidence of vascular filling defect to the subsegmental level... 
  END 

  $final_answer = $extractor->process_text( $text ); # 'absent' or 'present' 
  $is_final_answer_ambiguous = $extractor->ambiguous; # 1 or 0 
  $debug = $extractor->debug;

  $original_text = $extractor->orig_text; 
  $final_answer = $extractor->final_answer;
  $ambiguous = $extractor->ambiguous; 

  $extractor->clear; # clears orig_text, final_answer, target_sentence and ambiguous 

=head1 DESCRIPTION

A tool to be used to look for the presence or absence of a clinical condition as reported in medical reports. The extractor reports a 'final answer', 'absent' or 'present', as well as reports whether this answer is 'ambiguous' or not.

The 'use case' for this is when performing a research project with a large number of records and you need to identify a subset based on a diagnostic entity, you can use this tool to reduce the number of charts that have to be manually examined.

The medical reports don't require textual preprocessing however clearly the selection of target_phrases and skip_phrases requires reading through reports to get a sense of what vocabulary is being used in the particular dataset that is being evaluated.

Negated terms are identified using Lingua::NegEx which is a perl implementation of Wendy Chapman's NegEx algorithm.

=head2 GETTING STARTED

Create a new extractor object with  your extraction rules:

  target_phrases( \@words );

This is a list of phrases that describe the clinical entity in question. All forms of the entity in question need to explicitly stated since the package is currently not using lemmatization or stemming. This is the only required parameter for the extractor object.

  skip_phrases( \@skip );

This is a list of phrases that can be used to eliminate sentences in the text that might confuse the extractor. For example most radiographic reports start with a brief description of the indication for the test. This statement may state the clinical entity in question but does not mean it is present in the study (ie. Indication: to rule out pulmonary embolism). 

  absolute_negative_phrases( \@absolute_negative_assertions );
 
This is a list of phrases which if present in the text mean the condition is certainly not there and all ambiguity checking can be skipped.
 
  absolute_present_phrases( \@absolute_positive_assertions );

This is a list of phrases which if present in the text mean the condition is certainly there and all ambiguity checking can be skipped.

  start_phrase( $start_phrase );

A phrase if present in the text which indicates where to focus the search. All text prior to the start_phrase is ignored. Often times in radiology reports there is a 'Conclusion: ' or 'Impression: ' section which can be reviewed rather than analyzing the full report.

=head2 ANALYSIS

Once defined, the extractor object you created can be used to analyze target text. The analysis consists of:

1. If there is a start phrase defined, eliminate all text for analysis prior to the start phrase.

2. Make text all lowercase, eliminate extra spaces, and change all colons ':' into periods '.' to treat them as sentence breaks.

3. Split text into sentences using Text::Sentence.

4. Examine each sentence for the presence of any skip phrases and if found, ignore the sentence.

5. Examine each sentence for the presence of any target phrases and if found evaluate for negation using Lingua:Negex.

-if no negation found, mark this sentence as 'present'

-if the target phrase is negated then mark the sentence as 'absent'

6. Go through all the flagged sentences and see if there is any discrepancy -- if so set the ambiguous flag. If there are more sentences that indicate absent than those that indicate present then mark the final answer as absent and vice versa. If there are an equal number of absent and present phrases mark the final answer as present.

7. The possible values for ambiguous: 1 = there were some positive and some absent sentences; 2 = there was a match on an absolute positive phrase but the answer was going to be absent had this absolute phrase not been indicated; 3 = there was a match on an absolute negative phrase but the answer was going to be present had this absolute phrase not been indicated; If both an absolute positive and negation phrase was present, mark the final answer as present.

=head2 EXPORT

None by default.

=head1 SEE ALSO

This module depends on:

Text::Sentence

Class::MakeMethods

Lingua::NegEx

=head1 To Do

Add lemmatization or stemming to target_phrases so you don't have to explicitly write out all forms of words 

=head1 AUTHOR

Eduardo Iturrate, <lt>ed@iturrate.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Eduardo Iturrate

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
