#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';


# use Lingua::Align::Corpus::Treebank::AlpinoXML;
use Lingua::Align::Corpus::Treebank;



# my $corpus = new Lingua::Align::Corpus::Treebank::TigerXML(
#     -file => $ENV{HOME}.'/projects/SMULTRON/SMULTRON_DE_Sophies_World.xml');

my $corpus = new Lingua::Align::Corpus::Treebank(
    -type => 'alpino',
    -file => $FindBin::Bin.'/../europarl/ep-00-01-17.data.dz');


my %tree=();

while ($corpus->next_sentence(\%tree)){
    print $tree{ID},"\n";
    foreach my $nid (keys %{$tree{NODES}}){
	my @inside = $corpus->get_leafs(\%tree,$nid);
	my @outside = $corpus->get_outside_leafs(\%tree,$nid);
	print "  <node $nid>\n    inside leafs = ";
	print join(' ',@inside);
	print "\n    outside leafs = ";
	print join(' ',@outside);
	print "\n";
    }
    print "====================================================\n";
}

