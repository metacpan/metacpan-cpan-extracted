#!/usr/bin/perl

# intersections.pl - extract and count the common ngrams from two texts

# Eric Lease Morgan <eric_morgan@infomotions.com>
# September 11, 2010 - first investigations
# September 12, 2010 - made it more general


# configure
use constant TEXTONE => '../etc/walden.txt';
use constant TEXTTWO => '../etc/rivers.txt';
use constant LENGTH  => 10;

# require
use lib '../lib';
use strict;
use Lingua::EN::Ngram;

# get input and sanity check
my $length = $ARGV[ 0 ];
if ( ! $length ) {

	print "Usage: $0 <integer>\n";
	exit;
	
}


# build corpus
my $textone = Lingua::EN::Ngram->new( file => TEXTONE );
my $texttwo = Lingua::EN::Ngram->new( file => TEXTTWO );
my $corpus  = Lingua::EN::Ngram->new;

# calculate intersections
my $intersections = $corpus->intersection( corpus => [ ( $textone, $texttwo ) ], length => $length );

# process each intersection
print 'Top ', LENGTH, " $length-gram phrases common to both ", TEXTONE, ' and ', TEXTTWO, ":\n";
my $index = 0;
foreach ( sort { $$intersections{ $b } <=> $$intersections{ $a }} keys %$intersections ) {

	# skip punctuation
	next if ( $_ =~ /[,.?!:;()\-]/ );
	next if ( $_ =~ /^'/ or $_ =~ /' / );
	
	# increment
	$index++;
	last if ( $index > LENGTH );
	
	# print summary
	print $$intersections{ $_ }, "\t$_\n";
	
}

# done
exit;


