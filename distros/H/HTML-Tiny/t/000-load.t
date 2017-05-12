use Test::More tests => 2;

BEGIN {
  ok( $] >= 5.004, "Your perl is new enough" );

  use_ok( 'HTML::Tiny' );
}

diag( "Testing HTML::Tiny $HTML::Tiny::VERSION" );
