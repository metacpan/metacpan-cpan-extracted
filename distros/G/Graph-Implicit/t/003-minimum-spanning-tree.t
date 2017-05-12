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
    a => [pairs qw/  b c          /, qw/  9 1          /],
    b => [pairs qw/      d   f   h/, qw/      9   1   9/],
    c => [pairs qw/a       e     h/, qw/9       1     9/],
    d => [pairs qw/a b c d e f g h/, qw/1 1 9 9 9 9 9 1/],
    e => [pairs qw/    c d        /, qw/    9 9        /],
    f => [pairs qw/               /, qw/               /],
    g => [pairs qw/            g  /, qw/            9  /],
    h => [pairs qw/          f g  /, qw/          9 1  /],
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
my %mst = (
    a => {a => undef, b => 'd',   c => 'a',   d => 'e',
          e => 'c',   f => 'b',   g => 'h',   h => 'd'},
    d => {a => 'd',   b => 'd',   c => 'a',   d => undef,
          e => 'c',   f => 'b',   g => 'h',   h => 'd'},
);
my $edge_calculator = sub {
    my $vertex = shift;
    return @{ $graph{$vertex} };
};

SKIP: {
my $graph = Graph::Implicit->new($edge_calculator);
skip "not implemented yet", 6 unless $graph->can('prim');
for my $spanning_tree (qw/prim/) {
    for my $vertex (keys %mst) {
        my @visited;
        my $tree = $graph->$spanning_tree($vertex, sub { push @visited, $_[1] });
        cmp_bag(\@visited, $reachable{$vertex},
                "$spanning_tree visits each node exactly once from $vertex");
        ok(is_tree($tree),
           "$spanning_tree creates a tree from $vertex");
        cmp_deeply($tree, $mst{$vertex},
                   "$spanning_tree is the mst from $vertex");
    }
}
}
