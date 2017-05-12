use Test;
plan tests => 8;
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


my $fh = new FileHandle("t/data/so-xp.obo");
my $parser = new GOBO::Parsers::OBOParser(fh=>$fh);
$parser->parse;
my $g = $parser->graph;

$g->convert_intersection_links_to_logical_definitions();

my $c = $g->noderef('SO:0000111');
ok($c->label eq "transposable_element_gene");
my $n = 0;
foreach my $term (@{$g->terms}) {
    if ($term->logical_definition) {
        printf "%s equivalent_to [ %s ]\n", $term, $term->logical_definition;
        $n++;
    }
}
printf "total: %d\n", $n;
ok($n == 193);

#use Moose::Autobox;
# print 'Print squares from 1 to 10 : ';
#  print [ 1 .. 10 ]->map(sub { $_ * $_ })->join(', ');


$parser->parse_file("t/data/UnionTerms.obo");


$c = $g->noderef('JD:0000002');
printf "c=$c\n";
ok($c);
ok($c->label eq 'Viridiplantae and Cyanobacteria');
my $u = $c->union_definition;
ok($u);
ok(@{$u->arguments} == 2);
ok(grep {$_->id eq 'NCBITaxon:1117'} @{$u->arguments});
ok(grep {$_->id eq 'NCBITaxon:33090'} @{$u->arguments});
