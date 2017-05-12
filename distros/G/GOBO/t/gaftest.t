use Test;
plan tests => 1;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::GAFParser;
use FileHandle;

my $fh = new FileHandle("t/data/test-fb.gaf");
my $parser = new GOBO::Parsers::GAFParser(fh=>$fh);
$parser->parse;
my $ag = $parser->graph;

my $sl = $ag->annotation_ix->statements_by_node_id('FB:FBgn0043467');
foreach my $s (@$sl) {
    print "$s\n";
}
ok (@$sl == 3);
