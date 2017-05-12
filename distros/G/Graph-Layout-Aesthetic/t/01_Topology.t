#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01_Topology.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

my $has_directed   = eval "use Graph; use Graph::Directed; 1";
my $has_undirected = eval "use Graph; use Graph::Undirected; 1";

my $destroys;
{
    my $f = \&Graph::Layout::Aesthetic::Topology::DESTROY;
    no warnings 'redefine';
    *Graph::Layout::Aesthetic::Topology::DESTROY = sub($) {
        $destroys++;
        $f->(@_);
    }
}

{
    package KillRef;
    my $killrefs;
    sub test {
        my $class = shift;
        $killrefs = 0;
        bless $_[0], $class;
        $_[0] = undef;
        main::is($killrefs, 1, "Properly cleaned");
    }

    sub DESTROY {
        $killrefs++;
    }
}

sub check_topology {
    my ($t, $nodes) = @_;

    is($t->nr_vertices, 8, "Know all vertices");
    my @edges = ([ 0, 1 ], [ 0, 2 ], [ 2, 3 ], [ 3, 4 ], [ 4, 5 ], [ 5, 6]);
    for my $v (0..$t->nr_vertices-1) {
        is_deeply([sort {$a <=> $b } map $nodes->[$_], $t->neighbors($v)],
                  [sort {$a <=> $b } map {
                      $nodes->[$v] == $_->[0] ? $_->[1] : () ,
                      $nodes->[$v] == $_->[1] ? $_->[0] : () } @edges]);
        is_deeply([sort {$a <=> $b } map $nodes->[$_], $t->forward_neighbors($v)],
                  [sort {$a <=> $b } map { $nodes->[$v] == $_->[0] ? $_->[1] : ()} @edges]);
    }
    my @e = $t->edges;
    is_deeply([sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } map [$nodes->[$_->[0]], $nodes->[$_->[1]]], @e],
              [sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @edges], 
              "Got all edges");
    KillRef->test($e[0]);
    is($t->nr_vertices, 8, "Know all vertices");
}

my $t = Graph::Layout::Aesthetic::Topology->new_vertices(8);
isa_ok($t, "Graph::Layout::Aesthetic::Topology");
is($t->nr_vertices, 8, "Know all vertices");
$t->add_edge(0, 1);
$t->add_edge(0, 2, 1);
$t->add_edge(3, 2, 0);
$t->add_edge(3, 4, "foo");
$t->add_edge(4, 5, substr("foo", 0, 1));
$t->add_edge(6, 5, substr("foo", 1, 0));
eval { $t->add_edge(0, 0) };
like($@, qr!Vertex 0 connects to itself at t.01_Topology.t!,
     "Disallow self edge");
check_topology($t, [0..7]);
is($t->finished, "", "Unfinished");
eval { $t->levels };
like($@,
     qr!Won.t calculate node levels on an unfinished topology at t.01_Topology.t!,
     "Must finish before levels");
$t->finish;
check_topology($t, [0..7]);
is($t->finished, 1, "Finished");
eval { $t->finish };
like($@, qr!Topology is already finished at t.01_Topology.t!);
is_deeply([$t->levels], [0, 1, 1, 2, 3, 4, 5, 5 ], "Levels ok");

$destroys = 0;
$t = undef;
is($destroys, 1, "Topology object properly destroyed");

my $canaries = 0;
{
    package Canary;

    sub new {
        $canaries++;
        return bless [], shift;
    }

    sub DESTROY {
        $canaries--;
    }
}

# check user_data
for my $data (qw(user_data _private_data)) {
    my $t = Graph::Layout::Aesthetic::Topology->new_vertices(1);
    is($t->$data, undef);
    is($t->$data(5), undef);
    is($t->$data(6), 5);
    is($t->$data, 6);
    is($t->$data, 6);
    $t->$data(7);
    is($t->$data, 7);
    is($t->$data(Canary->new), 7);
    is($canaries, 1);
    isa_ok($t->$data(8), "Canary");
    is($canaries, 0);
    $t->$data(Canary->new);
    is($canaries, 1);
    $t = undef;
    is($canaries, 0);
}

