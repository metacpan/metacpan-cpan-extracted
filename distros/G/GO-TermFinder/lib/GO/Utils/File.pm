package GO::Utils::File;

=head1 NAME

GO::Utils::File - simply utility module for dealing with file parsing

=head1 SYNOPSIS

GO::Utils::File provides a single exported function for retrieving the
lines out of a file, that can be easily reused.

It will simply expect one gene name to exist per line.  It should deal
correctly with Mac and DOS line-endings, and will remove whitespace
from the beginning and end of the names, then return the gene names as
an array.

 use GO::Utils::File qw(GenesFromFile);

 my @genes = GenesFromFile($filename);

=cut

use strict;
use warnings;
use diagnostics;

use IO::File;

use vars qw (@ISA @EXPORT_OK $VERSION);
use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(GenesFromFile);

$VERSION = 0.12;

##########################################################################
sub GenesFromFile{
##########################################################################

=head2 GenesFromFile

GenesFromFile returns an array of gene names that were read from the
supplied file.  It assumes one name per line.

Usage:

    my @genes = GenesFromFile($filename);

=cut

    my $filename = shift;

    my $fh = IO::File->new($filename, q{<} )|| die "Cannot open $filename : $!";

    my @genes;
    my @lines;

    my $var = chr(13); # to deal with Mac end of line 

    while (<$fh>){

	if (/$var/o){ 

	    # if it's a Mac file multiple lines get read at once, so
	    # we have to split on the end-of line character

	    @lines = split($var, $_);

	}else{

	    @lines = ($_);

	}

	foreach my $gene (@lines){

	    $gene =~ s/\cM//g; # remove Control-M characters
	    
	    $gene =~ s/\s+$//; # remove any trailing or leading whitespace
	    $gene =~ s/^\s+//;
	    
	    next unless $gene;
	    
	    push (@genes, $gene);

	}

    }

    $fh->close;

    return @genes;

}

1;

=pod

=head1 AUTHOR

Gavin Sherlock; sherlock@genome.stanford.edu

=cut
