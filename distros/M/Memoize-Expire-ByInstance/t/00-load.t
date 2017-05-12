#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Memoize::Expire::ByInstance' );
}

diag( "Testing Memoize::Expire::ByInstance $Memoize::Expire::ByInstance::VERSION, Perl $], $^X" );
