#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Corpus::Parallel::Dublin;
use Lingua::Align::Corpus::Treebank;

my $corpus = 
    new Lingua::Align::Corpus::Parallel::Dublin(-alignfile => $ARGV[0]);
my $trees = new Lingua::Align::Corpus::Treebank;

my %srctree=();
my %trgtree=();
my $links;

while ($corpus->next_alignment(\%srctree,\%trgtree,\$links)){
    foreach my $s (keys %{$links}){
	foreach my $t (keys %{$$links{$s}}){
	    my @src = $trees->get_leafs(\%srctree,$s);
	    my @trg = $trees->get_leafs(\%trgtree,$t);
	    print join (' ',@src);
	    print ' <-> ';
	    print join (' ',@trg);
	    print " ($s:$t)\n";
	}
    }
    print "====================================================\n";
}

