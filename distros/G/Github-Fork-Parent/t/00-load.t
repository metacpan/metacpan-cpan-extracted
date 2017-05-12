#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Github::Fork::Parent' );
}

diag( "Testing Github::Fork::Parent $Github::Fork::Parent::VERSION, Perl $], $^X" );
