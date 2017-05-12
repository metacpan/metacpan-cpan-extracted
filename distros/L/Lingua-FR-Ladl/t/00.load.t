use Test::More tests => 4;

BEGIN {
use_ok( 'Lingua::FR::Ladl' );
use_ok( 'Lingua::FR::Ladl::Table' );
use_ok( 'Lingua::FR::Ladl::Parametrizer' );
use_ok( 'Lingua::FR::Ladl::Exceptions' );
}

diag( "Testing Lingua::FR::Ladl $Lingua::FR::Ladl::VERSION" );
