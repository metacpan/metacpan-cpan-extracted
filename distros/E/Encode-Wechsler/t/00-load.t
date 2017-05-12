#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use_ok( 'Encode::Wechsler' ) or BAIL_OUT( "can't use module" );
my $obj = new_ok( 'Encode::Wechsler' ) or BAIL_OUT( "can't instantiate object" );
