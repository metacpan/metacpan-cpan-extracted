#!/usr/bin/perl

use lib qw( lib );
use strict;

use Encode qw( from_to );

use Getopt::Long;

my $VERBOSE = 1;
my $infile;

GetOptions(
    'infile|i=s' => \$infile,
    'verbose|v=s' => \$VERBOSE,
);
die "Usage ./koi8-rto-utf8.pl --infile=path"
    unless ($infile && -f $infile);

my $outfile = $infile . '.utf8';

print "convert $infile to $outfile \n" if $VERBOSE;

open( my $in_fh, "<", $infile)
    or die "Couldn't open infile '$infile': $!";

open(my $out_fh, ">", $outfile)
    or die "Couldn't open outfile '$outfile': $!";

my $source_enc = 'koi8-r';

while (my $line = <$in_fh>) {
    from_to($line, $source_enc, 'UTF-8');
    print $out_fh $line unless $VERBOSE;
}

close($in_fh);
close($out_fh);

