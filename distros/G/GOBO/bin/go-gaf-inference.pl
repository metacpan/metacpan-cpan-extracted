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
use GOBO::InferenceEngine;
use GOBO::InferenceEngine::GAFInferenceEngine;
use DateTime;
use FileHandle;

my @ontfiles;
my %relh = ();
my $per_file_ic=0;
my $validate = 0;
my $infer = 0;
my $chunksize = 10000;
while ($ARGV[0] =~ /^\-/) {
    my $opt = shift @ARGV;
    if ($opt eq '-i' || $opt eq '--ontology') {
        push(@ontfiles, shift @ARGV);
    }
    elsif ($opt eq '-r' || $opt eq '--relation') {
        $relh{shift @ARGV} = 1;
    }
    elsif ($opt eq '--per-file') {
        $per_file_ic = 1;
    }
    elsif ($opt eq '--validate') {
        $validate = 1;
    }
    elsif ($opt eq '--infer') {
        $infer = 1;
    }
    elsif ($opt eq '--chunksize') {
        $chunksize = shift @ARGV;
    }
    elsif ($opt eq '-h' || $opt eq '--help') {
        system("perldoc $0");
        exit(0);
    }
    else {
        die "no such opt: $opt";
    }
}
if (!@ontfiles) {
    push(@ontfiles, shift);
}
if (!@ontfiles) {
    system("perldoc $0");
    exit(1);
}
if (!$validate && !$infer) {
    printf STDERR "You must pass either/both --validate or --infer flags\n";
    exit 1;
}

my $obo_parser = new GOBO::Parsers::OBOParser();
$obo_parser->parse_file($_) foreach @ontfiles;
my $ontg = $obo_parser->graph;
my $ie = new GOBO::InferenceEngine::GAFInferenceEngine(graph=>$ontg);

my %nodemap = ();

# iterate through annotations writing new ICs
foreach my $f (@ARGV) {
    my @ics = ();
    my @invalid = ();
    $ontg->annotations([]);
    my $gafparser = new GOBO::Parsers::GAFParser();
    $gafparser->set_file($f);

    # iterate through one chunk at a time
    while ($gafparser->parse_chunk(size=>$chunksize)) {
        printf STDERR "processing %d annots in in $f\n", scalar(@{$gafparser->graph->annotations});
        $ontg->add_annotations($gafparser->graph->annotations);
        printf STDERR "  ontg annots %d\n", scalar(@{$ontg->annotations});
        if ($infer) {
            push(@ics, @{$ie->infer_annotations($gafparser->graph->annotations)});
        }
        if ($validate) {
            push(@invalid, @{$ie->validate_annotations($gafparser->graph->annotations)});
        }
        
        # clear
        printf STDERR "  inferences %d\n", scalar(@ics);
        printf STDERR "  invalid annots %d\n", scalar(@invalid );
        $gafparser->graph(new GOBO::Graph);
    }
    if (@ics) {
        my $icgraph = new GOBO::Graph();
        $icgraph->annotations(\@ics);
        my $w = new GOBO::Writers::GAFWriter;
        if ($per_file_ic) {
            my $of = $f;
            $of =~ s/.*\///g;
            $of =~ s/\.gz//;
            $of .= ".ics.gaf";
            $w->file($of);
            $w->init_fh;
        }
        $w->graph($icgraph);
        $w->write;
    }
    if (@invalid) {
        my $w = new GOBO::Writers::GAFWriter;
        $w->init_fh;
        foreach my $i (@invalid) {
            my $term_id = $i->[2];
            my $term = $ontg->noderef($term_id);
            printf '%s only_in %s :: ', $term || $term_id, $i->[1];
            $w->write_annotation($i->[0]);
        }
    }
}
exit 0;


# find 
sub calculate_inference_graph {
    my $graph = shift;
    my $igraph = new GOBO::Graph;
    
}




=head1 NAME

go-gaf-inference.pl

=head1 SYNOPSIS

 go-gaf-inference.pl --infer go/ontology/obo_format_1_2/gene_ontology_ext.obo go/gene-associations/gene_association.sgd.gz

=head1 DESCRIPTION

Performs inference upon a GAF (Gene Association File), generating ICs based on configurable criteria

=head2 INFERENCE

Pass in --infer on the command line

=head3 Inter-ontology part_of inference

Example:

 go-gaf-inference.pl --infer --per-file go/ontology/obo_format_1_2/gene_ontology_ext.obo go/gene-associations/gene_association*.gz

generates IC BP annotations for MF annotations where a part_of link is asserted or can be inferred

TO BE DOCUMENTED

=head3 Other types of inference

NOT YET IMPLEMENTED

=head2 VALIDATION

Pass in --validate on the command line

=head3 Taxon validation

http://wiki.geneontology.org/index.php/Category:Taxon

  go-gaf-inference.pl --validate -i scratch/go-taxon/TaxonGOLinksFile.obo -i scratch/go-taxon/ncbitax-slim.obo -i scratch/go-taxon/UnionTerms.obo -i ontology/editors/gene_ontology_write.obo gene-associations/gene_association.goa_chicken.gz

Writes out taxonomically invalid annotations. Uses the correct semantics for union terms.

=head3 Other types of validation

NOT YET IMPLEMENTED

=cut