can_ok("Graph::Layout::Aesthetic::Topology", qw(from_graph));
if ($has_directed && $Graph::VERSION >= 0.50) {
    my $g = Graph::Directed->new;
    $g->add_edge("foo0", "foo1");
    $g->add_edge("foo0", "foo2");
    $g->add_edge("foo2", "foo3");
    $g->add_edge("foo3", "foo4");
    $g->add_edge("foo4", "foo5");
    $g->add_edge("foo5", "foo6");
    $g->add_vertex("foo7");

    my $t = Graph::Layout::Aesthetic::Topology->from_graph
        ($g, id_attribute => undef);
    is($t->finished, 1, "Finished");
    my @node_order = map /(\d+)/, $g->vertices;
    check_topology($t, \@node_order);
    is($g->get_vertex_attribute("foo0", "layout_id"), undef,
       "No accidental set of default name");
    $destroys = 0;
    $t = undef;
    is($destroys, 1, "Topology object properly destroyed");

    $t = Graph::Layout::Aesthetic::Topology->from_graph
        ($g,
         literal	=> 1,
         id_attribute	=> "index");
    is($t->finished, 1, "Finished");
    check_topology($t, \@node_order);
    my $v = 0;
    for ($g->vertices) {
        my $i = $_;
        $i =~ s/foo//;
        is ($node_order[$g->get_vertex_attribute($_, "index")], $i);
        is ($g->get_vertex_attribute($_, "layout_id"), undef);
        $v++;
    }
    is($v, $t->nr_vertices,
       "Graph and topology have the same number of vertices");
    $destroys = 0;
    $t = undef;
    is($destroys, 1, "Topology object properly destroyed");

    for ($g->vertices) {
        $g->delete_vertex_attribute($_, "index");
        $g->delete_vertex_attribute($_, "layout_id");
    }
    $t = Graph::Layout::Aesthetic::Topology->from_graph($g, literal => 1);
    is($t->finished, 1, "Finished");
    check_topology($t, \@node_order);
    $v = 0;
    for ($g->vertices) {
        my $i = $_;
        $i =~ s/foo//;
        is ($node_order[$g->get_vertex_attribute($_, "layout_id")], $i);
        is ($g->get_vertex_attribute($_, "index"), undef);
        $v++;
    }
    is($v, $t->nr_vertices,
       "Graph and topology have the same number of vertices");
    $destroys = 0;
    $t = undef;
    is($destroys, 1, "Topology object properly destroyed");

    for ($g->vertices) {
        $g->delete_vertex_attribute($_, "index");
        $g->delete_vertex_attribute($_, "layout_id");
    }
    $t = Graph::Layout::Aesthetic::Topology->from_graph($g);
    is($t->finished, 1, "Finished");
    $v = 0;
    for ($g->vertices) {
        my $i = $_;
        $i =~ s/foo//;
        is ($node_order[$g->get_vertex_attribute($_, "layout_id")], $i);
        is ($g->get_vertex_attribute($_, "index"), undef);
        $v++;
    }
    is($v, $t->nr_vertices,
       "Graph and topology have the same number of vertices");
    $destroys = 0;
    $t = undef;
    is($destroys, 1, "Topology object properly destroyed");

    for ($g->vertices) {
        $g->delete_vertex_attribute($_, "index");
        $g->delete_vertex_attribute($_, "layout_id");
    }
    my %attr = ("foo0" => 18, "a" => 36);
    $t = Graph::Layout::Aesthetic::Topology->from_graph
        ($g, literal => 1, id_attribute => \%attr);
    is($t->finished, 1, "Finished");
    check_topology($t, \@node_order);
    $v = 0;
    for ($g->vertices) {
        my $i = $_;
        $i =~ s/foo//;
        is ($g->get_vertex_attribute($_, "layout_id"),  undef);
        is ($g->get_vertex_attribute($_, "index"), undef);
        is($node_order[$attr{$_}], $i);
        $v++;
    }
    is($v, $t->nr_vertices,
       "Graph and topology have the same number of vertices");
    is(keys %attr, $v, "Attribute hash got cleared");
    $destroys = 0;
    $t = undef;
    is($destroys, 1, "Topology object properly destroyed");

    %attr = ("foo0" => 18, "a" => 36);
    for ($g->vertices) {
        $g->delete_vertex_attribute($_, "index");
        $g->delete_vertex_attribute($_, "layout_id");
    }
    $t = Graph::Layout::Aesthetic::Topology->from_graph
        ($g, id_attribute => \%attr);
    is($t->finished, 1, "Finished");
    $v = 0;
    for ($g->vertices) {
        my $i = $_;
        $i =~ s/foo//;
        is ($g->get_vertex_attribute($_, "layout_id"), undef);
        is ($g->get_vertex_attribute($_, "index"),     undef);
        is($node_order[$attr{$_}], $i);
        $v++;
    }
    is($v, $t->nr_vertices,
       "Graph and topology have the same number of vertices");
    is(keys %attr, $v, "Attribute hash got cleared");
    $destroys = 0;
    $t = undef;
    is($destroys, 1, "Topology object properly destroyed");
} elsif ($has_directed) {
    diag("You have Graph::Directed, but your Graph version is $Graph::VERSION which is below 0.50. Tests skipped");
} else {
    diag("You don't seem to have Graph::Directed. Tests skipped");
}

if ($has_undirected && $Graph::VERSION >= 0.50) {
    my $g = Graph::Undirected->new;
    $g->add_edge("foo0", "foo1");
    $g->add_edge("foo0", "foo2");
    $g->add_edge("foo2", "foo0");
    $g->add_edge("foo2", "foo3");
    $g->add_edge("foo3", "foo3");

    my $t = Graph::Layout::Aesthetic::Topology->from_graph
        ($g, id_attribute => "index");
    is($t->finished, 1, "Finished");

    my %v2n;
    $v2n{$_} = $g->get_vertex_attribute($_, "index") for $g->vertices;
    is (keys %v2n, 4, "Have all vetices");
    is_deeply([sort {$a <=> $b } $t->neighbors($v2n{foo0})],
              [sort {$a <=> $b } @v2n{qw(foo1 foo2)}], "Neighbors of foo0");
    is_deeply([sort {$a <=> $b } $t->neighbors($v2n{foo1})],
              [sort {$a <=> $b } @v2n{qw(foo0)}], "Neighbors of foo1");
    is_deeply([sort {$a <=> $b } $t->neighbors($v2n{foo2})],
              [sort {$a <=> $b } @v2n{qw(foo0 foo3)}], "Neighbors of foo2");
    is_deeply([sort {$a <=> $b } $t->neighbors($v2n{foo3})],
              [sort {$a <=> $b } @v2n{qw(foo2)}], "Neighbors of foo3");

    $destroys = 0;
    $t = undef;
    is($destroys, 1, "Topology object properly destroyed");

    eval { Graph::Layout::Aesthetic::Topology->from_graph
               ($g, id_attribute => "index", literal => 1) };
    like($@, qr!Vertex \d connects to itself at!, "Fail if no filtering");
} elsif ($has_undirected) {
    diag("You have Graph::Undirected, but your Graph version is $Graph::VERSION which is below 0.50. Tests skipped");
} else {
    diag("You don't seem to have Graph::Undirected. Tests skipped");
}
