use Test;
plan tests => 5;
use strict;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;


my $parser = new GOBO::Parsers::OBOParser(file=>"t/data/obo_file.obo");
my $verbose = 1;
$parser->parse;

my $g = $parser->graph;

$Data::Dumper::Maxdepth = 2;
print 
"node index: " . Dumper( $g->node_index )
. "\nnode links for GO:0000004:\n" . join("\n", @{$g->get_outgoing_links("GO:0000004")}) . "\n\nRemoving GO:0000004...\n\n\n";

ok ( $g->get_term("GO:0000004") );

#$g->node_index->remove_node( $g->noderef("GO:0000004") );
$g->remove_node( $g->noderef("GO:0000004")); # NO CASCADE

print 
"node index now: " . Dumper( $g->node_index )
. "\nnode links for GO:0000004:\n" . join("\n", @{$g->get_outgoing_links("GO:0000004")}) . "\nnode index after getting links for GO:0000004: " . Dumper( $g->node_index )
. "\n";

ok ( ! $g->get_term("GO:0000004") );

ok ( scalar(@{$g->get_outgoing_links("GO:0000004")}) == 3);

$g->remove_node( $g->noderef("GO:0000007"), 1); # WITH CASCADE

ok ( ! $g->get_term("GO:0000007") );

ok ( scalar(@{$g->get_outgoing_links("GO:0000007")}) == 0);

