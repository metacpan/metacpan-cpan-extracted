#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

# use Lingua::Align::Corpus::Treebank;
use Lingua::Align::Corpus::Treebank::Stanford;
# use Lingua::Align::Corpus::Treebank::TigerXML;
use Lingua::Align::Corpus::Treebank::AlpinoXML;

my $file = shift(@ARGV) || '/storage/tiedeman/projects/PACO-MT/data/treebanks/Europarl3/english/ep-00-01-17.stanford.gz';

my $corpus = new Lingua::Align::Corpus::Treebank::Stanford(-file => $file);
# my $output = new Lingua::Align::Corpus::Treebank::TigerXML;
my $output = new Lingua::Align::Corpus::Treebank::AlpinoXML;


my %tree=();

while ($corpus->next_sentence(\%tree)){
    print $output->print_tree(\%tree);
}

