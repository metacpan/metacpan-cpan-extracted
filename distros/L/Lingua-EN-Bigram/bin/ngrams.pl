#!/usr/bin/perl

# n-grams.pl - list top 10 bi-grams from a text ordered by tscore, and
#              list top 10 tri-grams, 4-grams, and 10-grams ordered by number of occurances

# Eric Lease Morgan <eric_morgan@infomotions.com>
# June   18, 2009 - first implementation
# June   19, 2009 - tweaked
# August 22, 2009 - added tri-grams and 4-grams
# August 23, 2009 - added n-grams; wow!


# require
use lib '../lib';
use Lingua::EN::Bigram;
use Lingua::StopWords qw( getStopWords );
use strict;

# initialize
my $stopwords = &getStopWords( 'en' );

# sanity check
my $file = $ARGV[ 0 ];
if ( ! $file ) {

	print "Usage: $0 <file>\n";
	exit;
	
}

# slurp
open F, $file or die "Can't open input: $!\n";
my $text = do { local $/; <F> };
close F;

# build n-grams
my $ngrams = Lingua::EN::Bigram->new;
$ngrams->text( $text );

# get bi-gram counts
my $bigram_count = $ngrams->bigram_count;
my $tscore       = $ngrams->tscore;

# display top ten bi-grams, sans stop words and punctuation
my $index = 0;
print "Bi-grams (T-Score, count, bi-gram)\n";
foreach my $bigram ( sort { $$tscore{ $b } <=> $$tscore{ $a } } keys %$tscore ) {

	# get the tokens of the bigram
	my ( $first_token, $second_token ) = split / /, $bigram;
	
	# skip stopwords and punctuation
	next if ( $$stopwords{ $first_token } );
	next if ( $first_token =~ /[,.?!:;()\-]/ );
	next if ( $$stopwords{ $second_token } );
	next if ( $second_token =~ /[,.?!:;()\-]/ );
	
	# increment
	$index++;
	last if ( $index > 10 );

	# output
	print "$$tscore{ $bigram }\t"           . 
	      "$$bigram_count{ $bigram }\t"     . 
	      "$bigram\t\n";

}
print "\n";


# get and process the first top 10 tri-gram counts
my $trigram_count = $ngrams->trigram_count;
$index = 0;
print "Tri-grams (count, tri-gram)\n";
foreach my $trigram ( sort { $$trigram_count{ $b } <=> $$trigram_count{ $a } } keys %$trigram_count ) {

	# get the tokens of the ngram
	my ( $first_token, $second_token, $third_token ) = split / /, $trigram;
	
	# skip punctuation
	next if ( $first_token  =~ /[,.?!:;()\-]/ );
	next if ( $second_token =~ /[,.?!:;()\-]/ );
	next if ( $third_token  =~ /[,.?!:;()\-]/ );

	# skip stopwords; results are often more interesting if these are commented out
	#next if ( $$stopwords{ $first_token } );
	#next if ( $$stopwords{ $second_token } );
	#next if ( $$stopwords{ $third_token } );
	
	# increment
	$index++;
	last if ( $index > 10 );
	
	# echo
	print $$trigram_count{ $trigram }, "\t$trigram\n";
	
}
print "\n";


# get and process the first top 10 10-gram counts
my @ten_grams = $ngrams->ngram( 10 );
my $ten_grams_counts = $ngrams->ngram_count( \@ten_grams );
$index = 0;
print "10_grams (count, 10-gram)\n";
foreach my $ten_gram ( sort { $$ten_grams_counts{ $b } <=> $$ten_grams_counts{ $a } } keys %$ten_grams_counts ) {

	# get the tokens of the ngram
	my ( $first_token, $second_token, $third_token, $fourth_token, $fifth_token, $sixth_token, $seventh_token, $eight_token, $ninth_token, $tenth_token ) = split / /, $ten_gram;
	
	# skip punctuation
	next if ( $first_token   =~ /[,.?!:;()\-]/ );
	next if ( $second_token  =~ /[,.?!:;()\-]/ );
	next if ( $third_token   =~ /[,.?!:;()\-]/ );
	next if ( $fourth_token  =~ /[,.?!:;()\-]/ );
	next if ( $fifth_token   =~ /[,.?!:;()\-]/ );
	next if ( $sixth_token   =~ /[,.?!:;()\-]/ );
	next if ( $seventh_token =~ /[,.?!:;()\-]/ );
	next if ( $eight_token   =~ /[,.?!:;()\-]/ );
	next if ( $ninth_token   =~ /[,.?!:;()\-]/ );
	next if ( $tenth_token   =~ /[,.?!:;()\-]/ );

	# skip stopwords; results are often more interesting if these are commented out
	#next if ( $$stopwords{ $first_token } );
	#next if ( $$stopwords{ $second_token } );
	#next if ( $$stopwords{ $third_token } );
	#next if ( $$stopwords{ $fourth_token } );
	#next if ( $$stopwords{ $fifth_token } );
	#next if ( $$stopwords{ $sixth_token } );
	#next if ( $$stopwords{ $seventh_token } );
	#next if ( $$stopwords{ $eight_token } );
	#next if ( $$stopwords{ $ninth_token } );
	#next if ( $$stopwords{ $tenth_token } );
	
	# increment
	$index++;
	last if ( $index > 10 );
	
	# echo
	print $$ten_grams_counts{ $ten_gram }, "\t$ten_gram\n";
	
}
print "\n";


# done
exit;

