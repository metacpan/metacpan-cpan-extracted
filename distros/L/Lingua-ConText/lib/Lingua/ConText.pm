package Lingua::ConText;

use 5.008008;
use strict;
use warnings;

require Exporter;

our (@ISA,@EXPORT_OK,$VERSION,$phrase);
BEGIN {
  @ISA = qw(Exporter);
  $VERSION = '0.01';
  @EXPORT_OK = qw(
    applyContext
  );
}
##################################################################################################


our $MAX_WINDOW = 15;
our $target_word_regex = '<CONCEPT>';

##################################################################################################


our ($phrase, $regex_list);

sub init {
  while ( my($position,$type_hash) = each %{$phrase} ) {
    while ( my ($type,$list) = each %{$type_hash} ) {
      foreach my $p ( @{$list} ) {
         $regex_list->{$position}->{$type} .= '|' if $regex_list->{$position}->{$type};
         $regex_list->{$position}->{$type} .= $p;
      }
    }
  }
}

##################################################################################################

sub applyContext {
  my ( $concept, $sentence ) = @_;
  return unless $concept && $sentence;
  my $tagged = preprocess_sentence( $concept, $sentence );
  return [ "'$concept' not found in this sentence.", $sentence, ] if ! $tagged;
  # print "$tagged\n\n";

  my @words = split /[,;\s]+/, $tagged;

  my $ne = applyNegEx( \@words );
  my $tmp = applyTemporality( \@words );
  my $subj = applyExperiencer( \@words );
  return [ $concept, $sentence, $ne, $tmp, $subj ];
}

##################################################################################################

sub preprocess_sentence {
  my $concept = lc shift;
  my $sentence = lc shift;
  $sentence =~ s/\s+/ /g;

  if ( $sentence =~ /\b$concept\b/ ) {
    $sentence =~ s/\b$concept\b/$target_word_regex/g;
  } else {
    return;
  }

  while ( my($position,$type_hash) = each %{$regex_list} ) {
    while ( my ($type,$regex) = each %{$type_hash} ) {
      my $tag = uc( qq{<$type} . '_' . qq{$position>} );
      $sentence =~ s/\b($regex)\b/$tag/g;
    }
  }

  my $regex_time = "((1[4-9]|[1-9]?[2-9][0-9])[ |-][day|days] of)|(([2-9]|[1-9][0-9])[ |-][week|weeks] of)|(([1-9]?[0-9])[ |-][month|months|year|years] of)";  #pattern to recognize expressions of >14 days
  my $regex_time_for = "[for|over] the [last|past] (((1[4-9]|[1-9]?[2-9][0-9])[ |-][day|days] of)|(([2-9]|[1-9][0-9])[ |-][week|weeks] of)|(([1-9]?[0-9])[ |-][month|months|year|years] of))"; # other pattern to recognize expressions of >14 days
  my $regex_time_since = "since [last|the last]? ((([2-9]|[1-9][0-9]) weeks ago)|(([1-9]?[0-9])? [month|months|year|years] ago)|([january|february|march|april|may|june|july|august|september|october|november|december|spring|summer|fall|winter]))";

  $sentence =~ s/\b($regex_time)\b/<TIME_PRE>/g;
  $sentence =~ s/\b($regex_time_for)\b/<TIME_PRE>/g;
  $sentence =~ s/\b($regex_time_since)\b/<TIME_POST>/g;

  return $sentence;
}

##################################################################################################

