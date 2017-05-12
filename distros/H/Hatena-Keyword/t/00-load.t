#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hatena::Keyword' );
}

diag( "Testing Hatena::Keyword $Hatena::Keyword::VERSION, Perl $], $^X" );
