#!/usr/bin/perl

use strict;

use XML::LibXML;

use Getopt::Long;
use Pod::Usage;

my $verbose;
my $help;
my $man;

my $line;
my $i;
my $rep = ".";
my $prefix;
my $base;
my $doc_xml = "";
my @tab_docs_xml;
my $docset;

my $collectionMax;
my @collection;

my $charset = 'UTF-8';

my $xmlhead="<?xml version=\"1.0\" encoding=\"$charset\"?>\n<documentCollection xmlns=\"http://alvis.info/enriched/\" version=\"1.1\">\n";
my $xmlfoot="</documentCollection>\n";

if (scalar(@ARGV) ==0) {
    $help = 1;
}

Getopt::Long::Configure ("bundling");

GetOptions('help|?'     => \$help,
	   'man'        => \$man,
	   'verbose|v'  => \$verbose,
	   'dir|d=s'    => \$rep,
	   'prefix|p:s' => \$prefix,
	   'base|b=s'   => \$base,
	   'size|s=i'   => \$collectionMax,
	   'file|f=s'   => \@collection,
    );

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;


foreach $docset (@collection) {
    $doc_xml = "";
    print STDERR "Reading $docset ... ";
    open DOCSET, $docset;
    
    binmode(DOCSET, ":utf8");
    while($line=<DOCSET>) {
	$doc_xml .= $line;
    }
    close DOCSET;
    print STDERR "done\n";

    print STDERR "Splitting $docset ... ";
    @tab_docs_xml = &split_to_docRecs($doc_xml);
    print STDERR "done\n";

    warn "\t" . scalar(@tab_docs_xml) . " documents split\n";
    warn "\t" . scalar(@tab_docs_xml) . " documents to print\n";

    warn "\tStart at " . ($base+1) . "\n";

    print STDERR "Printing $docset ... ";
    my $j = 0;
    for($i = 0; $i<scalar(@tab_docs_xml); $i++) {

	if ($i % $collectionMax == 0) {
	    open DOCREC, ">$rep/$prefix-" . ($base + $j + 1) . ".xml" or die "No such file\n";
	    binmode(DOCREC, ":utf8");
	    $j++;
	    print DOCREC $xmlhead;
	}

	print DOCREC ${$tab_docs_xml[$i]}[1];
	if (($i + 1) % $collectionMax == 0) {
	    print DOCREC $xmlfoot;
	    close DOCREC;
	}
    }
    if (($i + 1) % $collectionMax != 0) {
	print DOCREC $xmlfoot;
	close DOCREC;
    }
    print STDERR "done\n";
    
    print STDERR "\tLast document number: $i\n\n";
    $base += $i;
}

# print STDERR "Building the $rep/seq file ... ";
# open SEQ, ">$rep/seq";
# print SEQ "0 " . ($base - 1) . "\n";
# close SEQ;
# print STDERR "done\n";



sub split_to_docRecs
{
    my $xml=shift;

    my @recs=();
    
    my $doc;
    my $Parser=XML::LibXML->new();

    eval
    {
	$doc=$Parser->parse_string($xml);
    };
    if ($@)
    {
	warn "Parsing the doc failed: $@. Trying to get the IDs..\n";
	eval
	{
	    $xml=~s/<documentRecord\s(xmlns=[^\s]+)*\sid\s*=\s*\"([^\"]*?)\">/&unparseable_id($2)/esgo;
	};
    }
    else
    {
	if ($doc)
	{
 	    my $root=$doc->documentElement();
	    for my $rec_node ($root->getChildrenByTagName('documentRecord'))
	    {
		my $id=$rec_node->getAttribute("id");
		if (defined($id))
		{
		    $xml=$rec_node->toString();
		    push(@recs,[$id,$xml]);
		}
		else
		{
		    my $rec_str=$rec_node->toString();
		    $rec_str=~s/\n/ /sgo;
		    warn "No id for record $rec_str\n";
		}
	    }
	}
	else
	{
	    my $doc_str=$xml;
	    $doc_str=~s/\n/ /sgo;
	    warn "Parsing the doc failed. Doc: $doc_str\n";
	}
    }

    return @recs;
}

########################################################################

=head1 NAME

splitCollection.pl - Perl script for spliting a collection of XML documents


=head1 SYNOPSIS

splitCollection.pl [--help] [--man] [--rcfile=file] [--lang=lang] [--params=params] [--format=format]

=head1 OPTIONS AND ARGUMENTS

=over 4

=item    B<--help>             brief help message

=item    B<--man>              full documentation

=item    B<--verbose>          go into the verbose mode

=item    B<--file> <fileame>, B<--file> <fileame>   file to split

=item    B<--dir> <dirname>,  B<-d> <dirname>   directory containing the output files (by default, the current directory)

=item    B<--prefix> <prefix>, B<-p> <prefix>  prefix of the output filenames

=item    B<--base> <number>, B<-b> <number>    start number of the output filenames

=item    B<--size> <size>, B<-s> <size>      number of documents per output file

=back

=head1 DESCRIPTION

The script splits a document collection in ALVIS XML format into
several files in the same format. The ALVIS XML format is the format
used by the Ogmios platform to load file and record linguistic
annotations.

Intput file is given by the option C<--file>.  Output files are stored
in a directory specified with the option C<--dir>. Each output file
has the prefix indicated by the option C<--prefix>.

=head1 EXAMPLE

SplitCollection.pl -f examples/twodocs.xml -d examples -p subcoll -b 1 -s 1

=head1 AUTHOR

Thierry Hamon, E<lt>thierry.hamon@limsi.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 Thierry Hamon

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.4 or, at your
option, any later version of Perl 5 you may have available.

=cut