sub applyNegEx {
  my $words = shift;

  my $window = [];
  my $word_count = scalar @{$words};

  my $this_context; #  = 'affirmed'; # affirmed, negated, possible

  my $m = 0;
  while ( $m < $word_count ) {

    if ( @{$words}[$m] =~ /PSEUDO/ ) {
      $m++;

    } elsif ( ${$words}[$m] eq '<NEG_PRE>' ) {
        my $max_window = ( $word_count < $m + $MAX_WINDOW) ? ($word_count - $m) : $MAX_WINDOW;
        foreach ( my $o=1; $o < $max_window; $o++)  {
           if ( ${$words}[$m+$o] =~ /(<NEG_PRE>|<NEG_POST>|<POSS_POST>|<NEG_END>)/ ) {
            last;
          } else {
            push @{$window}, ${$words}[$m+$o];
          }
        }

        if ( ${$words}[$m] eq '<NEG_PRE>' ) {
          $this_context = 'negated';
        } elsif ( @{$words}[$m] eq '<POSS_PRE>' ) {
          $this_context = 'possible';
        }

        for ( my $w=0; $w < scalar( @{$window} ); $w++) {
          if ( @{$window}[$w] =~ /$target_word_regex/ ) {
            return $this_context;
          }
        }
        $window = [];
        $m++;
    } elsif ( @{$words}[$m] =~ /(<NEG_POST>|<POSS_POST>)/  ) {

          my $max_window = ($m < $MAX_WINDOW) ? $m : $MAX_WINDOW;
          for ( my $o=1; $o < $max_window; $o++) {
            if( @{$words}[$m-$o] =~ /(<NEG_PRE>|<POSS_PRE>|<NEG_POST>|<POSS_POST>|<NEG_END>)/ ) {
              last;
            } else {
              push @{$window}, @{$words}[$m-$o];
            }

            if ( @{$words}[$m] eq '<NEG_POST>' ){
              $this_context = 'negated';
            } elsif ( @{$words}[$m] eq '<POSS_POST>' ) {
              $this_context = 'possible';
              for( my $w=0; $w< scalar( @{$window}); $w++ ) {
                if( @{$window}[$w] =! /$target_word_regex/ ) {
                  return $this_context;
                }
              }
              $window = [];
              $m++;
            }
          }
    } else {
        $m++;
    }
  }
  return $this_context;
}



# recent, historical, hypothetical
sub applyTemporality {
  my $words = shift;
    my $window = [];
    my $words_length = scalar @{$words};

    #Going from one temporality term to another, and creating the appropriate window
    my $mm = 0;
    while ( $mm < $words_length )  {
        # /IF word is a pseudo-negation, skips to the next word
        if ( @{$words}[$mm]  eq '<NEG_PSEUDO>' ) {
          $mm++;
        } elsif ( @{$words}[$mm] eq '<HYPO_PRE>' ) {
            #/IF word is a pre- hypothetical trigger term
            #/expands window until end of sentence, termination term, or other negation/possible trigger term
            for (  my $o=1; ($mm+$o) < $words_length; $o++ ) {
                if ( @{$words}[$mm+$o]  =~ /(<HYPO_END>|<HYPOEXP_END>|<HYPO_PRE>)/ ) {
                        last;
                } else {
                        push @{$window}, @{$words}[$mm+$0];
                }
            }
            #/check if there are concepts in the window
            for (  my $w=0; $w < scalar(@{$window}); $w++) {
                if ( @{$window}[ $w ] =~ /$target_word_regex/ ) {
                        return 'hypothetical';
                }
            }
           $window = [];
           $mm++;

        } elsif ( @{$words}[$mm] =~ /(<HIST_PRE>|<HISTEXP_END>|<HIST_PRE>)/ ) {
                #/expands window until end of sentence, termination term, or other negation/possible trigger term
                for (  my $o=1; ($mm+$o) < $words_length; $o++ ) {
                        if ( @{$words}[$mm+$o]  =~ /(<HIST_END>|<HIST_EXP_END>|<HIST_PRE>|<HIST_1W>)/ ) {
                                last;
                        } else {
                                push @{$window}, @{$words}[$mm+$o];
                        }
                }
                #/check if there are concepts in the window
                for ( my $w=0; $w < scalar(@{$window}); $w++) {
                        if ( @{$window}[$w] =~ /$target_word_regex/ ) {
                                return 'historical';
                        }
                }
                $window = [];
                $mm++;
        } elsif ( @{$words}[$mm] eq '<TIME_POST>'  ) {
                #/expands window until end of sentence, termination term, or other negation/possible trigger term
                for ( my $o=1; ($mm - $o ) >= 0; $o++ ) {
                        if ( @{$words}[ $mm - $o ] =~ /(<HIST_END>|<HISTEXP_END>|<HIST_PRE>)/ ) {
                                last;
                        } else {
                                push @{$window}, @{$words}[$mm - $o ];
                        }
                }
                #/check if there are concepts in the window
                for ( my $w=0; $w < scalar(@{$window}); $w++ )  {
                        if ( @{$window}[ $w] =~ /$target_word_regex/ ) {
                                return 'historical';
                        }
                }
                $window = [];
                $mm++;
        } else {
                $mm++;
        }
  }
  return 'recent';
}

