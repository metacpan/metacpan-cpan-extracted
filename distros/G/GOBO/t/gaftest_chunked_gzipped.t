use Test;
plan tests => 2;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::GAFParser;
use FileHandle;

my $fn = 't/data/gene_association.mgi.gz';
my $parser = new GOBO::Parsers::GAFParser();
$parser->set_file($fn);
$parser->max_chunk(10);
my $n= 0;
while ($parser->parse_chunk) {
    print "Parsed chunk:\n";
    $n++;
}

ok($n>0);

my $ag = $parser->graph;
#print $parser->graph;

my $sl = $ag->annotation_ix->statements_by_node_id('MGI:MGI:1913318');
foreach my $s (@$sl) {
    printf "$s GP:%s\n", $s->specific_node;
}
ok (@$sl == 2);
