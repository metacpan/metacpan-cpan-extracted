#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use FabForce::DBDesigner4::Table qw(:const);

is( IDENTIFYING_1_TO_1    , 0, 'id 1:1'  );
is( IDENTIFYING_1_TO_N    , 1, 'id 1:n'  );
is( NON_IDENTIFYING_1_TO_N, 2, 'nid 1:n' );
is( NON_IDENTIFYING_1_TO_1, 5, 'nid 1:1' );