use Test;
plan tests => 5;
use strict;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
use GOBO::InferenceEngine;
use FileHandle;


my $parser = new GOBO::Parsers::OBOParser;
$parser->parse_file("t/data/cell.obo");
$parser->parse_file("t/data/cell_union.obo");
my $g = $parser->graph;

my $n = $g->noderef('CL:0000540'); # neuron
my $an = $g->noderef('CL:0000107'); # autonomic neuron
my $l = $g->noderef('CL:0000084'); #  T cell
my $u = $g->noderef('neuron_or_lymphocyte');

my $ie = new GOBO::InferenceEngine(graph=>$g);

ok($u->union_definition);
ok($ie->subsumed_by($an,$n));
ok($ie->subsumed_by($an,$u->union_definition));
ok($ie->subsumed_by($n,$u->union_definition));
ok($ie->subsumed_by($l,$u));

foreach my $link (@{$ie->get_inferred_target_links('foo2')}) {
    printf "link: $link\n";
}
foreach my $link (@{$ie->get_inferred_target_links('foo2','only_in')}) {
    printf "link: $link\n";
}
foreach my $link (@{$ie->get_inferred_target_nodes('foo2', 'only_in')}) {
    printf "link: $link\n";
}
