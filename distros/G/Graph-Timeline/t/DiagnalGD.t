#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;

use_ok('Graph::Timeline::DiagonalGD');

################################################################################
# Create a new object
################################################################################

eval { Graph::Timeline::DiagonalGD->new(1); };
like( $@, qr/^Timeline->new\(\) takes no arguments /, 'Too many arguments' );

my $x = Graph::Timeline::DiagonalGD->new();

isa_ok( $x, 'Graph::Timeline::DiagonalGD' );

################################################################################
# Render parameters
################################################################################

$x->add_interval( label => '1', start => '1950/01/01T12:00:00', end => '1951/12/31T13:00:00' ); 
$x->add_interval( label => '2', start => '1950/03/01T12:00:00', end => '1952/01/13T07:00:00' ); 

eval { $x->render( ); };
like( $@, qr/^Timeline::DiagonalGD->render\(\) 'graph-width' and 'label-width' must be defined/, 'Minimum arguments' );

eval { $x->render( 'graph-width' => 1 ); };
like( $@, qr/^Timeline::DiagonalGD->render\(\) 'graph-width' and 'label-width' must be defined/, 'Minimum arguments' );

eval { $x->render( 'label-width' => 1 ); };
like( $@, qr/^Timeline::DiagonalGD->render\(\) 'graph-width' and 'label-width' must be defined/, 'Minimum arguments' );

eval { $x->render( 'graph-width' => 1, 'label-width' => 1 ); };
like( $@, qr/^Timeline::DiagonalGD->render\(\) Date range spans into months or years. No can do/, 'Range of the data' );

eval { $x->render( unknown => 42, 'graph-width' => 1, 'label-width' => 1 ); };
like( $@, qr/^Timeline->render\(\) invalid key 'unknown' passed as data/, 'Unknown parameter' );

################################################################################
# Map parameters
################################################################################

eval { $x->map( 'wrong', 'whatever' ); };
like( $@, qr/^Timeline::DiagonalGD->map\(\) Unknown map style, use 'line' or 'box'/, 'Wrong argument' );

eval { $x->map( 'line' ); };
like( $@, qr/^Timeline::DiagonalGD->map\(\) The map requires a name/, 'Wrong argument' );

# vim: syntax=perl :
