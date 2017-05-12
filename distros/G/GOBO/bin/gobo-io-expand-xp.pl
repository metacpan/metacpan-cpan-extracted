#!/usr/bin/perl

use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
use FileHandle;

my $f = shift;
my $parser = new GOBO::Parsers::OBOParser(file=>$f);
$parser->parse;
my $g = $parser->graph;
$g->convert_intersection_links_to_logical_definitions;

my %done = ();

my @nodes = @{$g->referenced_nodes};
while (my $n = shift @nodes) {
    next if $done{$n->id};
    if ($n->id =~ /\^/) {
        my $ce = new GOBO::ClassExpression->parse_idexpr($g,$n->id);
        #printf STDERR "$n => $ce %s\n",ref($n);
        if (!$n->can('logical_definition')) {
            bless $n, 'GOBO::TermNode';
        }
        $n->logical_definition($ce);
        foreach my $arg (@{$ce->arguments}) {
            my $r = $arg;
            if ($arg->isa('GOBO::ClassExpression::RelationalExpression')) {
                $r = $arg->target;
            }
            if (!$r->isa('GOBO::ClassExpression')) {
                next;
            }
            push(@nodes,$r);
            #printf STDERR "n=$r %s\n",ref($r);
            $g->add_term($r);

        }
    }
    $done{$n->id} = 1;
}

#$g->parse_idexprs();
my $writer = new GOBO::Writers::OBOWriter(graph=>$parser->graph);
$writer->write;
