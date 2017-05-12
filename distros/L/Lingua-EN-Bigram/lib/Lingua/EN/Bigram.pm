package Lingua::EN::Bigram;

# Bigram.pm - Extract n-grams from a text and list them according to frequency and/or T-Score

# Eric Lease Morgan <eric_morgan@infomotions.com>
# June   18, 2009 - first investigations
# June   19, 2009 - "finished" POD
# August 22, 2010 - added trigrams and quadgrams; can I say "n-grams"?
# August 23, 2010 - yes, I can say n-gram


# include
use strict;
use warnings;

# define
our $VERSION = '0.03';


sub new {

	# get input
	my ( $class ) = @_;
	
	# initialize
	my $self = {};
		
	# return
	return bless $self, $class;
	
}


sub text {

	# get input
	my ( $self, $text ) = @_;
	
	# set
	if ( $text ) { $self->{ text } = $text }
	
	# return
	return $self->{ text };
	
}


sub words {

	# get input
	my ( $self ) = shift;

	# parse
	my $text = $self->text;
	$text =~ tr/a-zA-Z'()\-,.?!;:/\n/cs;
	$text =~ s/([,.?!:;()\-])/\n$1\n/g;
	$text =~ s/\n+/\n/g;
	
	# done
	return split /\n/, lc( $text );

}


