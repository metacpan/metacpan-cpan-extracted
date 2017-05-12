#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Formatter::HTML::MPS;
use Getopt::Std;

my %options = ();
getopt( 'd:', \%options );

if ( @ARGV != 1 ) {
    usage();
    exit 0;
}


# Open MPS file:
open my $fh, '<', $ARGV[0] or confess $!;

# Generate:
my $formatter = Formatter::HTML::MPS->format( join( '', <$fh> ) );
my $output = $formatter->document();

# Output to file in directory if specified, STDOUT if not:
if ( exists $options{d} ) {
    open $fh, '>', $options{d}.'/index.html' or confess $!;
    print $fh $output;
}
else {
    print $output;
}


sub usage {
    print "Usage: mpslidemaker.pl [OPTIONS] <file.mps>\n\n";
    print "OPTIONS:\n";
    print "\t-d <directory>\tSpecify output directory.\n";
    print "\n";
}





