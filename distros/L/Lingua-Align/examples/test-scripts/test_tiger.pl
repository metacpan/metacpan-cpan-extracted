#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Corpus::Treebank;
# use Lingua::Align::Corpus::Treebank::TigerXML;


my $corpus = new Lingua::Align::Corpus::Treebank(
    -type => 'tiger',
#     -file => $FindBin::Bin.'/../smultron/SMULTRON_DE_Sophies_World.xml');
    -file => '/storage/tiedeman/projects/SMULTRON/SMULTRON_DE_Sophies_World.xml');


my %tree=();

while ($corpus->next_sentence(\%tree)){
    print $tree{SENTID},"\n";
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