sub applyExperiencer {
  my $words = shift;
  my $window;
  my $mm = 0;
  my $word_length = scalar( @{$words} );
  while ( $mm < $word_length ) {
    #/IF word is a pseudo-negation, skips to the next word
    if( @{$words}[$mm] eq '<NEG_PSEUDO>' ) {
      $mm++;
    } elsif ( @{$words}[$mm] eq '<EXP_PRE>' ) {
      #expands window until end of sentence, termination term, or other negation/possible trigger term
      for ( my $o=1; ($mm+$o) < $word_length; $o++ ) {
        if( @{$words}[$mm+$o] =~ /(<EXP_END>|<HIST_EXP_END>|<HYPO_EXP_END>|<EXP_PRE>)/ ) {
          last;
        } else {
          push @{$window}, @{$words}[ $mm+$o ];
        }
        for ( my $w=0; $w < scalar( @{$window} ); $w++ ) {
          if( @{$window}[$w] =~ /$target_word_regex/ ) {
            return 'other';
          }
        }
      }
      $window = [];
      $mm++;
   } else {
      $mm++;
    }
  }
  return "patient";
}

##################################################################################################

$phrase = {
  pseudo => {
    'hypo' => [
      'if negative',
    ],
    'neg' => [
      'gram negative',
      'no change',
      'no definite change',
      'no increase',
      'no interval change',
      'no significant change',
      'no significant interval change',
      'no suspicious change',
      'not cause',
      'not certain if',
      'not certain whether',
      'not drain',
      'not extend',
      'not necessarily',
      'not on',
      'not only',
      'without difficulty',
    ],
    'hist' => [
      'history and',
      'history and examination',
      'history and physical',
      'history for',
      'history of chief complaint',
      'history of present illness',
      'history taking',
      '"history physical"',
      'poor history',
      'social history',
      'sudden onset of',
    ],
  },
  post => {
    'poss' => [
      'be ruled out',
      'being ruled out',
      'can be ruled out',
      'could be ruled out',
      'did not rule out',
      'is to be ruled out',
      'may be ruled out',
      'might be ruled out',
      'must be ruled out',
      'not been ruled out',
      'not ruled out',
      'ought to be ruled out',
      'should be ruled out',
      'will be ruled out',
    ],
    'neg' => [
      'are ruled out',
      'free',
      'has been negative',
      'has been ruled out',
      'have been ruled out',
      'is ruled out',
      'no longer present',
      'non diagnostic',
      'now resolved',
      'prophylaxis',
      'unlikely',
      'was negative',
      'was ruled out',
    ],
  },
  pre => {
    'exp' => [
      'aunt',
      'aunt\'s',
      'brother',
      'brother\'s',
      'dad',
      'dad\'s',
      'family',
      'fam hx',
      'father',
      'father\'s',
      'grandfather',
      'grandfather\'s',
      'grandmother',
      'grandmother\'s',
      'mom',
      'mom\'s',
      'mother',
      'mother\'s',
      'sister',
      'sister\'s',
      'uncle',
      'uncle\'s',
    ],
    'hypo' => [
      'as needed',
      'come back for',
      'come back to',
      'if',
      'return',
      'should he',
      'should she',
      'should the patient',
      'should there',
    ],
    'poss' => [
      'be ruled out for',
      'can be ruled out for',
      'could be ruled out for',
      'is to be ruled out for',
      'may be ruled out for',
      'might be ruled out for',
      'must be ruled out for',
      'ought to be ruled out for',
      'r/o',
      'ro',
      'rule her out',
      'rule her out for',
      'rule him out',
      'rule him out for',
      'rule out',
      'rule out for',
      'rule the patient out',
      'rule the patinet out for',
      'should be ruled out for',
      'what must be ruled out is',
      'will be ruled out for',
    ],
    'neg' => [
      'adequate to rule her out',
      'adequate to rule him out',
      'adequate to rule out',
      'adequate to rule the patient out',
      'any other',
      'as well as any',
      'can rule her out',
      'can rule her out against',
      'can rule her out for',
      'can rule him out',
      'can rule him out against',
      'can rule him out for',
      'can rule out',
      'can rule out against',
      'can rule out for',
      'can rule the patient out',
      'can rule the patinet out against',
      'can rule the patinet out for',
      'cannot',
      'checked for',
      'clear of',
      'declined',
      'declines',
      'denied',
      'denies',
      'denying',
      'did rule her out',
      'did rule her out against',
      'did rule her out for',
      'did rule him out',
      'did rule him out against',
      'did rule him out for',
      'did rule out',
      'did rule out against',
      'did rule out for',
      'did rule the patient out',
      'did rule the patient out against',
      'did rule the patient out for',
      'doesn\'t look like',
      'evaluate for',
      'fails to reveal',
      'free of',
      'inconsistent with',
      'is not',
      'isn\'t',
      'lack of',
      'lacked',
      'negative for',
      'never developed',
      'never had',
      'no',
      'no abnormal',
      'no cause of',
      'no complaints of',
      'no evidence',
      'no evidence to suggest',
      'no findings of',
      'no findings to indicate',
      'no history of',
      'no mammographic evidence of',
      'no new',
      'no new evidence',
      'no other evidence',
      'no radiographic evidence of',
      'no sign of',
      'no significant',
      'no signs of',
      'no suggestion of',
      'no suspicious',
      'not',
      'not appear',
      'not appreciate',
      'not associated with',
      'not complain of',
      'not demonstrate',
      'not exhibit',
      'not feel',
      'not had',
      'not have',
      'not have evidence of',
      'not know of',
      'not known to have',
      'not reveal',
      'not see',
      'not to be',
      'patient was not',
      'rather than',
      'resolved',
      'ruled her out',
      'ruled her out against',
      'ruled her out for',
      'ruled him out',
      'ruled him out against',
      'ruled him out for',
      'ruled out',
      'ruled out against',
      'ruled out for',
      'ruled the patient out',
      'ruled the patient out against',
      'ruled the patient out for',
      'rules her out',
      'rules her out for',
      'rules him out',
      'rules him out for',
      'rules out',
      'rules out for',
      'rules the patient out',
      'rules the patient out for',
      'sufficient to rule her out',
      'sufficient to rule her out against',
      'sufficient to rule her out for',
      'sufficient to rule him out',
      'sufficient to rule him out against',
      'sufficient to rule him out for',
      'sufficient to rule out',
      'sufficient to rule out against',
      'sufficient to rule out for',
      'sufficient to rule the patient out',
      'sufficient to rule the patient out against',
      'sufficient to rule the patient out for',
      'test for',
      'to exclude',
      'unremarkable for',
      'was not',
      'wasn\'t',
      'with no',
      'without',
      'without any evidence of',
      'without evidence',
      'without indication of',
      'without sign of',
    ],
    'hist' => [
      'history',
      'past history',
      'past medical history',
      'previous',
    ],
  },
  end => {
    'exp' => [
      'which',
    ],
    'histexp' => [
      'complains',
      'currently',
      'noted',
      'presenting',
      'presents',
      'reported',
      'reports',
      'states',
      'today',
      'was found',
    ],
    'hypo' => [
      'because',
      'since',
    ],
    'hypoexp' => [
      'her',
      'his',
      'patient',
      'patient\'s',
      'who',
    ],
    'neg' => [
      'although',
      'apart from',
      'as a cause for',
      'as a cause of',
      'as a etiology for',
      'as a etiology of',
      'as a reason for',
      'as a reason of',
      'as a secondary cause for',
      'as a secondary cause of',
      'as a secondary etiology for',
      'as a secondary etiology of',
      'as a secondary origin for',
      'as a secondary origin of',
      'as a secondary reason for',
      'as a secondary reason of',
      'as a secondary source for',
      'as a secondary source of',
      'as a source for',
      'as a source of',
      'as an cause for',
      'as an cause of',
      'as an etiology for',
      'as an etiology of',
      'as an origin for',
      'as an origin of',
      'as an reason for',
      'as an reason of',
      'as an secondary cause for',
      'as an secondary cause of',
      'as an secondary etiology for',
      'as an secondary etiology of',
      'as an secondary origin for',
      'as an secondary origin of',
      'as an secondary reason for',
      'as an secondary reason of',
      'as an secondary source for',
      'as an secondary source of',
      'as an source for',
      'as an source of',
      'as has',
      'as the cause for',
      'as the cause of',
      'as the etiology for',
      'as the etiology of',
      'as the origin for',
      'as the origin of',
      'as the reason for',
      'as the reason of',
      'as the secondary cause for',
      'as the secondary cause of',
      'as the secondary etiology for',
      'as the secondary etiology of',
      'as the secondary origin for',
      'as the secondary origin of',
      'as the secondary reason for',
      'as the secondary reason of',
      'as the secondary source for',
      'as the secondary source of',
      'as the source for',
      'as the source of',
      'aside from',
      'but',
      'cause for',
      'cause of',
      'causes for',
      'causes of',
      'etiology for',
      'etiology of',
      'except',
      'however',
      'nevertheless',
      'origin for',
      'origin of',
      'origins for',
      'origins of',
      'other possibilities of',
      'reason for',
      'reason of',
      'reasons for',
      'reasons of',
      'secondary',
      'secondary to',
      'source for',
      'source of',
      'sources for',
      'sources of',
      'still',
      'though',
      'trigger event for',
      'yet',
    ],
    'hist' => [
      'ED',
      'emergency department',
    ],
  },
};

