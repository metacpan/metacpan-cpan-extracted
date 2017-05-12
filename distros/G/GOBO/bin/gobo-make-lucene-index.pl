#!/usr/bin/perl
####
#### Example usage:
####
####   perl -I/home/sjcarbon/local/src/svn/geneontology/go-moose
####        ./gobo-make-lucene-index.pl ../t/data/*.obo
####

use strict;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
use GOBO::Util::LuceneIndexer;
use FileHandle;


my $loo = new GOBO::Util::LuceneIndexer();
$loo->target_dir('lucene');
$loo->open();

## Do many files.
foreach (@ARGV) {
  my $parser = new GOBO::Parsers::OBOParser(file=>$_);
  $parser->parse;
  $loo->index_terms($parser->graph->terms);
}

## Compress index and end.
$loo->close();
