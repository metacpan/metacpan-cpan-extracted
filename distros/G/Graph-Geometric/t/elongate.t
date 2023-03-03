#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More tests => 9;

my $pyramid = pentagonal bipyramid;
$pyramid = $pyramid->elongate;

is scalar( $pyramid->vertices ), 12;
is scalar( $pyramid->edges ),    25;
is scalar( $pyramid->faces ),    15;

my $bifrustum5 = pentagonal bifrustum;
my $prism5 = pentagonal prism;
my( $face5 ) = grep { scalar @$_ == 5 } $prism5->faces;
$prism5->elongate( $face5 );

is scalar( $prism5->vertices ), scalar( $bifrustum5->vertices );
is scalar( $prism5->edges ),    scalar( $bifrustum5->edges );
is scalar( $prism5->faces ),    scalar( $bifrustum5->faces );

my $bifrustum6 = hexagonal bifrustum;
my @cycle = grep { $bifrustum6->degree( $_ ) == 4 } $bifrustum6->vertices;
$bifrustum6->elongate( \@cycle );

is scalar( $bifrustum6->vertices ), 24;
is scalar( $bifrustum6->edges ),    42;
is scalar( $bifrustum6->faces ),    20;
