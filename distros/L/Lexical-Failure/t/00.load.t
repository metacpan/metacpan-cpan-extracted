use Test::More tests => 1, import =>[qw< use_ok diag >];

BEGIN {
use_ok( 'Lexical::Failure' );
}

diag( "Testing Lexical::Failure $Lexical::Failure::VERSION" );