sub word_count {

	# get input
	my ( $self ) = shift;

	# initialize
	my @words      = $self->words;
	my %word_count = ();
	
	# do the work
	for ( my $i = 0; $i <= $#words; $i++ ) { $word_count{ $words[ $i ] }++ }

	# done
	return \%word_count;
	
}


sub bigrams {

	# get input
	my ( $self ) = shift;
	
	# done
	return $self->ngram( 2 );

}


sub bigram_count {

	# get input
	my ( $self ) = shift;

	# initialize
	my @words        = $self->words;
	my @bigrams      = $self->bigrams;
	my %bigram_count = ();
	
	# do the work
	for ( my $i = 0; $i < $#words; $i++ ) { $bigram_count{ $bigrams[ $i ] }++ }
	
	# done
	return \%bigram_count;

}


sub tscore {

	# get input
	my ( $self ) = shift;
	
	# initialize
	my @words        = $self->words;
	my $word_count   = $self->word_count;
	my @bigrams      = $self->bigrams;
	my $bigram_count = $self->bigram_count;

	# calculate t-score
	my %tscore = ();
	for ( my $i = 0; $i < $#words; $i++ ) {

		$tscore{ $bigrams[ $i ] } = ( $$bigram_count{ $bigrams[ $i ] } - 
	                                  $$word_count{ $words[ $i ] } * 
	                                  $$word_count{ $words[ $i + 1 ] } / 
	                                  ( $#words + 1 ) ) / 
	                                  sqrt( $$bigram_count{ $bigrams[ $i ] }
	                                );

	}
	
	# done
	return \%tscore;
	
}


sub trigrams {
	
	# get input
	my ( $self ) = shift;

	# done
	return $self->ngram( 3 );

}


sub trigram_count {

	# get input
	my ( $self ) = shift;

	# initialize
	my @words         = $self->words;
	my @trigrams      = $self->trigrams;
	my %trigram_count = ();
	
	# do the work
	for ( my $i = 0; $i < $#words; $i++ ) { $trigram_count{ $trigrams[ $i ] }++ }
	
	# done
	return \%trigram_count;

}


sub quadgrams {
	
	# get input
	my ( $self ) = shift;

	# done
	return $self->ngram( 4 );

}


sub quadgram_count {

	# get input
	my ( $self ) = shift;

	# initialize
	my @words          = $self->words;
	my @quadgrams      = $self->quadgrams;
	my %quadgram_count = ();
	
	# do the work
	for ( my $i = 0; $i < $#words; $i++ ) { $quadgram_count{ $quadgrams[ $i ] }++ }
	
	# done
	return \%quadgram_count;

}


sub ngram {

	# get input
	my ( $self, $n ) = @_;

	# sanity check
	if ( ! $n ) { die "This method -- ngram -- requires an integer as an argument." }
	if ( $n =~ /\D/ ) { die "This method -- ngram -- requires an integer as an argument." }
	
	# initialize
	no warnings;
	my @words  = $self->words;
	my @ngrams = ();
	
	# process each word
	for ( my $i = 0; $i < $#words; $i++ ) {
	
		# repeat n number of times
		my $tokens = '';
		for ( my $j = $i; $j < $i + $n; $j++ ) { $tokens .= $words[ $j ] . ' ' }
		
		# remove the trailing space
		chop $tokens;
		
		# build the ngram
		$ngrams[ $i ] = $tokens;
		
	}
	
	# done
	return @ngrams;

}


sub ngram_count {

	# get input
	my ( $self, $ngrams ) = @_;

	# sanity check
	if ( ref( $ngrams ) ne 'ARRAY' ) { die "This method -- ngram_count -- requires you pass it a reference to an array." }
	
	# initialize
	no warnings;
	my @words       = $self->words;
	my %ngram_count = ();
	
	# do the work
	for ( my $i = 0; $i < $#words; $i++ ) { $ngram_count{ $$ngrams[ $i ] }++ }
	
	# done
	return \%ngram_count;

}


=head1 NAME

Lingua::EN::Bigram - Extract n-grams from a text and list them according to frequency and/or T-Score


=head1 SYNOPSIS

  # initalize
  use Lingua::EN::Bigram;
  $ngrams = Lingua::EN::Bigram->new;
  $ngrams->text( 'All men by nature desire to know. An indication of this...' );

  # calculate t-score for bigrams; t-score is only available for bigrams
  $tscore = $ngrams->tscore;
  foreach ( sort { $$tscore{ $b } <=> $$tscore{ $a } } keys %$tscore ) {

    print "$$tscore{ $_ }\t" . "$_\n";

  }

  # list trigrams according to frequency
  @trigrams = $ngrams->ngram( 3 );
  $count = $ngrams->ngram_count( \@trigrams );
  foreach my $trigram ( sort { $$count{ $b } <=> $$count{ $a } } keys %$count ) {

    print $$count{ $trigram }, "\t$trigram\n";

  }


=head1 DESCRIPTION

This module is designed to: 1) pull out all of the ngrams (multi-word phrases) in a given text, and 2) list these phrases according to their frequency. Using this module is it possible to create lists of the most common phrases in a text as well as order them by their statistical occurance, thus implying significance. This process is useful for the purposes of textual analysis and "distant reading".


=head1 METHODS


=head2 new

Create a new, empty Lingua::EN::Bigram object:

  # initalize
  $ngrams = Lingua::EN::Bigram->new;


=head2 text

Set or get the text to be analyzed:

  # fill Lingua::EN::Bigram object with content 
  $ngrams->text( 'All good things must come to an end...' );

  # get the Lingua::EN::Bigram object's content 
  $text = $ngrams->text;


=head2 words

Return a list of all the tokens in a text. Each token will be a word or puncutation mark:

  # get words
  @words = $ngrams->words;


=head2 word_count

Return a reference to a hash whose keys are a token and whose values are the number of times the token occurs in the text:

  # get word count
  $word_count = $ngrams->word_count;

  # list the words according to frequency
  foreach ( sort { $$word_count{ $b } <=> $$word_count{ $a } } keys %$word_count ) {

    print $$word_count{ $_ }, "\t$_\n";

  }


=head2 bigrams

Return a list of all bigrams in the text. Each item will be a pair of tokens and the tokens may consist of words or puncutation marks:

  # get bigrams
  @bigrams = $ngrams->bigrams;

This is a convienience method for the ngram method, described below. It is identical to $ngrams->ngram( 2 ). In fact, that is exactly what is called within the module itself.


=head2 bigram_count

Return a reference to a hash whose keys are a bigram and whose values are the frequency of the bigram in the text:

  # get bigram count
  $count = $ngrams->bigram_count;

  # list the bigrams according to frequency
  foreach ( sort { $$count{ $b } <=> $$count{ $a } } keys %$count ) {

    print $$count{ $_ }, "\t$_\n";

  }


=head2 tscore

Return a reference to a hash whose keys are a bigram and whose values are a T-Score -- a probabalistic calculation determining the significance of the bigram occuring in the text:

  # get t-score
  $tscore = $ngrams->tscore;

  # list bigrams according to t-score
  foreach ( sort { $$tscore{ $b } <=> $$tscore{ $a } } keys %$tscore ) {

	  print "$$tscore{ $_ }\t" . "$_\n";

  }

T-Score can only be computed against bigrams.


=head2 trigrams

Return a list of all trigrams (three-word phrases) in the text. Each item will include three tokens and the tokens may consist of words or puncutation marks:

  # get trigrams
  @trigrams = $ngrams->trigrams;

This is a convienience method for the ngram method, described below. It is identical to $ngrams->ngram( 3 ). In fact, that is exactly what is called within the module itself.


=head2 trigram_count

Return a reference to a hash whose keys are a trigram and whose values are the frequency of the trigram in the text:

  # get trigram count
  $count = $ngrams->trigram_count;

  # list the trigrams according to frequency
  foreach ( sort { $$count{ $b } <=> $$count{ $a } } keys %$count ) {

    print $$count{ $_ }, "\t$_\n";

  }


=head2 quadgrams

Return a list of all quadgrams (four-word phrases) in the text. Each item will include four tokens and the tokens may consist of words or puncutation marks:

  # get quadgrams
  @quadgrams = $ngrams->quadgrams;

This is a convienience method for the ngram method, described below. It is identical to $ngrams->ngram( 4 ). In fact, that is exactly what is called within the module itself.


=head2 quadgram_count

Return a reference to a hash whose keys are a quadgram and whose values are the frequency of the quadgram in the text:

  # get quadgram count
  $count = $ngrams->quadgram_count;

  # list the trigrams according to frequency
  foreach ( sort { $$count{ $b } <=> $$count{ $a } } keys %$count ) {

    print $$count{ $_ }, "\t$_\n";

  }


=head2 ngram

Return a list of ngrams where the length of each ngram is denoted by the method's parameter:

  # create a list of trigrams
  @trigrams = $ngrams->ngram( 3 );
  
This method requires a single parameter and that parameter must be an integer.


=head2 ngram_count

Given a reference to an array, return a reference to a hash whose keys are an ngram and whose values are the frequency of the ngram in the text:

  # count ngram frequency
  $counts = $ngrams->ngram_count( \@trigrams );
  foreach ( sort { $$counts{ $b } <=> $$counts{ $a } } keys %$counts ) {

    print $$counts{ $_ }, "\t$_\n";
	
  }


=head1 DISCUSSION

Given the increasing availability of full text materials, this module is intended to help "digital humanists" apply mathematical methods to the analysis of texts. For example, the developer can extract the high-frequency words using the word_count method and allow the user to search for those words in a concordance. The bigram_count method simply returns the frequency of a given bigram, but the tscore method can order them in a more finely tuned manner.

Consider using T-Score-weighted bigrams as classification terms to supplement the "aboutness" of texts. Concatonate many texts together and look for common phrases written by the author. Compare these commonly used phrases to the commonly used phrases of other authors.

Each bigram, trigram, quadgram, or ngram includes punctuation. This is intentional. Developers may need want to remove bigrams, trigrams, quadgrams, or ngrams containing such values from the output. Similarly, no effort has been made to remove commonly used words -- stop words -- from the methods. Consider the use of Lingua::StopWords, Lingua::EN::StopWords, or the creation of your own stop word list to make output more meaningful. The distribution came with a script (bin/ngrams.pl) demonstrating how to remove puncutation and stop words from the displayed output.

Finally, this is not the only module supporting bigram extraction. See also Text::NSP which supports n-gram extraction.


=head1 TODO

There are probably a number of ways the module can be improved:

=over

* the constructor method could take a scalar as input, thus reducing the need for the text method

* the distribution's license should probably be changed to the Perl Aristic License

* the addition of alternative T-Score calculations would be nice

* make sure the module works with character sets beyond ASCII

=back


=head1 CHANGES

=over

* August 23, 2010 (version 0.03) - added ngram and ngram_counts methods

* August 22, 2010 (version 0.02) - added trigrams and quadgrams; tweaked documentation; removed bigrams.pl from  the distribution and substituted it wih n-grams.pl

* June 19, 2009 (version 0.01) - initial release

=back

=head1 ACKNOWLEDGEMENTS

T-Score, as well as a number of the module's methods, is calculated as per Nugues, P. M. (2006). An introduction to language processing with Perl and Prolog: An outline of theories, implementation, and application with special consideration of English, French, and German. Cognitive technologies. Berlin: Springer.


=head1 AUTHOR

Eric Lease Morgan <eric_morgan@infomotions.com>

=cut

# return true or die
1;
