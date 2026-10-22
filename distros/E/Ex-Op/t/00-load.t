#!perl
use 5.010;
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok( 'Ex::Op' ) || print "Bail out!\n";
}

is( $Ex::Op::VERSION, '0.01', 'version' );
ok( defined &Ex::Op::CLONE, 'CLONE is defined for threads' );

diag( "Testing Ex::Op $Ex::Op::VERSION, Perl $], $^X" );
