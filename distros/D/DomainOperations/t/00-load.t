#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DomainOperations' );
}

diag( "Testing DomainOperations $DomainOperations::VERSION, Perl $], $^X" );
