#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Lingua::Align::Corpus::Parallel::Giza;


my $bitext = new Lingua::Align::Corpus::Parallel::Giza(
    -alignfile => 'moses/giza.src-trg/src-trg.A3.final.gz',
    -encoding => 'utf8');

my @src=();
my @trg=();
my %links=();

while ($bitext->next_alignment(\@src,\@trg,\%links)){
    print '';
    %links=();
}
