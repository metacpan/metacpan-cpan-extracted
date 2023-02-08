#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More tests => 4;

my $pyramid10 = decagonal pyramid;
is scalar( $pyramid10->vertices ), 11;
is scalar( $pyramid10->faces ), 11;

my $prism25 = pentacosagonal prism;
is scalar( $prism25->vertices ), 50;
is scalar( $prism25->faces ), 27;
