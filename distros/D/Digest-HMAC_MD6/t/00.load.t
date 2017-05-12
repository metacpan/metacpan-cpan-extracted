use Test::More tests => 1;

BEGIN {
  use_ok( 'Digest::HMAC_MD6' );
}

diag( "Testing Digest::HMAC_MD6 $Digest::HMAC_MD6::VERSION" );
