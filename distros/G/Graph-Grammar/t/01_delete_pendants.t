#!/usr/bin/perl

use strict;
use warnings;

use Graph::Grammar;
use Graph::Undirected;
use Test::More;

my @rules = (
    [ 'degree() based rule',
      sub { $_[0]->degree( $_[1] ) == 1 },
      sub { $_[0]->delete_vertex( $_[1] ) } ],

    [ 'NoMoreVertices based rule',
      sub { 1 }, sub { 1 }, NO_MORE_VERTICES,
      sub { $_[0]->delete_vertex( $_[1] ) } ],
);

plan tests => 3 * @rules;

for my $rule (@rules) {
    my $g = Graph::Undirected->new;
    $g->add_cycle( 1..6 );

    parse_graph( $g, $rule );
    is scalar $g->vertices, 6;

    for (1..6) {
        $g->add_edge( $_, 10 + $_ );
    }
    is scalar $g->vertices, 12;

    parse_graph( $g, $rule );
    is scalar $g->vertices, 6;
}