init();

1;



__END__

=head1 NAME

Lingua::ConText - Perl extension for finding the context of a word in a sentence.

=head1 SYNOPSIS

  use Lingua::ConText qw( applyContext );

   
  my $text = 'The patient denied a history of pneumonia.';
  my $result = applyContext( 'pneumonia', $text );
  print join "\n", @{$result}; 
  # pneumonia
  # The patient denied a history of pneumonia.
  # negated
  # historical
  # patient

=head1 DESCRIPTION


This is a perl implementation of the ConText algorithm which uses a
list of phrases to determine the context of a given concept within
a sentence. 


This is a port from the java code authored by Stephane Meystre, Julien
Charles Thibault, Oscar Ferrandez Escamez made available online.

=head2 EXPORT

None by default.


=head3 applyContext( $concept, $sentence );

  return [ 
    $concept, $sentence, $negation_context, 
    $temporality_context, $experiencer_context 
  ];

  $negation_context; # affirmed, negated, possible
  $temporality_context; # recent, hypothetical, historical
  $experiencer_context; # patient, other

=head1 SEE ALSO

The ConText documentation and downloads for java implementation can be
found here:

http://code.google.com/p/negex/

Background information:


Chapman WW, Dowling JN, Chu DL. ConText: An algorithm for identifying 
contextual features from clinical text. In: BioNLP Workshop of the 
Association for Computational Linguistics Prague, Czech Republic; 2007.
p. 81-88.


Harkema H, Thornblade T, Dowling J, Chapman WW. Portability of ConText:
An Algorithm for determining Negation, Experiencer, and Temporal Status
from Clinical Reports. J Biomed Inform. 2009;42(5):839-851.

http://www.ncbi.nlm.nih.gov/pubmed/21459155

=head1 AUTHOR

Eduardo Iturrate, E<lt>ed@iturrate.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Eduardo Iturrate

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

