use Test;
plan tests => 6;
use strict;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Parsers::GAFParser;
use GOBO::Writers::GAFWriter;
use GOBO::InferenceEngine::GAFInferenceEngine;
use FileHandle;

my $gaf = "t/data/128up.gaf";

my $ontf = "t/data/gtp.obo";
my $obo_parser = new GOBO::Parsers::OBOParser(file=>$ontf);
my $ontg = $obo_parser->graph;
$obo_parser->parse;
my $ie = new GOBO::InferenceEngine::GAFInferenceEngine(graph=>$ontg);

my $gafparser = new GOBO::Parsers::GAFParser();
$gafparser->set_file($gaf);

my @ics = ();
while ($gafparser->parse_chunk(size=>2)) {
    $ontg->add_annotations($gafparser->graph->annotations);
    printf "inferring annotations for %s\n", scalar(@{$gafparser->graph->annotations});
    push(@ics, @{$ie->infer_annotations($gafparser->graph->annotations)});
    # clear
    $gafparser->graph(new GOBO::Graph);
}

print "Inferred ICs:\n";
my $icgraph = new GOBO::Graph();
$icgraph->annotations(\@ics);
my $w = new GOBO::Writers::GAFWriter;
$w->graph($icgraph);
$w->write;

ok(@ics == 1);
# FAKE link added to ftp.obo GO:0005525 gtp binding --> GO:0046123-purine deoxyribonucleoside biosynthetic process
my $ic = shift @ics;
ok($ic->node->label eq '128up');
ok($ic->target->label eq 'purine deoxyribonucleoside biosynthetic process');
ok($ic->evidence->supporting_entities->[0]->id eq 'GO:0005525');
ok($ic->source->id eq 'GOC');

# now add it back in and attempt to do inference again..

my $fh = new FileHandle($gaf);
$gafparser = new GOBO::Parsers::GAFParser(fh=>$fh);
my $agraph = $gafparser->graph;
$gafparser->parse;
$ontg->add_annotations($agraph->annotations);
printf "num annots orig: %d\n", scalar(@{$agraph->annotations});
print "Adding inferred annotation back:\n";
$agraph->add_annotation($ic);
$ontg->add_annotation($ic);
printf "num annots new: %d\n", scalar(@{$agraph->annotations});
foreach my $xlink (@{$agraph->annotation_ix->statements_by_node_id('FB:FBgn0010339')}) {
    printf "  128up :: $xlink\n";
}

print "Inferring ICs, second pass (expecting none):\n";
$ie = new GOBO::InferenceEngine::GAFInferenceEngine(graph=>$ontg);
@ics = @{$ie->infer_annotations($gafparser->graph->annotations)};
$icgraph = new GOBO::Graph();
$icgraph->annotations(\@ics);
my $w = new GOBO::Writers::GAFWriter;
$w->graph($icgraph);
$w->write;
ok(@ics == 0);


