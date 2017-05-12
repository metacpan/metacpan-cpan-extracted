use Test::More tests => 2;
use_ok( Catalyst::Test, 'BookDB' );

ok( request('/')->is_success );
