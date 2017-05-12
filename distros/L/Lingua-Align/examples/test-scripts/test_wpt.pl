#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Corpus::Parallel::WPT;

my $alg=$FindBin::Bin.'/../europarl/wpt03/test.wa.nonullalign';
my $src=$FindBin::Bin.'/../europarl/wpt03/test.f';
my $trg=$FindBin::Bin.'/../europarl/wpt03/test.e';

my $corpus = new Lingua::Align::Corpus::Parallel::WPT(
    -alignfile => $alg,
    -src_file => $src,
    -src_encoding => 'iso-8859-1',
    -trg_file => $trg,
    -trg_encoding => 'iso-8859-1');


my %srctree=();
my %trgtree=();
my %links=();

while ($corpus->next_alignment(\%srctree,\%trgtree,\%links)){
    foreach my $s (keys %links){
	foreach my $t (keys %{$links{$s}}){
	    print "$s:$t ($links{$s}{$t})\n";
	}
    }
    print "====================================================\n";
}

