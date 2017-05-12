#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

my $EP_OPUS=$ENV{HOME}.'/projects/OPUS/corpus/Europarl3';
my $EP_PACO=$ENV{HOME}.'/projects/PACO-MT/data/treebanks/Europarl3';


use Lingua::Align::Corpus::Parallel::OPUS;

my $corpus = new Lingua::Align::Corpus::Parallel::OPUS(
  -alignfile => $EP_OPUS.'xml/en-nl.ces.gz',

  -src_file => $EP_PACO.'/english/ep-00-01-17.stanford.factored.gz',
  -src_type => 'Penn',

  -trg_file => $EP_PACO.'/dutch/ep-00-01-17.data.dz',
  -trg_type => 'AlpinoXML');



my %srcsent=();
my %trgsent=();
my $links;

while ($corpus->next_alignment(\%srcsent,\%trgsent,\$links)){
    print "====================================================\n";
}

