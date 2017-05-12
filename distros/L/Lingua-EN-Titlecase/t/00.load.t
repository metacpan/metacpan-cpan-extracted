use Test::More tests => 2;

BEGIN {
      use_ok( 'Lingua::EN::Titlecase' );
      use_ok( 'Lingua::EN::Titlecase::HTML' );
}

diag( "Testing Lingua::EN::Titlecase $Lingua::EN::Titlecase::VERSION" );
