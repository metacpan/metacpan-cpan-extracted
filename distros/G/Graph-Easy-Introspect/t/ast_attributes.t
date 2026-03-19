use strict ;
use warnings ;
use Test::More ;
use Graph::Easy ;
use Graph::Easy::Parser::Graphviz ;
use Graph::Easy::Introspect ;

# node attributes
{
my $g = Graph::Easy->new ;
my $a = $g->add_node('A') ;
$a->set_attribute('shape', 'rounded') ;
$a->set_attribute('color', 'red') ;
$g->add_edge('A', 'B') ;

my $ast = $g->ast ;
my ($na) = grep { $_->{id} eq 'A' } @{$ast->{nodes}} ;
my ($nb) = grep { $_->{id} eq 'B' } @{$ast->{nodes}} ;

ok(ref $na->{attrs} eq 'HASH', 'node attrs is hash') ;
is($na->{attrs}{shape}, 'rounded', 'shape attribute extracted') ;
is($na->{attrs}{color}, 'red',     'color attribute extracted') ;
is(scalar keys %{$nb->{attrs}}, 0, 'node B with no explicit attrs has empty attrs') ;
}

# only set attributes are extracted
{
my $g = Graph::Easy->new ;
my $a = $g->add_node('A') ;
$a->set_attribute('shape', 'circle') ;
$g->add_edge('A', 'B') ;

my $ast = $g->ast ;
my ($na) = grep { $_->{id} eq 'A' } @{$ast->{nodes}} ;

ok(exists $na->{attrs}{shape}, 'explicitly set shape present in attrs') ;
ok(!exists $na->{attrs}{color}, 'unset color not present in attrs') ;
}

# edge attributes
{
my $parser = Graph::Easy::Parser::Graphviz->new ;
my $g      = $parser->from_text(q{digraph { A -> B [style=dashed] ; }}) ;
my $ast    = $g->ast ;
my $e      = $ast->{edges}[0] ;

ok(ref $e->{attrs} eq 'HASH', 'edge attrs is hash') ;
is($e->{attrs}{style}, 'dashed', 'edge style attribute extracted') ;
}

# edge without explicit attributes has empty attrs
{
my $g   = Graph::Easy->new ;
$g->add_edge('A', 'B') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

ok(ref $e->{attrs} eq 'HASH', 'edge attrs is hash') ;
}

# node label distinct from name
{
my $parser = Graph::Easy::Parser::Graphviz->new ;
my $g      = $parser->from_text(q{digraph { A [label="My Node"] ; A -> B ; }}) ;
my $ast    = $g->ast ;
my ($na)   = grep { $_->{id} eq 'A' } @{$ast->{nodes}} ;

is($na->{id},    'A',       'id is internal name') ;
is($na->{label}, 'My Node', 'label is display label') ;
}

# node label defaults to name when not set
{
my $g  = Graph::Easy->new ;
$g->add_edge('A', 'B') ;
my $ast = $g->ast ;
my ($na) = grep { $_->{id} eq 'A' } @{$ast->{nodes}} ;

is($na->{label}, 'A', 'label defaults to name') ;
}

# graph-level attributes
{
my $parser = Graph::Easy::Parser::Graphviz->new ;
my $g      = $parser->from_text('digraph mygraph { rankdir=LR ; A -> B ; }') ;
my $ast    = $g->ast ;

ok(ref $ast->{graph}{attrs} eq 'HASH', 'graph attrs is hash') ;
}

# anon node detection
{
my $parser = Graph::Easy::Parser::Graphviz->new ;
my $g      = Graph::Easy->new ;
my $a      = $g->add_node('A') ;
$g->add_edge('A', 'B') ;
my $ast = $g->ast ;
my ($na) = grep { $_->{id} eq 'A' } @{$ast->{nodes}} ;

is($na->{is_anon}, 0, 'regular node is not anon') ;
}

done_testing() ;
