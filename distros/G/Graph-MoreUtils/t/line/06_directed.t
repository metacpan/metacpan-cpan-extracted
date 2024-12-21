#!/usr/bin/perl

use strict;
use warnings;
use Graph::Directed;
use Graph::MoreUtils qw( line );
use List::Util qw( all );
use Test::More tests => 7;

my( $g, $l );

$g = Graph::Directed->new;
$g->add_edge( 0, 0 );
$g->add_edge( 0, 1 );
$g->add_edge( 1, 0 );
$g->add_edge( 1, 1 );

is $g->edges, 4;

$l = line( $g );

is $l->vertices, 4;
is $l->edges, 8;

ok all { $l->in_degree( $_ ) == 2 && $l->out_degree( $_ ) == 2 } $l->vertices;

$l = line( $l );

is $l->vertices, 8;
is $l->edges, 16;

ok all { $l->in_degree( $_ ) == 2 && $l->out_degree( $_ ) == 2 } $l->vertices;
