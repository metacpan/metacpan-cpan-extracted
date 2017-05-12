#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Corpus::Parallel::STA;

my $corpus = new Lingua::Align::Corpus::Parallel::STA(-alignfile => $ENV{HOME}.'/projects/SMULTRON/Alignments_SMULTRON_Sophies_World_DE_EN.xml');


my %srctree=();
my %trgtree=();
my $links;

while ($corpus->next_alignment(\%srctree,\%trgtree,\$links)){
    my %links = $corpus->get_links(\%srctree,\%trgtree);
    foreach my $s (keys %{$links}){
	foreach my $t (keys %{$links{$s}}){
	    print "$s:$t ($links{$s}{$t})\n";
	}
    }
    print "====================================================\n";
}

