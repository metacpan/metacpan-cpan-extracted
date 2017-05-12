#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dispatch::Class' );
}

diag( "Testing Dispatch::Class $Dispatch::Class::VERSION, Perl $], $^X" );
