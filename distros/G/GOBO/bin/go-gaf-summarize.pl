#!/usr/bin/perl
use strict;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::Annotation;
use GOBO::Node;
use GOBO::Parsers::GAFParser;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::GAFWriter;
use GOBO::Writers::CustomizableWriter;
use GOBO::InferenceEngine;
use GOBO::InferenceEngine::GAFInferenceEngine;
use List::MoreUtils;
use DateTime;
use FileHandle;

my $ontf;
my $writer = new GOBO::Writers::CustomizableWriter;
while ($ARGV[0] =~ /^\-/) {
    my $opt = shift @ARGV;
    if ($opt eq '-i' || $opt eq '--ontology') {
        $ontf = shift;
    }
    elsif ($opt eq '-h' || $opt eq '--help') {
        system("perldoc $0");
        exit(0);
    }
    elsif ($opt eq '--gaf') {
        bless $writer, 'GOBO::Writers::GAFWriter';
    }
    else {
        die "no such opt: $opt";
    }
}
if (!$ontf) {
    $ontf = shift;
}
if (!$ontf) {
    system("perldoc $0");
    exit(1);
}

my $obo_parser = new GOBO::Parsers::OBOParser(file=>$ontf);
$obo_parser->parse;
my $ontg = $obo_parser->graph;
my $ie = new GOBO::InferenceEngine::GAFInferenceEngine(graph=>$ontg);


# iterate through annotations writing new ICs
my @ics = ();
foreach my $f (@ARGV) {
    print "FILE: $f\n";
    #my $gafparser = new GOBO::Parsers::GAFParser(file=>$f);
    my $gafparser = new GOBO::Parsers::GAFParser();
    $gafparser->graph($ontg);
    $ontg->annotations([]);
    # iterate through one chunk at a time
    $gafparser->parse_file($f);
    my %count_by_node = ();
    foreach my $ann (@{$gafparser->graph->annotations}) {
        $count_by_node{$ann->target->id}++;
    }
    foreach my $nid (keys %count_by_node) {
        printf "  %s count: %d\n", $ontg->noderef($nid), $count_by_node{$nid};
    }
}
exit 0;



=head1 NAME

go-gaf-summarize.pl

=head1 SYNOPSIS

  go-gaf-summarize.pl go/ontology/obo_format_1_2/gene_ontology_ext.obo go/gene-associations/*gz

=head1 DESCRIPTION

Extracts all annotations to a term, including annotations inferred from graph

=cut
