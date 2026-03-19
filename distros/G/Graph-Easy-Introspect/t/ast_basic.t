use strict ;
use warnings ;
use Test::More ;
use Graph::Easy ;
use Graph::Easy::Parser::Graphviz ;
use Graph::Easy::Introspect ;

my $dot = <<'DOT' ;
digraph {
    A -> B ;
    B -> C ;
}
DOT

my $parser = Graph::Easy::Parser::Graphviz->new ;
my $g      = $parser->from_text($dot) ;

ok($g, 'graph parsed from DOT') ;

my $ast = $g->ast ;
ok($ast, 'AST generated') ;
ok(!exists $ast->{error}, 'no error in AST') ;

# top-level keys
ok(exists $ast->{meta},    'meta key present') ;
ok(exists $ast->{meta},     'meta key present') ;
ok(exists $ast->{graph},    'graph key present') ;
ok(ref $ast->{nodes} eq 'ARRAY', 'nodes is array') ;
ok(ref $ast->{edges} eq 'ARRAY', 'edges is array') ;
ok(ref $ast->{groups} eq 'ARRAY', 'groups is array') ;
ok(ref $g->ast_grid eq 'ARRAY', 'ast_grid is array') ;

# meta
ok(defined $ast->{meta}{introspect_version}, 'meta has introspect_version') ;
ok(defined $ast->{meta}{graph_easy_version}, 'meta has graph_easy_version') ;
ok(defined $ast->{meta}{generated_at},       'meta has generated_at') ;
ok(defined $ast->{meta}{layout_algorithm},   'meta has layout_algorithm') ;

# graph block
ok(defined $ast->{graph}{is_directed},  'graph has is_directed') ;
ok(defined $ast->{graph}{total_width},  'graph has total_width') ;
ok(defined $ast->{graph}{total_height}, 'graph has total_height') ;
ok($ast->{graph}{total_width}  > 0, 'total_width positive') ;
ok($ast->{graph}{total_height} > 0, 'total_height positive') ;
is($ast->{graph}{is_directed}, 1, 'digraph is directed') ;

# node count
is(scalar @{$ast->{nodes}}, 3, '3 nodes in AST') ;
is(scalar @{$ast->{edges}}, 2, '2 edges in AST') ;

# nodes are sorted deterministically
is($ast->{nodes}[0]{id}, 'A', 'first node is A') ;
is($ast->{nodes}[1]{id}, 'B', 'second node is B') ;
is($ast->{nodes}[2]{id}, 'C', 'third node is C') ;

# node fields
my $na = $ast->{nodes}[0] ;
ok(defined $na->{id},          'node has id') ;
ok(defined $na->{label},       'node has label') ;
ok(defined $na->{is_anon},     'node has is_anon') ;
ok(defined $na->{is_isolated}, 'node has is_isolated') ;
ok(defined $na->{x},           'node has x') ;
ok(defined $na->{y},           'node has y') ;
ok(defined $na->{width},       'node has width') ;
ok(defined $na->{height},      'node has height') ;
ok(ref $na->{bbox}      eq 'HASH',  'node has bbox') ;
ok(ref $na->{ports}     eq 'HASH',  'node has ports') ;
ok(ref $na->{edges_in}  eq 'ARRAY', 'node has edges_in') ;
ok(ref $na->{edges_out} eq 'ARRAY', 'node has edges_out') ;
ok(ref $na->{groups}    eq 'ARRAY', 'node has groups') ;
ok(ref $na->{attrs}     eq 'HASH',  'node has attrs') ;
ok(defined $na->{component},   'node has component') ;

is($na->{is_anon}, 0, 'A is not anon') ;
is($na->{label}, 'A', 'node A label matches id') ;
is(scalar @{$na->{edges_out}}, 1, 'A has 1 outgoing edge') ;
is(scalar @{$na->{edges_in}},  0, 'A has 0 incoming edges') ;

