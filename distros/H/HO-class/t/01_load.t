#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'HO::class' );
    use_ok( 'HO::abstract' );
}

diag( "Testing HO::class $HO::class::VERSION, Perl $], $^X" );
