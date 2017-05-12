#!/usr/bin/perl

use Test::More tests =>2; 

use File::Spec;
use File::Path;

use MetaMap::DataStructures; 

my %params = (); 
my $datastructures = MetaMap::DataStructures->new(\%params); 

ok($datastructures);

#  set the input/outputfile
my $outFileName  = File::Spec->catfile('t','output','sample.out');
my $inFileName = File::Spec->catfile('t','input', 'sample.txt');
my $keyFileName = File::Spec->catfile('t','key', 'sample.key');

#  remove the output file if it exists
File::Path->remove_tree($outFileName);

#open test input
open (IN, $inFileName) || die "Coudn't open the input file: $inFileName\n";

#create Output
open (OUT, ">$outFileName") ||  die "Could not open output file: $outFileName\n";

#read each utterance
my $input = '';

while(<IN>) {
    #build a string until the utterance has been read in
    chomp $_;
    $input .= $_;
    if ($_ eq "\'EOU\'.") {
	$datastructures->createFromText($input); 
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
    foreach my $key(sort keys %uniqueConcepts) {
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
close OUT;

my $output = "";
open(OUTPUT, $outFileName) || die "Could not open outputfile $outFileName\n";
while(<OUTPUT>) { $output .= $_; } close OUTPUT;

my $key = ""; 
open(KEY, $keyFileName) || die "Could not open keyfile $keyFileName\n";
while(<KEY>) { $key .= $_; } close KEY; 

cmp_ok($output, 'eq', $key);

#  remove output file
File::Path->remove_tree($outFileName);
