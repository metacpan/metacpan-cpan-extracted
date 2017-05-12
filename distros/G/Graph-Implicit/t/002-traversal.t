#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 48;
use Test::Deep;
use Graph::Implicit;

sub is_tree {
    my ($graph, $start) = @_;
    # a tree is an acyclic graph with E=V-1
    my $v = keys %$graph;
    my $e = (grep { defined } values %$graph);

    VERTEX: for my $vertex (keys %$graph) {
        next unless defined $graph->{$vertex};
        my %visited;
        $visited{$vertex} = 1;
        my $iter = $vertex;
        while (1) {
            $iter = $graph->{$iter};
            next VERTEX if !defined $iter;
            return 0 if $visited{$iter};
            $visited{$iter} = 1;
        }
    }

    return $e == $v - 1;
}

my %graph = (
    a => [qw/  b c          /],
    b => [qw/      d   f   h/],
    c => [qw/a       e     h/],
    d => [qw/a b c d e f g h/],
    e => [qw/    c d        /],
    f => [qw/               /],
    g => [qw/            g  /],
    h => [qw/          f g  /],
);
my %reachable = (
    a => [qw/a b c d e f g h/],
    b => [qw/a b c d e f g h/],
    c => [qw/a b c d e f g h/],
    d => [qw/a b c d e f g h/],
    e => [qw/a b c d e f g h/],
    f => [qw/          f    /],
    g => [qw/            g  /],
    h => [qw/          f g h/],
);
my $edge_calculator = sub {
    my $vertex = shift;
    return map { [$_, 1] } @{ $graph{$vertex} };
};

my $graph = Graph::Implicit->new($edge_calculator);
for my $traversal (qw/bfs dfs/) {
    for my $vertex (qw/a b c d e f g h/) {
        my @visited;
        my $tree = $graph->$traversal($vertex, sub { push @visited, $_[1] });
        cmp_bag(\@visited, $reachable{$vertex},
                "$traversal visits each node exactly once from $vertex");
        ok(is_tree($tree),
           "$traversal creates a tree from $vertex");
        SKIP: {
            skip "don't know a good algorithm for this", 1;
            no strict 'refs';
            ok(&{ "check_$traversal" }($tree),
            "$traversal is in the correct order from $vertex");
        }
    }
}
