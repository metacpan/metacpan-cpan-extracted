#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'LittleORM' )         || print "Bail out!\n";
    use_ok( 'LittleORM::Model' )  || print "Bail out!\n";
    use_ok( 'LittleORM::Filter' ) || print "Bail out!\n";
}

diag( "Testing LittleORM $LittleORM::VERSION, Perl $], $^X" );
