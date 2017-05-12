#!/usr/bin/perl

use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::GAFParser;
use GOBO::Writers::GAFWriter;
use FileHandle;

my $f = shift;
#my $fh = new FileHandle("gzip -dc $f|");
my $parser = new GOBO::Parsers::GAFParser(file=>$f);
$parser->parse;
#print $parser->graph;
my $writer = new GOBO::Writers::GAFWriter(graph=>$parser->graph);
$writer->write;
