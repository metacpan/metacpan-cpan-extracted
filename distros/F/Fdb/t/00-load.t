#!perl -T
use 5.8.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Fdb' ) || print "Bail out!\n";
}

diag( "Testing Fdb $Fdb::VERSION, Perl $], $^X" );
