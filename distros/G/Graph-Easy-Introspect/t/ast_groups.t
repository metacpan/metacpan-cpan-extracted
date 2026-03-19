use strict ;
use warnings ;
use Test::More ;
use Graph::Easy ;
use Graph::Easy::Introspect ;

# basic group membership
{
my $g   = Graph::Easy->new ;
my $grp = $g->add_group('grp1') ;
my $a   = $g->add_node('A') ;
my $b   = $g->add_node('B') ;

$grp->add_node($a) ;
$grp->add_node($b) ;
$g->add_edge('A', 'C') ;

my $ast = $g->ast ;

is(scalar @{$ast->{groups}}, 1, 'one group in AST') ;

my $grp_ast = $ast->{groups}[0] ;
is($grp_ast->{id}, 'grp1', 'group id correct') ;
ok(ref $grp_ast->{nodes} eq 'ARRAY', 'group nodes is array') ;
is(scalar @{$grp_ast->{nodes}}, 2, 'group has 2 nodes') ;
ok((grep { $_ eq 'A' } @{$grp_ast->{nodes}}), 'A in group') ;
ok((grep { $_ eq 'B' } @{$grp_ast->{nodes}}), 'B in group') ;
}

# group bounding box
{
my $g   = Graph::Easy->new ;
my $grp = $g->add_group('grp1') ;
my $a   = $g->add_node('A') ;
my $b   = $g->add_node('B') ;

$grp->add_node($a) ;
$grp->add_node($b) ;
$g->add_edge('A', 'B') ;

my $ast = $g->ast ;
my $ga  = $ast->{groups}[0] ;

ok(defined $ga->{bbox},     'group has bbox') ;
ok(defined $ga->{bbox}{x1}, 'group bbox has x1') ;
ok(defined $ga->{bbox}{y1}, 'group bbox has y1') ;
ok(defined $ga->{bbox}{x2}, 'group bbox has x2') ;
ok(defined $ga->{bbox}{y2}, 'group bbox has y2') ;
ok($ga->{bbox}{x2} >= $ga->{bbox}{x1}, 'bbox x2 >= x1') ;
ok($ga->{bbox}{y2} >= $ga->{bbox}{y1}, 'bbox y2 >= y1') ;
}

# node back-references to groups
{
my $g   = Graph::Easy->new ;
my $grp = $g->add_group('grp1') ;
my $a   = $g->add_node('A') ;
my $b   = $g->add_node('B') ;

$grp->add_node($a) ;
$grp->add_node($b) ;
$g->add_edge('A', 'C') ;

my $ast = $g->ast ;

my ($na) = grep { $_->{id} eq 'A' } @{$ast->{nodes}} ;
my ($nc) = grep { $_->{id} eq 'C' } @{$ast->{nodes}} ;

ok(ref $na->{groups} eq 'ARRAY', 'A has groups array') ;
ok((grep { $_ eq 'grp1' } @{$na->{groups}}), 'A back-ref to grp1') ;
is(scalar @{$nc->{groups}}, 0, 'C not in any group') ;
}

# graph with no groups
{
my $g   = Graph::Easy->new ;
$g->add_edge('A', 'B') ;
my $ast = $g->ast ;

ok(ref $ast->{groups} eq 'ARRAY', 'groups key is array') ;
is(scalar @{$ast->{groups}}, 0, 'no groups when none defined') ;
}

# groups sorted deterministically
{
my $g  = Graph::Easy->new ;
my $g1 = $g->add_group('zebra') ;
my $g2 = $g->add_group('alpha') ;
my $a  = $g->add_node('A') ;
my $b  = $g->add_node('B') ;

$g1->add_node($a) ;
$g2->add_node($b) ;

my $ast = $g->ast ;

is($ast->{groups}[0]{id}, 'alpha', 'groups sorted: alpha first') ;
is($ast->{groups}[1]{id}, 'zebra', 'groups sorted: zebra second') ;
}

# group label
{
my $g   = Graph::Easy->new ;
my $grp = $g->add_group('grp1') ;
$grp->set_attribute('label', 'My Group') ;
my $a = $g->add_node('A') ;
$grp->add_node($a) ;

my $ast = $g->ast ;
my $ga  = $ast->{groups}[0] ;

is($ga->{label}, 'My Group', 'group label extracted') ;
}

done_testing() ;