my $nb = $ast->{nodes}[1] ;
is(scalar @{$nb->{edges_in}},  1, 'B has 1 incoming edge') ;
is(scalar @{$nb->{edges_out}}, 1, 'B has 1 outgoing edge') ;

my $nc = $ast->{nodes}[2] ;
is(scalar @{$nc->{edges_in}},  1, 'C has 1 incoming edge') ;
is(scalar @{$nc->{edges_out}}, 0, 'C has 0 outgoing edges') ;
is($nc->{is_isolated}, 0, 'C is not isolated') ;

# bbox fields
ok(defined $na->{bbox}{x1}, 'bbox has x1') ;
ok(defined $na->{bbox}{y1}, 'bbox has y1') ;
ok(defined $na->{bbox}{x2}, 'bbox has x2') ;
ok(defined $na->{bbox}{y2}, 'bbox has y2') ;

# ports structure
for my $side (qw/left right top bottom unknown/)
	{
	ok(ref $na->{ports}{$side} eq 'ARRAY', "port side $side is array") ;
	}

# edge fields
my $eab = $ast->{edges}[0] ;
ok(defined $eab->{id},               'edge has id') ;
ok(defined $eab->{from},             'edge has from') ;
ok(defined $eab->{to},               'edge has to') ;
ok(defined $eab->{is_self_loop},     'edge has is_self_loop') ;
ok(defined $eab->{is_bidirectional}, 'edge has is_bidirectional') ;
ok(defined $eab->{multiplicity},     'edge has multiplicity') ;
ok(defined $eab->{arrow_dir},        'edge has arrow_dir') ;
ok(ref $eab->{path}  eq 'ARRAY', 'edge has path') ;
ok(ref $eab->{attrs} eq 'HASH',  'edge has attrs') ;

is($eab->{is_self_loop},     0, 'A->B is not self-loop') ;
is($eab->{is_bidirectional}, 0, 'A->B is not bidirectional') ;
is($eab->{multiplicity},     1, 'A->B has multiplicity 1') ;
ok($eab->{arrow_dir}, 'A->B has arrow_dir set') ;

# path point fields
my $pp = $eab->{path}[0] ;
ok(defined $pp->{x},         'path point has x') ;
ok(defined $pp->{y},         'path point has y') ;
ok(defined $pp->{type},      'path point has type') ;
ok(defined $pp->{type_code}, 'path point has type_code') ;
ok(defined $pp->{is_label},  'path point has is_label') ;

# edges sorted deterministically
is($ast->{edges}[0]{from}, 'A', 'first edge from A') ;
is($ast->{edges}[0]{to},   'B', 'first edge to B') ;
is($ast->{edges}[1]{from}, 'B', 'second edge from B') ;
is($ast->{edges}[1]{to},   'C', 'second edge to C') ;

# connected component
is($na->{component}, $nb->{component}, 'A and B in same component') ;
is($nb->{component}, $nc->{component}, 'B and C in same component') ;

# isolated node
my $g2 = Graph::Easy->new ;
$g2->add_node('X') ;
$g2->add_edge('Y', 'Z') ;
my $ast2 = $g2->ast ;
my ($xn) = grep { $_->{id} eq 'X' } @{$ast2->{nodes}} ;
is($xn->{is_isolated}, 1, 'isolated node X flagged correctly') ;

# undirected graph
my $p2 = Graph::Easy::Parser::Graphviz->new ;
my $g3 = $p2->from_text('graph { A -- B ; }') ;
my $ast3 = $g3->ast ;
is($ast3->{graph}{is_directed}, 0, 'undirected graph has is_directed=0') ;

# grid dimensions match total_width/total_height
my $grid = $g->ast_grid ;
is(scalar @$grid, $ast->{graph}{total_height}, 'grid row count matches total_height') ;
my $max_w = 0 ;
for my $row (@$grid) { $max_w = scalar @$row if scalar @$row > $max_w }
is($max_w, $ast->{graph}{total_width}, 'grid max col count matches total_width') ;

done_testing() ;
