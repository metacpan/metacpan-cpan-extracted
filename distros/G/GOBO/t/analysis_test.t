use Test;
plan tests => 1;
use strict;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Parsers::GAFParser;
use GOBO::Writers::GAFWriter;
use GOBO::Analysis::AnalysisEngine;
use FileHandle;

my $gaf = "t/data/test-fb.gaf";

my $ontf = "t/data/gtp.obo";
my $obo_parser = new GOBO::Parsers::OBOParser(file=>$ontf);
my $ontg = $obo_parser->graph;
$obo_parser->parse;
my $ae = new GOBO::Analysis::AnalysisEngine;

my $fh = new FileHandle($gaf);
my $gafparser = new GOBO::Parsers::GAFParser(fh=>$fh);

my @ics = ();
$gafparser->parse;
$ontg->add_annotations($gafparser->graph->annotations);

$ae->graph($ontg);
$ae->index_annotations;

ok(compare('FB:FBgn0010339','FB:FBgn0039946') > 0);

sub compare {
    my ($f1,$f2) = @_;
    my $simJ = $ae->calculate_simJ($f1,$f2);
    printf "%s vs %s = %s\n", $f1, $f2, $simJ;
    return $simJ;
}
