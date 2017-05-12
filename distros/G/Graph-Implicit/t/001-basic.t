#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 24;
use Test::Deep;
use Graph::Implicit;

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
my $edge_calculator = sub {
    my $vertex = shift;
    return map { [$_, 1] } @{ $graph{$vertex} };
};

my $graph = Graph::Implicit->new($edge_calculator);
for my $vertex (qw/a b c d e f g h/) {
    cmp_bag([$graph->neighbors($vertex)], $graph{$vertex},
            "calculated neighbors of $vertex correctly");
}
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
for my $vertex (qw/a b c d e f g h/) {
    cmp_bag([$graph->vertices($vertex)], $reachable{$vertex},
            "calculated vertices reachable from $vertex correctly");
}
my %edges = (
    map { my $v = $_; $v => [map { [$v => $_] } @{ $graph{$v} }] }
        qw/a b c d e f g h/,
);
my %reachable_edges = (
    map { $_ => [map { @{ $edges{$_} } } @{ $reachable{$_} }] }
        qw/a b c d e f g h/,
);
for my $vertex (qw/a b c d e f g h/) {
    cmp_bag([$graph->edges($vertex)], $reachable_edges{$vertex},
            "calculated edges reachable from $vertex correctly");
}
