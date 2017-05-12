#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Deep;
use Graph::Implicit;
use List::MoreUtils qw/pairwise/;

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

sub pairs {
    die "uneven list sizes" if @_ % 2 == 1;
    my @list1 = @_;
    my @list2 = splice @list1, @list1 / 2, @list1 / 2;
    our ($a, $b); # dumb...
    return pairwise { [$a, $b] } @list1, @list2;
}

my %graph = (
    a => [pairs qw/  b c          /, qw/  7 3          /],
    b => [pairs qw/      d   f   h/, qw/      8   8   2/],
    c => [pairs qw/a       e     h/, qw/1       2     4/],
    d => [pairs qw/a b c d e f g h/, qw/2 9 1 6 8 1 3 2/],
    e => [pairs qw/    c d        /, qw/    2 2        /],
    f => [pairs qw/               /, qw/               /],
    g => [pairs qw/            g  /, qw/            4  /],
    h => [pairs qw/          f g  /, qw/          5 3  /],
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
my %sssp = (
    a => {a => undef, b => 'a',   c => 'a',   d => 'e',
          e => 'c',   f => 'd',   g => 'h',   h => 'c'},
    d => {a => 'd',   b => 'd',   c => 'd',   d => undef,
          e => 'c',   f => 'd',   g => 'd',   h => 'd'},
);
my $edge_calculator = sub {
    my $vertex = shift;
    return @{ $graph{$vertex} };
};

my $graph = Graph::Implicit->new($edge_calculator);
for my $vertex (keys %sssp) {
    my ($tree, $blah) = $graph->dijkstra($vertex);
    cmp_bag([keys %$tree], $reachable{$vertex},
            "dijkstra visits each node exactly once from $vertex");
    ok(is_tree($tree),
       "dijkstra creates a tree from $vertex");
    cmp_deeply($tree, $sssp{$vertex},
               "dijkstra is the sssp from $vertex");
}
