use Test::More tests => 2;

BEGIN {
  use_ok( 'Devel::TraceLoad::Hook' );
  use_ok( 'Devel::TraceLoad' );
}

diag( "Testing Devel::TraceLoad $Devel::TraceLoad::VERSION" );
