#!/usr/bin/perl

=head1 NAME

MetaMapDataStructures.pl - This program provides an example of using the 
    data structures in MetaMap::DataStructures

=head1 SYNOPSIS

This program provides an example of using the data structures in 
MetaMap::DataStructures

=head1 USAGE

Usage: MetaMapDataStructures.pl [OPTIONS] [OUTPUT FILE] [INPUT FILE]

=head1 INPUT FILE

=head2 FILE

File containing machine readable (-q) MetaMap mapped text 

=head1 OUTPUT FILE

=head2 FILE

File containing exampel output 

=head1 OPTIONS

Optional command line arguements

=head2 Options:

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head3 --debug

Sets the debug flag on for testing

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=back

=head1 CONTACT US
   
  If you have any trouble installing and using UMLS-Similarity, 
  please contact us: 

      Sam Henry : henryst at vcu.edu

=head1 AUTHOR

 Sam Henry, , Virginia Commonwealth University 
 Bridget T. McInnes, Virginia Commonwealth University 

=head1 COPYRIGHT

Copyright (c) 2016

 Sam Henry, Virginia Commonwealth University
 henryst at vcu.edu

 Bridget T. McInnes, Virginia Commonwealth University
 btmcinnes at vcu.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################
#                               THE CODE STARTS HERE
###############################################################################

use Getopt::Long;
use MetaMap::DataStructures; 


eval(GetOptions( "version", "help", "debug")) 
    or die ("Please check the above mentioned option(s).\n");


#  if help is defined, print out help
if( defined $opt_help ) {    
    $opt_help = 1;
    &showHelp();
    exit;
}

#  if version is requested, show version
if( defined $opt_version ) {
    $opt_version = 1;
    &showVersion();
    exit;
}
# At least 2 terms should be given on the command line.
if( (scalar(@ARGV) < 2) ) {
    print STDERR "The output and input file should be given on the \n";
    print STDERR "command line.\n";
    &minimalUsageNotes();
    exit;
}

my %params = (); 

if(defined $opt_debug) { 
    $params{"debug"} = 1; 
}

my $datastructures = MetaMap::DataStructures->new(\%params); 

my $outFileName = shift; 
my $inFileName = shift; 

#open test input
open (IN, $inFileName) || die "Coudn't open the input file: $inFileName\n";

#create Output
open (OUT, ">$outFileName") ||  die "Could not open output file: $outFileName\n";

#read each utterance
my $input = '';
print STDERR "Reading Input\n";
while(<IN>) {
    #build a string until the utterance has been read in
    chomp $_;
    $input .= $_;
    if ($_ eq "\'EOU\'.") {
	$datastructures->createFromText($input); 
	$input = '';
    }
}

my $citations = $datastructures->getCitations(); 

print OUT  "\n\n---------  Citations Results  ----------------\n\n"; 
print OUT  "numCitations = ".(scalar keys %{$citations})."\n";
print OUT  "begin listing citations:\n";
print OUT "---------------------------------------------------------------\n\n";
foreach my $key (keys %{$citations}) {

    my $citation = ${$citations}{$key};

    print OUT  "PMID = $citation->{id}\n";
    
    print OUT  "-------------Utterances-----------------------\n";
    my $utterancesRef = $citation->getOrderedUtterances();
    foreach my $utterance(@{ $utterancesRef }) {
	print OUT  $utterance->{id}."*";
    }
    print OUT  "\n";

    print OUT  "-------------Tokens-----------------------\n";
    my $tokensRef = $citation->getOrderedTokens();
    foreach my $token(@{ $tokensRef }) {
	print OUT  $token->{text}.'*';
    }
    print OUT  "\n";
    print OUT  "-------------Concepts-----------------------\n";
    my $conceptsListsRef = $citation->getOrderedConcepts();
    foreach my $conceptListRef(@{ $conceptsListsRef }) {
	foreach my $concept(@{ $conceptListRef }) {
	    print OUT  $concept->{text}.'*';
	}
	print OUT  "\n";
    }
    print OUT  "\n";
    print OUT  "-------------Unique Concepts-----------------------\n";
    my %uniqueConcepts = %{ $citation->getUniqueConcepts() };
    print OUT "Number of unique Concepts = ".(scalar keys %uniqueConcepts)."\n";
    foreach my $key(keys %uniqueConcepts) {
	print OUT  "$key - $uniqueConcepts{$key}->{text}\n";
    }
    print OUT  "--------------- Mappings ---------------------\n";
    my $mappingsRef = $citation->getOrderedMappings();
    foreach my $mapping(@{ $mappingsRef }) {
	print OUT  "|";
	foreach my $c(@{ $mapping->{concepts} }) {
	    my $text = $c->{text};
	    print OUT  "*$text";
	}
	print OUT  "|\n";
    }
    print OUT  "\n";

    print OUT  "-------------Other-----------------------\n";
    print OUT  "Citation has title? - ".$citation->hasTitle()."\n";
    print OUT  "Citation has abstract? - ".$citation->hasAbstract()."\n";
    print OUT  "Citation Title: ";
    $tokensRef = $citation->getTitle()->getOrderedTokens();
    foreach my $token(@{$tokensRef}) {
	print OUT  $token->{text}.'*';
    }
    print OUT  "\n";
    print OUT  "Citation Abstract: ";
    $tokensRef = $citation->getAbstract()->getOrderedTokens();
    foreach my $token(@{$tokensRef}) {
	print OUT  $token->{text}.'*';
    }
    print OUT  "\n";

    print OUT  "--------------  Final Other --------------------\n";
    my $conceptsRef = $citation->getConcepts();
    print OUT  "Citation equals itself?: ".$citation->equals($citation)."\n";
    print OUT  "Citation equals its title?: ".$citation->equals($citation->getTitle())."\n";
    print OUT  "Citation equals its abstract?: ".$citation->equals($citation->getAbstract())."\n";
    print OUT  "Citation contains one of its own concepts?: ".($citation->contains(${$conceptsRef}[0]->{cui}))."\n";
    print OUT  "Citation contains a concept that it doesn't contain?: ".$citation->contains('1')."\n";

    print OUT  "\nUtterance toStrings\n";
    $utterancesRef = $citation->getOrderedUtterances();
    foreach my $utterance(@{$utterancesRef}) {
	print OUT  $utterance->toString();
    }
    
    print OUT  "\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n\n";

}

print STDERR "DONE!, results written to $outFileName\n";

    
##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: MetaMapDataStructures.pl [OPTIONS] OUTPUTFILE INPUTFILE\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input ... \n\n";

    print "Usage: MetaMapDataStructures.pl [OPTIONS] OUTPUTFILE INPUTFILE\n\n";

    print "Options:\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

    print "--debug                  Prints debug information for\n";
    print "                         testing purposes\n\n"; 
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: MetaMapDataStructures.pl,v 1.113 2015/06/24 19:25:05 btmcinnes Exp $';
    print "\nCopyright (c) 2016, Sam Henry & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type MetaMapDataStructures.pl --help for help.\n";
}
    
