use strict ;
use warnings ;
use Test::More ;
use Graph::Easy ;
use Graph::Easy::Parser::Graphviz ;
use Graph::Easy::Introspect ;

my $parser = Graph::Easy::Parser::Graphviz->new ;

# self-loop
{
my $g   = $parser->from_text('digraph { A -> A ; }') ;
my $ast = $g->ast ;

is(scalar @{$ast->{nodes}}, 1, 'self-loop: 1 node') ;
is(scalar @{$ast->{edges}}, 1, 'self-loop: 1 edge') ;

my $e = $ast->{edges}[0] ;
is($e->{is_self_loop}, 1, 'self-loop flagged') ;
is($e->{from}, 'A', 'self-loop from A') ;
is($e->{to},   'A', 'self-loop to A') ;
ok(!defined $e->{from_port}, 'self-loop has no from_port') ;
ok(!defined $e->{to_port},   'self-loop has no to_port') ;
ok(ref $e->{path} eq 'ARRAY', 'self-loop has path array') ;

my $n = $ast->{nodes}[0] ;
is(scalar @{$n->{edges_in}},  1, 'self-loop: 1 incoming edge') ;
is(scalar @{$n->{edges_out}}, 1, 'self-loop: 1 outgoing edge') ;
is($n->{is_isolated}, 0, 'self-loop node not isolated') ;
}

# bidirectional edge
{
my $g   = $parser->from_text('digraph { A -> B [dir=both] ; }') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

is($e->{is_bidirectional}, 1, 'dir=both is bidirectional') ;
is($e->{is_self_loop},     0, 'dir=both is not self-loop') ;
}

# undirected edge is not bidirectional
{
my $g   = $parser->from_text('graph { A -- B ; }') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

is($e->{is_bidirectional}, 0, 'undirected edge is not flagged bidirectional') ;
}

# directed edge is not bidirectional
{
my $g   = $parser->from_text('digraph { A -> B ; }') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

is($e->{is_bidirectional}, 0, 'normal directed edge not bidirectional') ;
}

# multiplicity: two edges between same nodes
{
my $g   = $parser->from_text('digraph { A -> B ; A -> B ; }') ;
my $ast = $g->ast ;

is(scalar @{$ast->{edges}}, 2, 'two parallel edges') ;
is($ast->{edges}[0]{multiplicity}, 2, 'first edge multiplicity 2') ;
is($ast->{edges}[1]{multiplicity}, 2, 'second edge multiplicity 2') ;
}

# single edge has multiplicity 1
{
my $g   = $parser->from_text('digraph { A -> B ; B -> C ; }') ;
my $ast = $g->ast ;

is($ast->{edges}[0]{multiplicity}, 1, 'A->B multiplicity 1') ;
is($ast->{edges}[1]{multiplicity}, 1, 'B->C multiplicity 1') ;
}

# arrow directions: horizontal right
{
my $g   = $parser->from_text('digraph { A -> B ; }') ;
$g->set_attribute('flow', 'east') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

ok(defined $e->{arrow_dir}, 'horizontal edge has arrow_dir') ;
}

# arrow direction: vertical (default layout)
{
my $g   = $parser->from_text('digraph { A -> B ; }') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

ok(defined $e->{arrow_dir}, 'vertical edge has arrow_dir') ;
ok($e->{arrow_dir} =~ /^(up|down|left|right)$/, "arrow_dir is a valid direction: $e->{arrow_dir}") ;
}

# edge with label
{
my $g   = $parser->from_text(q{digraph { A -> B [label="hello"] ; }}) ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

is($e->{label}, 'hello', 'edge label extracted') ;
ok(defined $e->{label_x}, 'label_x set when label present') ;
ok(defined $e->{label_y}, 'label_y set when label present') ;
}

# edge without label
{
my $g   = $parser->from_text('digraph { A -> B ; }') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

ok(!defined $e->{label}, 'edge without label has undef label') ;
}

# path points have correct structure
{
my $g   = $parser->from_text('digraph { A -> B ; }') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

ok(scalar @{$e->{path}} > 0, 'edge has at least one path point') ;

for my $p (@{$e->{path}})
	{
	ok(defined $p->{x},         "path point has x") ;
	ok(defined $p->{y},         "path point has y") ;
	ok(defined $p->{type},      "path point has type") ;
	ok(defined $p->{type_code}, "path point has type_code") ;
	ok(defined $p->{is_label},  "path point has is_label") ;
	ok($p->{type} =~ /^[A-Z]/, "path type is uppercase string: $p->{type}") ;
	}
}

# from_port and to_port present for normal edges
{
my $g   = $parser->from_text('digraph { A -> B ; }') ;
my $ast = $g->ast ;
my $e   = $ast->{edges}[0] ;

ok(defined $e->{from_port}, 'from_port defined') ;
ok(defined $e->{to_port},   'to_port defined') ;
ok(defined $e->{from_side}, 'from_side defined') ;
ok(defined $e->{to_side},   'to_side defined') ;
ok($e->{from_side} =~ /^(left|right|top|bottom|unknown)$/, "from_side valid: $e->{from_side}") ;
ok($e->{to_side}   =~ /^(left|right|top|bottom|unknown)$/, "to_side valid: $e->{to_side}") ;
}

# port seq ordering: fan-out edges should have distinct seq values on same side
{
my $g = Graph::Easy->new ;
$g->add_edge('A', 'B') ;
$g->add_edge('A', 'C') ;
$g->add_edge('A', 'D') ;
my $ast = $g->ast ;
my ($na) = grep { $_->{id} eq 'A' } @{$ast->{nodes}} ;

my $total_ports = 0 ;
for my $side (qw/left right top bottom/)
	{
	$total_ports += scalar @{$na->{ports}{$side}} ;
	}

is($total_ports, 3, 'A has 3 outgoing ports total') ;
}

# disconnected components
{
my $g = Graph::Easy->new ;
$g->add_edge('A', 'B') ;
$g->add_edge('C', 'D') ;
my $ast = $g->ast ;

my %comp ;
for my $n (@{$ast->{nodes}})
	{
	push @{$comp{$n->{component}}}, $n->{id} ;
	}

is(scalar keys %comp, 2, 'two separate components') ;
}

done_testing() ;
