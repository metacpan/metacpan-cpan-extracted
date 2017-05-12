#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Corpus::Parallel::Moses;


my $bitext = new Lingua::Align::Corpus::Parallel::Moses(
	-alignfile => 'moses/model/aligned.grow-diag-final-and');

my @src=();
my @trg=();
my %links=();

while ($bitext->next_alignment(\@src,\@trg,\%links)){
    print '';
    %links=();
}
