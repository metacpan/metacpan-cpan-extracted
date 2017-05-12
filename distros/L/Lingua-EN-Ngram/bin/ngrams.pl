#!/usr/bin/perl

# ngrams.pl - count and display the most frequent ngrams in a text

# Eric Lease Morgan <eric_morgan@infomotions.com>
# August    28, 2010 - first cut; for a blog posting
# August    29, 2010 - tweeked to accept command-line input
# September 12, 2010 - tweaked for use by Lingua::EN::Ngram


# denote the number of ngrams to display; season to taste
use constant LENGTH => 10;

# require
use lib '../lib';
use Lingua::EN::Ngram;
use strict;

# sanity check
my $file = $ARGV[ 0 ];
my $size = $ARGV[ 1 ];
if ( ! $file or ! $size ) {

	print "Usage: $0 <file> <integer>\n";
	exit;
	
}

# initialize and count ngrams
my $ngram = Lingua::EN::Ngram->new( file => $file );
my $ngrams = $ngram->ngram( $size );

# process all the ngrams
my $index = 0;
foreach my $phrase ( sort { $$ngrams{ $b } <=> $$ngrams{ $a } } keys %$ngrams ) {
	
	# check for punctuation in each token of phrase
	my $found = 0;
	foreach ((split / /, $phrase )) {
	
		if ( $_ =~ /[,.?!:;()\-]/ ) {
		
			$found = 1;
			last;
			
		}
		
	}
	
	# don't want found tokens
	next if ( $found );
	
	# increment; only want LENGTH phrases displayed
	$index++;
	last if ( $index > LENGTH );
	
	# don't want single frequency phrases
	last if ( $$ngrams{ $phrase } == 1 );
	
	# echo
	print $$ngrams{ $phrase }, "\t$phrase\n";
	
}

# done
exit;
