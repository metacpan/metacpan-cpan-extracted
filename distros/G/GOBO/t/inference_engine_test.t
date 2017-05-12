use Test;
plan tests => 9;
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

my $fh = new FileHandle("t/data/cell.obo");
my $parser = new GOBO::Parsers::OBOParser(fh=>$fh);
$parser->parse;
my $g = $parser->graph;

my $ie = new GOBO::InferenceEngine(graph=>$g);
my $neuron = $g->noderef('CL:0000540');

printf "neuron = $neuron\n";
my $develops_from = $g->relation_noderef('develops_from');

printf "df = $develops_from\n";
ok($develops_from->transitive);
ok($develops_from->propagates_over_is_a);
printf "$develops_from . $develops_from => %s\n", $ie->relation_composition($develops_from, $develops_from);

ok($ie->relation_composition($develops_from, $develops_from)->equals($develops_from));

my $xlinks = 
    $ie->extend_link(
        new GOBO::LinkStatement(node=>'CL:0000540',
                               relation=>$develops_from,
                               target=>'CL:0000047'));

foreach (@$xlinks) {
    printf "x: $_\n";
}

check();

printf "cached links: %d\n", scalar(@{$ie->inferred_graph->links});
print "trying again (should be cached)\n";
check();

sub check {

    my $links = $g->get_target_links($neuron);
    foreach (@$links) {
        printf "asserted: $_ [REL=%s t:%s]\n", $_->relation, $_->relation->transitive;
    }
    $links = $ie->get_inferred_target_links($neuron);
    foreach (@$links) {
        printf "inferred: $_\n";
    }
    ok(@$links > 0);
    ok(grep {$_->matches(relation=>'develops_from', target=>'CL:0000031')} @$links);
    ok(grep {$_->matches(relation=>'develops_from', target=>'CL:0000133')} @$links);
}

#use Moose::Autobox;
# print 'Print squares from 1 to 10 : ';
#  print [ 1 .. 10 ]->map(sub { $_ * $_ })->join(', ');
