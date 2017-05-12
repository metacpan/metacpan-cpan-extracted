#!/usr/bin/perl

use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
use FileHandle;

my $f = shift;
my $parser = new GOBO::Parsers::OBOParser(file=>$f);
$parser->parse;
my $writer = new GOBO::Writers::OBOWriter(graph=>$parser->graph);
$writer->write;
