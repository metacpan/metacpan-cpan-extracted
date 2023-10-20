#!/usr/bin/perl

use strict;
use warnings;

use Graph::MoreUtils qw( SSSR );
use Graph::Undirected;
use Test::More tests => 2;

my $g = Graph::Undirected->new;
$g->add_cycle( 'A'..'F' );

is scalar SSSR( $g ), 12;
is scalar SSSR( $g, 4 ), 0;
