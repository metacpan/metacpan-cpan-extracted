use Test;
plan tests => 2;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::GAFParser;
use FileHandle;

my $fh = new FileHandle("t/data/test-fb.gaf");
my $parser = new GOBO::Parsers::GAFParser(fh=>$fh);
$parser->max_chunk(10);
my $n= 0;
while ($parser->parse_chunk) {
    printf "Parsed chunk: %d\n", scalar(@{$parser->graph->annotations});
    $n++;
}
printf "total chunks: $n\n";

ok($n>0);

my $ag = $parser->graph;
#print $parser->graph;

my $sl = $ag->annotation_ix->statements_by_node_id('FB:FBgn0043467');
foreach my $s (@$sl) {
    print "$s\n";
}
ok (@$sl == 3);
