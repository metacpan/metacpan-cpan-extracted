#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82 tests => 3;
use lib 't/';
use Sample;

my $tube = new_ok( 'Sample' );
my $res;
ok( $res = [ $tube->list_fuzzy_matchers( ) ], 'Method list_fuzzy_matchers( )' );
ok( scalar(@$res)>=4, 'List available matchers' );

