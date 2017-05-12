use Test::More tests => 1;

BEGIN {
use_ok( 'Devel::Decouple' );
}

diag( "Testing Devel::Decouple $Devel::Decouple::VERSION" );
note("Testing on perl $]");
